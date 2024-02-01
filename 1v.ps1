# Login to Azure (Uncomment if not already logged in)
# Connect-AzAccount

# Function to get disk information from Azure and the OS
function Get-DiskInfo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$vmName,
        [Parameter(Mandatory=$true)]
        [string]$resourceGroupName
    )

    # Getting VM details
    $vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroupName
    write-host $vm

    # Getting OS disk details from Azure
    $osDisk = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name
    write-host $osDisk
    # Getting data disk details from Azure
    $dataDisks = $vm.StorageProfile.DataDisks | ForEach-Object {
        Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $_.Name
    }

    write-host $dataDisks
    # Getting disk usage details from within the OS
    try {
        $diskUsageResult = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $vmName -CommandId 'RunPowerShellScript' -ScriptString {
            Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null } | Select-Object Name, @{Name="Used (GB)"; Expression={"{0:N2}" -f ($_.Used / 1GB)}}, @{Name="Free (GB)"; Expression={"{0:N2}" -f ($_.Free / 1GB)}}, @{Name="TotalSize (GB)"; Expression={"{0:N2}" -f ($_.Used / 1GB + $_.Free / 1GB)}}
        }
        write-host $diskUsageResult
        $diskUsageString = $diskUsageResult.Value[0].Message -split "`r`n" | Where-Object { $_ -match '\w' }
        write-host $diskUsageLines
        $diskUsageLines = $diskUsageString -split "`n" | Where-Object { $_ -match '\w' } | Select-Object -Skip 2
    }
    catch {
        $diskUsageLines = @("Error: Unable to retrieve disk usage")
    }

    # Construct disk details object
    $diskDetails = foreach ($line in $diskUsageLines) {
        $lineData = $line -split '\s+', 6
        if ($lineData.Count -ge 4) {
            $osDiskSizeRounded = [math]::Ceiling($lineData[3])
            $matchedDisk = $null
            if ($lineData[0] -match 'C') {  # Assuming C: drive is always OS Disk
                $matchedDisk = $osDisk
            } else {
                $matchedDisk = $dataDisks | Where-Object { [math]::Ceiling($_.DiskSizeGB) -eq $osDiskSizeRounded } | Select-Object -First 1
            }

            [PSCustomObject]@{
                VMName = $vmName
                DiskType = if ($matchedDisk.Name -like "*OsDisk*") { "OS Disk" } else { "Data Disk" }
                DiskName = $lineData[0]
                AzureDiskSizeGB = $matchedDisk.DiskSizeGB
                OSDiskSizeReportedGB = $osDiskSizeRounded
                OSUsedGB = $lineData[1]
                OSFreeGB = $lineData[2]
                #TotalSizeGB = $lineData[3]
                UnusedGB = $lineData[3] - $lineData[1]
            }
        }
    }

    return $diskDetails
}

# Replace with your actual Resource Group Name and VM Names
$resourceGroupName = "nf-test"
$vmNames = @("nf-win01") # List of VM names

# Collecting information
$info = foreach ($vmName in $vmNames) {
    Get-DiskInfo -vmName $vmName -resourceGroupName $resourceGroupName
}

# Flattening the array of arrays
$flattenedInfo = $info | Select-Object

# Exporting to CSV
$flattenedInfo | Export-Csv -Path "AzureVMDiskDetails.csv" -NoTypeInformation