
# Azure VM Disk Inventory Script

This PowerShell script is designed to gather information about the disks of Azure Virtual Machines (VMs), including both Linux and Windows VMs. It uses Azure CLI commands to retrieve data and exports the information to a CSV file for further analysis. The script can be run using the Azure CLI on a local machine.

## Prerequisites

Before using this script, ensure that you have the following prerequisites set up:

1. **Azure CLI**: Install and configure the Azure CLI on your local machine. You can download it from [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

2. **Azure Subscription**: Make sure you are logged into the correct Azure subscription and have the necessary permissions to access and query VM resources.

## Usage

1. Clone or download the repository to your local machine.

2. Open a PowerShell terminal.

3. Navigate to the directory containing the script.

4. Modify the script's variables, such as `$resourceGroupName` and `$outputCsv`, to match your Azure environment and desired output file name.

5. Run the script by executing the following command:

   ```powershell
   ./vm_disk_inventory.ps1
The script will gather information about the disks of all VMs in the specified resource group, including OS disks and data disks. It will also retrieve disk information from both Linux and Windows VMs.

The collected data will be exported to a CSV file named as specified in the $outputCsv variable.

You can now analyze the disk information in the generated CSV file using your preferred tools.

# Output Format
The generated CSV file will contain the following columns:

1. VMName: The name of the Azure Virtual Machine.
2. DiskType: Indicates whether it's an OS Disk or a Data Disk.
3. DiskName: The name of the disk.
4. AzureDiskSizeGB: The size of the disk in gigabytes (GB).
5. AzureDiskType: The type of the disk (e.g., Standard_LRS).
6. AzureDiskId: The Azure Resource ID of the disk.
7. OSDiskInfo: Additional information about the OS disk (for Windows VMs) or Linux disk usage statistics (for Linux VMs).

# Notes
Ensure that you have appropriate permissions to access and retrieve information about Azure resources, including VMs and disks.

The script uses the Azure CLI and can be run using the Azure CLI on your local machine.

The script is designed to work with both Windows and Linux VMs and adapts its commands accordingly.

Be cautious when modifying the script, and ensure you understand its behavior before making changes.

For any issues or questions, please refer to the GitHub repository's issue tracker.
