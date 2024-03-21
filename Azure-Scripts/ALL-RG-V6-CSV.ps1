# Define the script to run on each Windows VM
$windowsScriptToRun = "Get-Volume | Format-List; Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture"

# Define the script to run on each Linux VM
$linuxScriptToRun = "df -h"

# Get a list of resource groups
$resourceGroups = az group list --query "[].name" -o tsv

# Ensure the CSV files are clear at the beginning of the script
if (Test-Path "windows.csv") { Remove-Item "windows.csv" }
if (Test-Path "linux.csv") { Remove-Item "linux.csv" }

# Iterate over each resource group
# Iterate over each resource group
foreach ($rg in $resourceGroups) {
    Write-Host "Running script on VMs in resource group: $rg"

    # Get a list of Windows VMs in the current resource group
    $windowsVMs = az vm list --resource-group $rg --query "[?storageProfile.osDisk.osType=='Windows'].name" -o tsv | ForEach-Object { $_.Trim() }

    # Iterate over each Windows VM in the current resource group
    foreach ($vm in $windowsVMs) {
        Write-Host "Running script on Windows VM: $vm in resource group: $rg"

        # Fetch disk IDs for the current VM
        $diskIdsRaw = az vm show --resource-group $rg --name $vm --query "[storageProfile.osDisk.managedDisk.id, storageProfile.dataDisks[].managedDisk.id]" --output tsv

        # Split the $diskIdsRaw into an array of individual disk IDs
        # The -split operator uses regular expressions to split the string on newlines, tabs, or multiple spaces
        $diskIds = $diskIdsRaw -split '\r?\n|\t| {2,}'

        foreach ($diskId in $diskIds) {
            if (-not [string]::IsNullOrWhiteSpace($diskId)) {
                $diskDetails = az disk show --ids $diskId | ConvertFrom-Json
                # Process each disk's details as needed
                # For example, add disk details to the output object for each disk
            }
        }

        # Run the script on the Windows VM using Azure CLI
        $result = az vm run-command invoke --resource-group $rg --name $vm --command-id RunPowerShellScript --scripts $windowsScriptToRun | ConvertFrom-Json

        # Process the result and create the output object as before
        # Add disk details to the output object
        if ($result.value) {
        # Split the result into individual disk entries
        $diskEntries = $result.value.message -split 'ObjectId\s+:\s+\{1\}' -ne ''

        foreach ($diskEntry in $diskEntries) {
            # Extract key values using regex
            $matches = [regex]::Matches($diskEntry, '(?m)^(.+?)\s+:\s+(.+)$')
            $properties = @{}
            foreach ($match in $matches) {
                $properties[$match.Groups[1].Value.Trim()] = $match.Groups[2].Value.Trim()
            }

            # Handle missing or merged DriveLetter
            if ($properties.ContainsKey('DriveLetter')) {
                $driveLetter = $properties['DriveLetter']
                # Check if DriveLetter is merged with DriveType
                if ($driveLetter.StartsWith("DriveType")) {
                    $properties['DriveType'] = $driveLetter.Substring(11).Trim()
                    $properties['DriveLetter'] = $null
                }
            } else {
                $properties['DriveLetter'] = $null
            }

            # Convert Size and SizeRemaining from bytes to GB and round to 2 decimal places
            $sizeGB = [math]::Round([double]$properties['Size'] / 1GB, 2)
            $sizeRemainingGB = [math]::Round([double]$properties['SizeRemaining'] / 1GB, 2)

            # Create a custom object for CSV export
            $outputObj = [PSCustomObject]@{
                VMName           = $vm
                ResourceGroup    = $rg
                DriveLetter      = $properties['DriveLetter']
                DriveType        = $properties['DriveType']
                FileSystem       = $properties['FileSystem']
                SizeGB           = $sizeGB
                SizeRemainingGB  = $sizeRemainingGB
                HealthStatus     = $properties['HealthStatus']
                OperationalStatus= $properties['OperationalStatus']
            }
            
            
           if ($diskDetails) {
                $outputObj | Add-Member -NotePropertyName "DiskType" -NotePropertyValue $diskDetails.sku.name
                $outputObj | Add-Member -NotePropertyName "DiskSizeGB" -NotePropertyValue ($diskDetails.diskSizeGB)
            }
            if $vm -eq 'nf-win01'{wait-debugger}
            #wait-debugger
            # Append the object to the CSV file
            $outputObj | Export-Csv -Append -NoTypeInformation -Path "windows.csv"
        }
    } else {
        Write-Host "Skipping Windows VM '$vm' in resource group '$rg' as it is not running or set to run."
    }
    }
    # Repeat similar steps for Linux VMs, adjusting the output processing as needed for the Linux script's output.
    # Note: The example above focuses on the Windows VMs part. You will need to adjust the handling of the Linux VMs' output
    # similarly, ensuring that the data structure fits a CSV format and using `Export-Csv` as shown.
}
