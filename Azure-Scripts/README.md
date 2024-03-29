# Azure VM Disk Inventory Script
# Overview
This PowerShell script is designed to collect detailed information about the disks attached to Azure Virtual Machines (VMs) within a specified resource group. It caters to both Linux and Windows VMs, capturing essential disk metrics such as disk type, name, size, and more. The script leverages the Azure CLI for querying Azure resources and outputs the disk information into separate text files for Windows and Linux VMs, facilitating easy review and management.

# Prerequisites
Before running the script, ensure you have the following setup completed:

Azure CLI: The script requires Azure CLI to be installed and configured on your local machine. Download Azure CLI
Azure Subscription: Log into your Azure subscription where the target VMs are hosted. Ensure you have necessary permissions to access and manage the VMs and their disks.
PowerShell: The script is written for PowerShell and should be executed in a PowerShell environment.
# Getting Started
Clone or Download the Script:
First, clone this repository or download the script file directly to your local machine.

Open PowerShell:
Launch your PowerShell terminal and navigate to the directory where the script is located.

Configure Script Variables:
Open the script in a text editor and modify any variables such as $resourceGroupName to match your Azure setup and requirements.

Execute the Script:
Run the script by entering the following command in your PowerShell terminal:

powershell
Copy code
./Linux-Windows.ps1
# Script Output
The script will generate two text files: windows.txt and linux.txt, each containing disk information for Windows and Linux VMs respectively. The output files include:

VM Name
Disk Type (OS Disk/Data Disk)
Disk Name
Disk Size (in GB)
Disk ID
Additional Information specific to OS type
# Important Notes
Ensure you have the correct permissions to query and manage Azure VMs and disks.
The script interacts with Azure resources through Azure CLI commands executed in a PowerShell environment.
It's designed to accommodate both Windows and Linux VMs by adapting the commands and parsing logic accordingly.
Exercise caution when modifying the script. Make sure to understand the changes and their potential impacts.
Issues and Contributions
For any issues, questions, or contributions, please refer to the issue tracker of this repository. We welcome your feedback and contributions to improve the script and documentation.
