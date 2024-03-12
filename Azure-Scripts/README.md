# Azure VM Disk Inventory Script
This PowerShell script is designed to gather information about the disks of Azure Virtual Machines (VMs), including both Linux and Windows VMs. It uses Azure CLI commands to retrieve data and exports the information to separate text files for Windows and Linux VMs. The script can be run using the Azure CLI on a local machine.

# Prerequisites
Before using this script, ensure that you have the following prerequisites set up:

Azure CLI: Install and configure the Azure CLI on your local machine. You can download it from here.

Azure Subscription: Make sure you are logged into the correct Azure subscription and have the necessary permissions to access and query VM resources.

# Usage
Clone or download the repository to your local machine.

Open a PowerShell terminal.

Navigate to the directory containing the script.

Modify the script's variables, such as $resourceGroupName, to match your Azure environment.

Run the script by executing the following command:

# Powershell

./Linux-Windows.ps1

The script will gather information about the disks of all VMs in the specified resource group, including OS disks and data disks. It will then export the information to separate text files named "windows.txt" and "linux.txt" for Windows and Linux VMs, respectively.

You can now review the disk information in the generated text files.

# Output Format
The information in the generated text files includes the following columns:

VMName: The name of the Azure Virtual Machine.
DiskType: Indicates whether it's an OS Disk or a Data Disk.
DiskName: The name of the disk.
DiskSizeGB: The size of the disk in gigabytes (GB).
DiskId: The Azure Resource ID of the disk.
Additional Information: Additional information about the disk, such as OS disk details for Windows VMs or disk usage statistics for Linux VMs.
Notes
Ensure that you have appropriate permissions to access and retrieve information about Azure resources, including VMs and disks.

The script uses the Azure CLI and can be run using the Azure CLI on your local machine.

The script is designed to work with both Windows and Linux VMs and adapts its commands accordingly.

Be cautious when modifying the script, and ensure you understand its behavior before making changes.

For any issues or questions, please refer to the GitHub repository's issue tracker.
