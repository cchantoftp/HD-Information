import boto3
import csv

def get_ec2_disk_usage():
    ssm = boto3.client('ssm', region_name='us-east-1')  # Replace 'your_region' with your AWS region

    instances = boto3.resource('ec2', region_name='us-east-1').instances.filter(
        Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])

    disk_usage_info = []

    for instance in instances:
        instance_id = instance.id
        instance_type = instance.instance_type
        instance_state = instance.state['Name']

        # Run the command to get disk usage via SSM Run Command
        command = f"df -h /"
        response = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName="AWS-RunShellScript",
            Parameters={'commands': [command]}
        )

        # Retrieve the output of the command
        output = response['Command']['Output']
        disk_info = output.splitlines()[1].split()
        disk_size, used_space, available_space = disk_info[1], disk_info[2], disk_info[3]

        disk_usage_info.append({
            "Instance ID": instance_id,
            "Instance Type": instance_type,
            "Instance State": instance_state,
            "Root Volume Size (GB)": disk_size,
            "Used Space (GB)": used_space,
            "Available Space (GB)": available_space
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
