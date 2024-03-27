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
            # Extract and format the relevant information from the result
            $output = $result.value.message -split "`n" | Where-Object { $_ -match ': ' } | ForEach-Object {
                $key, $value = $_ -split ': ', 2
                if ($key.Trim() -eq "Size" -or $key.Trim() -eq "SizeRemaining") {
                    $value = [double]($value.Trim() -replace ',', '') / 1GB
                    $value = [math]::Round($value, 2)
                    $value = "$value GB"
                }
                [PSCustomObject]@{
                    VMName = $vm
                    ResourceGroup = $rg
                    OperatingSystem = "Windows"
                    Key = $key.Trim()
                    Value = $value.Trim()
                }
            }

            # Export the output to the Windows CSV file
            $output | Export-Csv -Append -NoTypeInformation -Path "windows.csv"
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
            # Extract and format the relevant information from the result
            $output = $result.value.message -split "`n" | Where-Object { $_ -match '\S' } | ForEach-Object {
                [PSCustomObject]@{
                    VMName = $vm
                    ResourceGroup = $rg
                    OperatingSystem = "Linux"
                    Output = $_
                }
            }

            # Export the output to the Linux CSV file
            $output | Export-Csv -Append -NoTypeInformation -Path "linux.csv"
        } else {
            Write-Host "Skipping Linux VM '$vm' in resource group '$rg' as it is not running or set to run."
        }
    }
}