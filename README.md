# Cloud Disk Usage Scripts
This project includes scripts for monitoring and retrieving disk usage information in two popular cloud providers: Amazon Web Services (AWS) and Microsoft Azure. The scripts are designed to help you gather disk usage data for your cloud resources.

# Project Structure
The project is organized into two main folders:

AWS Scripts: This folder contains Python scripts specifically designed to work with AWS services. These scripts use the Boto3 library to interact with AWS services, retrieve EC2 disk usage data, and save it to a CSV file.

Azure Scripts: In this folder, you'll find PowerShell (Ps1) scripts that are tailored for Microsoft Azure. These scripts leverage Azure PowerShell modules to collect and display disk usage information for Azure virtual machines.

Prerequisites
Before using the scripts, make sure you have the following prerequisites in place:

# AWS Scripts:

AWS CLI installed and configured with appropriate credentials.
Python 3.x installed on your local machine.
Boto3 library installed. You can install it using pip.
Azure Scripts:

Azure PowerShell modules installed on your local machine.
Appropriate Azure credentials and permissions to access Azure resources.
Usage
# AWS Scripts
Clone the Repository: Clone this repository to your local machine.

Configure AWS Credentials: Ensure that your AWS CLI is configured with the necessary AWS credentials using aws configure.

Run the AWS Scripts: Navigate to the AWS Scripts folder, modify the script if needed, and run it using Python.

The AWS scripts retrieve disk usage data for your EC2 instances, calculate used and available space, and save the data to a CSV file.

# Azure Scripts
Clone the Repository: Clone this repository to your local machine.

Configure Azure Credentials: Ensure that you have Azure PowerShell modules installed and configured with the appropriate Azure credentials.

Run the Azure Scripts: Navigate to the Azure Scripts folder, modify the script if needed, and execute it using PowerShell.

The Azure scripts collect disk usage information for your Azure virtual machines and display it.

# Note
This project provides scripts for monitoring and retrieving disk usage data in AWS and Azure. Ensure that you meet the prerequisites and follow the instructions within each folder to run the respective scripts for your cloud provider.

The project aims to provide a convenient way to monitor and manage disk usage in both AWS and Azure environments.