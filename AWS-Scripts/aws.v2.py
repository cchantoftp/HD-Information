import boto3
import csv

def get_ec2_disk_usage():
    ec2 = boto3.client('ec2', region_name='us-east-1')  # Replace 'your_region' with your AWS region

    instances = ec2.describe_instances()

    disk_usage_info = []

    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            instance_type = instance['InstanceType']
            instance_state = instance['State']['Name']

            # Get disk usage for the root volume of the EC2 instance
            block_device_mappings = instance.get('BlockDeviceMappings', [])
            root_volume = [volume for volume in block_device_mappings if volume['DeviceName'] == instance['RootDeviceName']]
            if root_volume:
                volume_id = root_volume[0]['Ebs']['VolumeId']
                disk_info = ec2.describe_volumes(VolumeIds=[volume_id])['Volumes'][0]
                disk_size = disk_info['Size']
                used_space = disk_size - disk_info['Size']  # Calculate used space as (total - available)
                disk_usage_info.append({
                    "Instance ID": instance_id,
                    "Instance Type": instance_type,
                    "Instance State": instance_state,
                    "Root Volume Size (GB)": disk_size,
                    "Used Space (GB)": used_space,
                    "Available Space (GB)": disk_info['Size']
                })

    return disk_usage_info

if __name__ == "__main__":
    usage_info = get_ec2_disk_usage()
    print("EC2 Disk Usage:")
    for info in usage_info:
        print(f"Instance ID: {info['Instance ID']}")
        print(f"Instance Type: {info['Instance Type']}")
        print(f"Instance State: {info['Instance State']}")
        print(f"Root Volume Size (GB): {info['Root Volume Size (GB)']}")
        print(f"Used Space (GB): {info['Used Space (GB)']}")
        print(f"Available Space (GB): {info['Available Space (GB)']}")
        print()

    # Create a CSV file
    with open('ec2_disk_usage.csv', 'w', newline='') as csvfile:
        fieldnames = ['Instance ID', 'Instance Type', 'Instance State', 'Root Volume Size (GB)', 'Used Space (GB)', 'Available Space (GB)']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        for info in usage_info:
            writer.writerow(info)

    print("CSV file 'ec2_disk_usage.csv' has been created.")
