# SSM configuration to grant all your ec2 into region  cloudwatch agent or ssm agent

Please make sure thaht you configurte it before apply the python script
AWS Systems Manager (SSM) allows you to manage and configure your EC2 instances at scale without needing to connect to each instance individually. SSM Quick Setup provides a streamlined process for installing and configuring the SSM Agent on your EC2 instances, enabling you to manage them remotely.

# Prerequisites:

An AWS account with permissions to access AWS Systems Manager.
EC2 instances running within the AWS environment.
Basic knowledge of AWS services and EC2 instance management.
Steps to Setup SSM Agent using SSM Quick Setup:

Step 1: Access AWS Management Console

Log in to your AWS Management Console: https://aws.amazon.com/console/
Step 2: Navigate to Systems Manager

Go to the AWS Systems Manager Console by searching for "Systems Manager" in the services search bar.
Step 3: Access Quick Setup

In the Systems Manager Console, navigate to "Quick Setup" located in the left navigation pane.
Step 4: Launch Quick Setup

Click on the "Quick Setup" option to start the process.
Step 5: Select EC2 Instances

Choose the EC2 instances for which you want to install the SSM Agent. You can select instances individually or choose entire Auto Scaling groups.
Step 6: Review and Confirm

Review the selected instances and configurations to ensure they are accurate.
Click on the "Install SSM Agent" button to proceed.
Step 7: Monitor Progress

Systems Manager will now begin the process of installing and configuring the SSM Agent on the selected instances.
Monitor the progress in the Systems Manager Console. You can also track progress using CloudWatch logs.
Step 8: Verify Installation

Once the installation process is complete, verify that the SSM Agent is successfully installed on your EC2 instances.
You can do this by checking the status of the SSM Agent in the Systems Manager Console or by running commands remotely using the AWS Systems Manager Run Command feature.
Step 9: Start Managing Instances

With the SSM Agent installed and configured, you can now start managing your EC2 instances remotely using AWS Systems Manager features such as Run Command, State Manager, and Session Manager.
Additional Resources:

AWS Systems Manager Documentation
SSM Agent Installation Guide
AWS SSM Quick Setup Guide
Note: Ensure that your IAM policies and roles have the necessary permissions to interact with AWS Systems Manager and EC2 instances. It's also recommended to follow AWS best practices for security and compliance when configuring your instances and permissions.



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