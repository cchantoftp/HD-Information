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
            # Process and convert the result for CSV format
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
                    Key = $key.Trim()
                    Value = $value.Trim()
                }
            }

            # Append the output to windows.csv
            $output | Export-Csv -Append -NoTypeInformation -Path "windows.csv"
        } else {
            Write-Host "Skipping Windows VM '$vm' in resource group '$rg' as it is not running or set to run."
        }
    }

    # Repeat similar steps for Linux VMs, adjusting the output processing as needed for the Linux script's output.
    # Note: The example above focuses on the Windows VMs part. You will need to adjust the handling of the Linux VMs' output
    # similarly, ensuring that the data structure fits a CSV format and using `Export-Csv` as shown.
}
