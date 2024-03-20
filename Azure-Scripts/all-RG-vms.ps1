# Define the Windows script to run
$windowsScriptToRun = "Get-Volume | Format-List; Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture"

# Define the Linux script to run
$linuxScriptToRun = "df -h"

# Initialize arrays to store output data
$windowsOutput = @()
$linuxOutput = @()

# Get a list of resource groups
$resourceGroups = az group list --query "[].name" -o tsv

# Iterate over each resource group
foreach ($rg in $resourceGroups) {
    Write-Host "Running script on VMs in resource group: $rg"

    # Get a list of Windows VMs in the current resource group
    $windowsVMs = az vm list --resource-group $rg --query "[?storageProfile.osDisk.osType=='Windows'].name" -o tsv | ForEach-Object { $_.Trim() }

    # Iterate over each Windows VM in the current resource group
    foreach ($vm in $windowsVMs) {
        Write-Host "Running script on Windows VM: $vm in resource group: $rg"

        # Run the script on the Windows VM using Azure CLI
        $result = az vm run-command invoke --resource-group $rg --name $vm --command-id RunPowerShellScript --scripts $windowsScriptToRun | ConvertFrom-Json

        if ($result.value) {
            # Add Windows output to the array
            $windowsOutput += [PSCustomObject]@{
                VMName = $vm
                ResourceGroup = $rg
                Output = $result.value.message -join "`n"
                OSType = "Windows"
            }
        } else {
            Write-Host "Skipping Windows VM '$vm' in resource group '$rg' as it is not running or set to run."
        }
    }

    # Get a list of Linux VMs in the current resource group
    $linuxVMs = az vm list --resource-group $rg --query "[?storageProfile.osDisk.osType=='Linux'].name" -o tsv | ForEach-Object { $_.Trim() }

    # Iterate over each Linux VM in the current resource group
    foreach ($vm in $linuxVMs) {
        Write-Host "Running script on Linux VM: $vm in resource group: $rg"

        # Run the script on the Linux VM using Azure CLI
        $result = az vm run-command invoke --resource-group $rg --name $vm --command-id RunShellScript --scripts $linuxScriptToRun | ConvertFrom-Json

        if ($result.value) {
            # Add Linux output to the array
            $linuxOutput += [PSCustomObject]@{
                VMName = $vm
                ResourceGroup = $rg
                Output = $result.value.message -join "`n"
                OSType = "Linux"
            }
        } else {
            Write-Host "Skipping Linux VM '$vm' in resource group '$rg' as it is not running or set to run."
        }
    }
}

# Export Windows output to CSV
$windowsOutput | Export-Csv -Path "windows_output.csv" -NoTypeInformation

# Export Linux output to CSV
$linuxOutput | Export-Csv -Path "linux_output.csv" -NoTypeInformation
