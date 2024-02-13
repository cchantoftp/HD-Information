import json
import boto3

def lambda_handler(event, context):
    # Set the region and S3 bucket name
    region = 'us-east-1'
    s3_bucket_name = 'diskinfofpcomplete'

    # Create Boto3 clients for EC2 and S3
    ec2_client = boto3.client('ec2', region_name=region)
    s3_client = boto3.client('s3', region_name=region)

    # Define the instance IDs to target
    instance_ids = ['i-06a08e6c6f523e971', 'i-096d731bc257e3feb']

    # Initialize dictionary to store disk information
    disk_info = {}

    # Loop through each instance and gather information
    for instance_id in instance_ids:
        # Get instance details
        instance_info = ec2_client.describe_instances(InstanceIds=[instance_id])
        instance_type = instance_info['Reservations'][0]['Instances'][0]['InstanceType']
        private_ip = instance_info['Reservations'][0]['Instances'][0]['PrivateIpAddress']

        # Get disk information using EC2 instance metadata
        disk_info[instance_id] = {}
        disk_info[instance_id]['instance_type'] = instance_type
        disk_info[instance_id]['private_ip'] = private_ip

        # Fetch disk information from the EC2 instance
        disk_info_command = "df -h"
        disk_info_response = execute_ssm_command(instance_id, disk_info_command)

        # Extract relevant disk information from the response
        disk_info[instance_id]['disk_usage'] = disk_info_response

    # Save disk information to S3
    s3_key = 'disk_info.json'
    s3_client.put_object(Body=json.dumps(disk_info), Bucket=s3_bucket_name, Key=s3_key)

    # Save command output to S3
    command_output_key = 'command_output.txt'
    s3_client.put_object(Body=json.dumps(disk_info_response), Bucket=s3_bucket_name, Key=command_output_key)

    return {
        'statusCode': 200,
        'body': json.dumps('Disk information saved to S3')
    }

def execute_ssm_command(instance_id, command):
    # Create Boto3 client for SSM
    ssm_client = boto3.client('ssm')

    # Execute command on the instance using SSM
    response = ssm_client.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={'commands': [command]},
    )

    # Get command execution details
    command_id = response['Command']['CommandId']

    # Wait for command execution to complete
    waiter = ssm_client.get_waiter('command_executed')
    waiter.wait(
        CommandId=command_id,
        InstanceId=instance_id
    )

    # Get command output
    output = ssm_client.get_command_invocation(
        CommandId=command_id,
        InstanceId=instance_id
    )['StandardOutputContent']

    return output
