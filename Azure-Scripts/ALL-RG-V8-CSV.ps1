# Define the script to run on each Windows VM
$windowsScriptToRun = "Get-Volume | Format-List; Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture"

# Define the script to run on each Linux VM
$linuxScriptToRun = "df -h | awk 'NR>1 {print $1, $2, $3, $4, $5, $6}'"

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

        # Parse the volume information from $result.value.message
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
            #wait-debugger
        }
    }
}

Write-Host "Script completed. Combined disk and volume information is available in $csvFilePath"
