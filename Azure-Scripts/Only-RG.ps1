# Define the script to run on each Windows VM
$windowsScriptToRun = "Get-Volume | Format-List; Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture"

# Define the script to run on each Linux VM
$linuxScriptToRun = "df -h"

# Get a list of Windows VMs in the specified resource group
$windowsVMs = az vm list --resource-group nf-test --query "[?storageProfile.osDisk.osType=='Windows'].name" -o tsv | ForEach-Object { $_.Trim() }

# Iterate over each Windows VM
foreach ($vm in $windowsVMs) {
    Write-Host "Running script on Windows VM: $vm in resource group 'nf-test'"

    # Run the script on the VM using Azure CLI
    $result = az vm run-command invoke --resource-group nf-test --name $vm --command-id RunPowerShellScript --scripts $windowsScriptToRun | ConvertFrom-Json

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
                Key = $key.Trim()
                Value = $value.Trim()
            }
        }

        # Display the output
        $output
    } else {
        Write-Host "Skipping Windows VM '$vm' in resource group 'nf-test' as it is not running or set to run."
    }
}

# Get a list of Linux VMs in the specified resource group
$linuxVMs = az vm list --resource-group nf-test --query "[?storageProfile.osDisk.osType=='Linux'].name" -o tsv | ForEach-Object { $_.Trim() }

# Iterate over each Linux VM
foreach ($vm in $linuxVMs) {
    Write-Host "Running script on Linux VM: $vm in resource group 'nf-test'"

    # Run the script on the VM using Azure CLI
    $result = az vm run-command invoke --resource-group nf-test --name $vm --command-id RunShellScript --scripts $linuxScriptToRun | ConvertFrom-Json

    if ($result.value) {
        # Extract and format the relevant information from the result
        $output = $result.value.message

        # Display the output
        $output
    } else {
        Write-Host "Skipping Linux VM '$vm' in resource group 'nf-test' as it is not running or set to run."
    }
}