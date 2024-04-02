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


# Notes



Explanation of "N/A" Values in Output

The script generates a CSV file containing disk and volume information for VMs. In cases where certain information is not available or not applicable, the script sets the value to "N/A" (Not Available). Below are explanations for why certain values might be "N/A" in the output:

UniqueId:

Windows VMs: This value might be unavailable because the script does not gather unique volume identifiers for Windows VMs.
Linux VMs: Unique identifiers for volumes are not typically available in Linux environments.
DriveLetter:

Linux VMs: Linux systems do not typically assign drive letters like Windows. Instead, mount points are used, which are provided where drive letters are expected.
DriveType, FileSystem, FileSystemLabel:

Linux VMs: These values might not be directly available or relevant for Linux systems. Linux filesystems may not have explicit labels like Windows.
SizeRemainingGB:

For volumes or disks where real-time data about remaining space is unavailable, this field is set to "N/A".
In Linux systems, the available space might not be directly retrievable for all volumes due to permissions or other system configurations.
HealthStatus, OperationalStatus:

If the script cannot retrieve health or operational status for a volume or disk, these fields are set to "N/A".
These values might not be applicable or retrievable depending on the system configuration or underlying infrastructure.
DiskName, DiskSizeGB, DiskType:

For volumes, these fields are set to "N/A" because volumes do not have direct disk-related properties.
These properties are specific to disks and are not relevant for individual volumes.
Other Fields:

Additional fields marked as "N/A" might represent properties that are either not applicable or not retrievable based on the script's logic or limitations of the environment.
These "N/A" values ensure consistency in the CSV output structure and indicate where specific information is unavailable or not applicable for the given context.


