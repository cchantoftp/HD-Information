# EC2 Disk Usage Script with CSV Output
This Python script allows you to retrieve and display disk usage information for your Amazon EC2 instances in a specified AWS region and saves the data to a CSV file.

# Prerequisites
AWS CLI installed and configured with appropriate credentials.

Python 3.x installed on your local machine.

Boto3 library installed. You can install it using pip:

Copy code
pip install boto3
Usage
Clone the Repository

Clone this repository to your local machine:

bash
Copy code
git clone
Configure AWS Credentials

Ensure that your AWS CLI is configured with the necessary AWS credentials. You can configure it using aws configure.

Modify the Script

Open the ec2_disk_usage.py script and replace 'your_region' with your AWS region. Save the changes.

Run the Script

Navigate to the directory where the script is located and execute it:

bash
Copy code
python ec2_disk_usage.py
The script will retrieve disk usage information for all your EC2 instances in the specified region, calculate used and available space, and display the data. It will also create a CSV file named ec2_disk_usage.csv with the collected information.

Install CloudWatch Agent (Note)

If the script is unable to retrieve used and available disk space data, it may be because the CloudWatch Agent is not installed and configured on your EC2 instances. To collect detailed disk metrics, consider installing and configuring the CloudWatch Agent on your EC2 instances. You can find installation instructions in the AWS documentation.
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-on-EC2-Instance.html

# Example Output
mathematica
Copy code
EC2 Disk Usage:
Instance ID: i-1234567890abcdef0
Instance Type: t2.micro
Instance State: running
Root Volume Size (GB): 30
Used Space (GB): 12
Available Space (GB): 18

Instance ID: i-9876543210fedcba0
Instance Type: m5.large
Instance State: stopped
Root Volume Size (GB): 100
Used Space (GB): 25
Available Space (GB): 75
CSV File

After running the script, a CSV file named ec2_disk_usage.csv will be created in the same directory. You can open this file using a spreadsheet program like Excel to further analyze or share the disk usage data.

# Notes
Make sure your AWS IAM user has the necessary permissions to describe EC2 instances and volumes.
Doc here
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-on-EC2-Instance.html

Replace 'your_region' with the actual AWS region where your EC2 instances are located.

Ensure that Boto3 is correctly installed and Python 3.x is used to run the script.

If detailed disk usage data is missing, consider installing and configuring the CloudWatch Agent on your EC2 instances as described in step 5.


# SSM configuration to grant all your ec2 into region  cloudwatch agent or ssm agent

Please make sure thaht you configurte it before apply the python script




# Roles Configuration
To execute the actions performed by the script, such as describing EC2 instances, executing commands on instances using AWS Systems Manager (SSM), and putting objects into an S3 bucket, the IAM roles assigned to the Lambda function need specific permissions. Here's a breakdown of the required IAM policies:

Describe EC2 Instances:

The Lambda function needs permission to describe EC2 instances in the specified region. You can use the ec2:DescribeInstances action.
Example IAM policy statement:
json
Copy code
{
    "Effect": "Allow",
    "Action": "ec2:DescribeInstances",
    "Resource": "*"
}
Execute Commands with SSM:

The Lambda function needs permission to execute commands on EC2 instances using AWS Systems Manager (SSM). This includes actions like ssm:SendCommand, ssm:GetCommandInvocation, etc.
Example IAM policy statement:
json
Copy code
{
    "Effect": "Allow",
    "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation"
    ],
    "Resource": "*"
}
Put Object into S3 Bucket:

The Lambda function needs permission to put objects into the specified S3 bucket. Use the s3:PutObject action.
Example IAM policy statement:
json
Copy code
{
    "Effect": "Allow",
    "Action": "s3:PutObject",
    "Resource": "arn:aws:s3:::s3-bucket-name/*"
}
Ensure that these policies are attached to the IAM role associated with the Lambda function. You can create a custom IAM policy combining these statements or attach separate policies with specific permissions based on your organization's security requirements. Additionally, always follow the principle of least privilege, granting only the permissions necessary for the Lambda function to perform its intended actions.