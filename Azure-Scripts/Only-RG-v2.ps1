# Define the path for the output text file in the same directory as the script
$outputFilePath = Join-Path -Path $PSScriptRoot -ChildPath "output.txt"

# Define the script to run on each Windows VM
$scriptToRun = "Get-Volume | Format-List; Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture"

# Get a list of Windows VMs in the specified resource group
$vms = az vm list --resource-group nf-test --query "[?storageProfile.osDisk.osType=='Windows'].name" -o tsv | ForEach-Object { $_.Trim() }

# Iterate over each Windows VM
foreach ($vm in $vms) {
    Write-Host "Running script on Windows VM: $vm"

    # Run the script on the VM using Azure CLI
    $result = az vm run-command invoke --resource-group nf-test --name $vm --command-id RunPowerShellScript --scripts $scriptToRun | ConvertFrom-Json

    if ($result.value) {
        # Extract and format the relevant information from the result
        $output = $result.value.message -split "`n" | Where-Object { $_ -match ': ' } | ForEach-Object {
            $key, $value = $_ -split ': ', 2
            [PSCustomObject]@{
                Key = $key.Trim()
                Value = $value.Trim()
            }
        }

        # Save the output to the text file
        $output | Format-Table | Out-File -FilePath $outputFilePath -Append

        # Display the output
        $output
    } else {
        Write-Host "Skipping Windows VM '$vm' in resource group 'nf-test' as it is not running or set to run."
    }
}

# Output file location
Write-Host "Output saved to: $outputFilePath"