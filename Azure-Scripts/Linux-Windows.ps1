# Define the script to run on each Windows VM
$windowsScriptToRun = "Get-Volume | Format-List; Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture"

# Define the script to run on each Linux VM
$linuxScriptToRun = "lsblk -o NAME,FSTYPE,LABEL,UUID,MOUNTPOINT,SIZE"

# Get a list of resource groups
$resourceGroups = az group list --query "[].name" -o tsv

# Ensure the CSV file is clear at the beginning of the script
$csvFilePath = "vms_disk_volume_info.csv"
if (Test-Path $csvFilePath) { Remove-Item $csvFilePath }

# Function to add missing properties with 'na' value
function Add-MissingProperties {
    param($obj, $properties)
    foreach ($prop in $properties) {
        if (-not $obj.PSObject.Properties.Name -contains $prop) {
            $obj | Add-Member -NotePropertyName $prop -NotePropertyValue 'na'
        }
    }
}

# Combined properties for CSV headers
$combinedProperties = @("VMName", "ResourceGroup", "DriveLetter", "DriveType", "FileSystem", "FileSystemLabel", "DedupMode", "SizeGB", "SizeRemainingGB", "HealthStatus", "OperationalStatus", "DiskName", "DiskState", "DiskEncryption", "DiskType", "DiskSizeGB", "DiskIOPSReadWrite", "DiskMBpsReadWrite", "DiskSKU", "DiskZoneCount", "DiskLocation", "DiskTimeCreated", "DiskUUID")

# Iterate over each resource group
foreach ($rg in $resourceGroups) {
    Write-Host "Processing resource group: $rg"

    # Get a list of all VMs in the current resource group
    $vms = az vm list --resource-group $rg --query "[].{name: name, osType: storageProfile.osDisk.osType}" -o json | ConvertFrom-Json

    foreach ($vm in $vms) {
        Write-Host "Processing VM: $($vm.name) in resource group: $rg"

        # Determine the script to run based on the OS type
        $scriptToRun = if ($vm.osType -eq "Windows") { $windowsScriptToRun } else { $linuxScriptToRun }
        $commandId = if ($vm.osType -eq "Windows") { "RunPowerShellScript" } else { "RunShellScript" }

        # Run the script on the VM
        $result = az vm run-command invoke --resource-group $rg --name $vm.name --command-id $commandId --scripts $scriptToRun | ConvertFrom-Json

        if ($vm.osType -eq "Windows") {
            $volumeEntries = $result.value.message -split 'ObjectId\s+:\s+\{1\}' -ne ''

            $volumeInfoList = foreach ($volumeEntry in $volumeEntries) {
                # Extract key-value pairs for each volume
                $matches = [regex]::Matches($volumeEntry, '(?m)^(.+?)\s+:\s+(.+)$')
                $properties = @{}
                foreach ($match in $matches) {
                    $properties[$match.Groups[1].Value.Trim()] = $match.Groups[2].Value.Trim()
                }

                # Convert Size and SizeRemaining from bytes to GB and round to 2 decimal places
                $sizeGB = [math]::Round([double]$properties['Size'] / 1GB, 2)
                $sizeRemainingGB = [math]::Round([double]$properties['SizeRemaining'] / 1GB, 2)

                # Create a custom object for each volume
                [PSCustomObject]@{
                    VMName            = $vm.name
                    UniqueId          = $properties['UniqueId']
                    DriveLetter       = $properties['DriveLetter']
                    DriveType         = $properties['DriveType']
                    FileSystem        = $properties['FileSystem']
                    FileSystemLabel   = $properties['FileSystemLabel']
                    SizeGB            = $sizeGB
                    SizeRemainingGB   = $sizeRemainingGB
                    HealthStatus      = $properties['HealthStatus']
                    OperationalStatus = $properties['OperationalStatus']
                }
            }
        } else {
            # Assuming $volumeEntries contains the `lsblk` output as shown earlier
            $volumeEntries = $result.value -split 'ObjectId\s+:\s+\{1\}' -ne ''

            $df_command = 'df --output=source,fstype,size,used,avail,pcent,target'
            $dfOutput = az vm run-command invoke --resource-group $rg --name $vm.name --command-id $commandId --scripts $df_command | ConvertFrom-Json

            $dfLines = $dfOutput.value -split '\r?\n' | Where-Object { $_ -and $_ -notmatch '^(Filesystem|\s*$)' }

            $spaceInfo = @{}


            foreach ($line in $dfLines) {
                # Splitting the line into columns, expecting 7 columns based on the df command output format
                $columns = $line -split '\s+', 7
                if ($columns.Count -eq 7) {
                    $target = $columns[6]  # The mount point is the last column
                    $availableKB = $columns[4]  # Available space is in the 5th column, in KB

                    # Convert available space from KB to GB, rounding to two decimal places
                    $availableGB = [math]::Round($availableKB / 1024 / 1024, 2)

                    # Ensure we're not capturing command execution status or other non-data lines
                    if ($target -notmatch '^(succeeded:|message=Enable)') {
                        $spaceInfo[$target] = $availableGB
                    }
                }
            }


            $lines = $volumeEntries -split '\r?\n' | Where-Object { $_ -and $_ -notmatch '^\s*NAME' }

            $volumeInfoList = foreach ($line in $lines) {
                $columns = $line -split '\s+', 7

                # Assuming the mount point is always the second last column before size
                $mountpoint = $columns[-2]
                $rawSize = $columns[-1]

                # Convert the size to GB
                $value = $rawSize -replace '[^0-9.]'  # Extract numeric value
                $unit = $rawSize -replace '[0-9.]'    # Extract unit (M or G)
                $sizeInGB = switch ($unit) {
                    "M" { [math]::Round($value / 1024, 3) }  # Convert MB to GB
                    "G" { [double]$value }                   # Already in GB, ensure it's a double
                    default { $rawSize }                     # Unrecognized unit, return original value
                }

                # Validate that sizeInGB is a number
                if ($sizeInGB -match '^-?\d*(\.\d+)?$' -and $sizeInGB -ne '') {
                    $availableSpace = 'N/A'
                    if ($spaceInfo.ContainsKey($mountpoint)) {
                        $availableSpace = $spaceInfo[$mountpoint]
                    }

                    # Create the object with validated and converted size
                    [PSCustomObject]@{
                        VMName            = $vm.name
                        UniqueId          = 'N/A'  # Adjust as needed
                        DriveLetter       = $mountpoint  # Using mountpoint as DriveLetter for Linux
                        DriveType         = 'N/A'
                        FileSystem        = 'N/A'  # Adjust as needed
                        FileSystemLabel   = 'N/A'  # Adjust as needed
                        SizeGB            = $sizeInGB
                        SizeRemainingGB   = $availableSpace
                        HealthStatus      = 'N/A'
                        OperationalStatus = 'N/A'
                    }
                }
            }
            #wait-debugger
        }
        # Parse the volume information from $result.value.message
        

        # Fetch disk details for the current VM (assuming $vmName and $resourceGroup are defined)
        $diskIdsRaw = az vm show --resource-group $rg --name $vm.name --query "[storageProfile.osDisk.managedDisk.id, storageProfile.dataDisks[].managedDisk.id]" --output tsv
        $diskIds = $diskIdsRaw -split '\r?\n|\t| {2,}'

        $diskDetailsList = foreach ($diskId in $diskIds) {
            if (-not [string]::IsNullOrWhiteSpace($diskId)) {
                $diskDetails = az disk show --ids $diskId | ConvertFrom-Json
                # Create a custom object for each disk (simplified here; add more properties as needed)
                [PSCustomObject]@{
                    DiskId       = $diskId
                    DiskName     = $diskDetails.name
                    DiskSizeGB   = $diskDetails.diskSizeGB
                    DiskType     = $diskDetails.sku.name
                }
            }
        }

        # Assuming $volumeInfoList contains all volumes from the VM as previously parsed
        # And $diskDetailsList contains details for all disks associated with the VM

        foreach ($volumeInfo in $volumeInfoList) {
            # Initially, create an output object for the volume
            $outputObj = $volumeInfo | Select-Object @{Name='VMName';Expression={$vm.name}}, @{Name='ResourceGroup';Expression={$rg}}, UniqueId, DriveLetter, DriveType, FileSystem, FileSystemLabel, SizeGB, SizeRemainingGB, HealthStatus, OperationalStatus

            # Add placeholders for disk details to ensure the CSV structure is consistent
            $outputObj | Add-Member -NotePropertyName "DiskName" -NotePropertyValue "N/A"
            $outputObj | Add-Member -NotePropertyName "DiskSizeGB" -NotePropertyValue "N/A"
            $outputObj | Add-Member -NotePropertyName "DiskType" -NotePropertyValue "N/A"

            # Export the volume information to CSV
            $outputObj | Export-Csv -Append -NoTypeInformation -Path "vms_disk_volume_info.csv"
        }

        # After processing all volumes, process each disk
        foreach ($diskDetail in $diskDetailsList) {
            # Create an output object for the disk
            $diskOutputObj = [PSCustomObject]@{
                VMName          = $vm.name
                ResourceGroup   = $rg
                UniqueId        = "N/A" # UniqueId is not applicable for disks directly
                DriveLetter     = "N/A" # DriveLetter is a volume property, not a disk property
                DriveType       = "N/A" # DriveType is also a volume property
                FileSystem      = "N/A" # FileSystem is determined at the volume level
                FileSystemLabel = "N/A" # FileSystemLabel is a volume property
                SizeGB          = "N/A" # Placeholder, will be replaced
                SizeRemainingGB = "N/A" # Not applicable for disks
                HealthStatus    = "N/A" # HealthStatus is a volume property
                OperationalStatus = "N/A" # OperationalStatus is a volume property
                DiskName       = $diskDetail.DiskName
                DiskSizeGB     = $diskDetail.DiskSizeGB
                DiskType       = $diskDetail.DiskType
            }

            # Export the disk information to CSV
            $diskOutputObj | Export-Csv -Append -NoTypeInformation -Path "vms_disk_volume_info.csv"
            #if ($vm.osType -ne "Windows") { wait-debugger }
        }
    }
}

Write-Host "Script completed. Combined disk and volume information is available in $csvFilePath"
