#az login

# Set your Azure subscription
#$subscriptionId = "b34abaea-961b-4fc8-8e8b-38118036e83b"
#az account set --subscription $subscriptionId

# Variables
$outputCsv = "1vm_disk_inventory.csv"

# Function to get disk info and usage from VM's guest OS
function Get-GuestOSDiskInfo {
    param (
        $vmName,
        $osType,
        $resourceGroupName
    )

    if ($osType -eq "Linux") {
        # Run a shell command to get disk usage information
        $diskInfo = az vm run-command invoke -g $resourceGroupName -n $vmName --command-id RunShellScript --scripts "df -h" --query "value[0].message" | Out-String
    } else {
        # Run a PowerShell command to get disk usage information
        $diskInfo = az vm run-command invoke -g $resourceGroupName -n $vmName --command-id RunPowerShellScript --scripts "Get-Volume | Format-List" --query "value[0].message" | Out-String
    }

    # Remove extra line breaks and spaces
    $diskInfo = $diskInfo -replace '\r?\n', ' ' -replace '\s+', ' '

    return $diskInfo.Trim()
}

# Get all resource groups in the subscription
$resourceGroups = az group list --query "[].name" -o tsv

# Array to hold all data
$allData = @()

foreach ($resourceGroupName in $resourceGroups) {
    Write-Host "Checking VMs in resource group: $resourceGroupName"
    # Getting VM details in each resource group
    $vms = az vm list -g $resourceGroupName --query "[].{Name:name, OsType:storageProfile.osDisk.osType}" | ConvertFrom-Json

    foreach ($vm in $vms) {
        $vmName = $vm.Name
        $osType = $vm.OsType

        Write-Host "Checking VM: $vmName in resource group: $resourceGroupName"

        try {
            # Get VM instance view to check state
            $vmState = az vm get-instance-view -g $resourceGroupName -n $vmName --query "instanceView.statuses[?code=='PowerState/running'].displayStatus" -o tsv

            if ($vmState -eq "VM running") {
                # Get Azure Disk Details
                # Fetching the ID of the OS disk and data disks from the VM object
                $osDiskId = az vm show -g $resourceGroupName -n $vmName --query "storageProfile.osDisk.managedDisk.id" -o tsv
                $dataDisksIds = az vm show -g $resourceGroupName -n $vmName --query "storageProfile.dataDisks[].managedDisk.id" -o tsv

                # Combining OS and data disks IDs into an array
                $diskIds = @($osDiskId) + @($dataDisksIds)

                # Get Guest OS Disk Details
                $osDiskInfo = Get-GuestOSDiskInfo -vmName $vmName -osType $osType -resourceGroupName $resourceGroupName

                foreach ($diskId in $diskIds) {
                    # Get details for each disk using its ID
                    if (-not [string]::IsNullOrWhiteSpace($diskId)) {
                        $diskDetails = az disk show --ids $diskId --query "{Name:name, DiskSizeGB:diskSizeGb, DiskType:sku.name}" | ConvertFrom-Json

                        # Construct the data object for each disk
                        $dataObj = New-Object PSObject -Property @{
                            DiskName          = $diskDetails.Name
                            AzureDiskId       = $diskId
                            AzureDiskSizeGB   = $diskDetails.DiskSizeGB
                            OSDiskInfo        = if ($osDiskId -eq $diskId) { $osDiskInfo } else { "" }
                            ResourceGroupName = $resourceGroupName
                            VMName            = $vmName
                            DiskType          = if ($osDiskId -eq $diskId) { "OS Disk" } else { "Data Disk" }
                            AzureDiskType     = $diskDetails.DiskType
                        }

                        # Add the data object to the array of all data
                        $allData += $dataObj
                    }
                }
            } else {
                # Output when VM is not running
                Write-Host "Skipping VM '$vmName' in resource group '$resourceGroupName' as it is not running."
            }
        } catch {
            Write-Host "Failed to retrieve disk information for VM '$vmName' in resource group '$resourceGroupName'."
        }
    }
}

# Export to CSV (ensure you have permissions to write to the location)
$allData | Export-Csv -Path ./$outputCsv -NoTypeInformation
