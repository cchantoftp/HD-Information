#!/bin/bash

# Function to get disk and OS information from the system
get_disk_info() {
    local vmName="$1"
    local resourceGroupName="$2"

    osDiskSize=$(df -h / | awk 'NR==2 {print $2}')
    osUsed=$(df -h / | awk 'NR==2 {print $3}')
    osFree=$(df -h / | awk 'NR==2 {print $4}')

    osType=$(lsb_release -d | awk -F "\t" '{print $2}')

    echo "VMName,DiskType,DiskName,AzureDiskSizeGB,OSDiskSizeReportedGB,OSUsedGB,OSFreeGB,UnusedGB,OSType"
    echo "$vmName,OS Disk,/,,$osDiskSize,$osUsed,$osFree,,$osType"
}

resourceGroupName="nf-test" #Name
vmName="Ps-Test" #vmname

info="$(get_disk_info "$vmName" "$resourceGroupName")"

echo "$info" | sed 's/,$//' > DiskInfoLinux.csv
