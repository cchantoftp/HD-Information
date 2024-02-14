import subprocess

def get_disk_usage():
    # Use subprocess to run the 'df' command and capture its output
    df_output = subprocess.check_output(['df', '-h', '/']).decode('utf-8').splitlines()

    # Split the output and extract the total, used, and free space values
    _, total, used, free, *_ = df_output[1].split()

    return {
        "total": total,
        "used": used,
        "free": free
    }

if __name__ == "__main__":
    usage = get_disk_usage()
    print("Disk usage:")
    print(f"Total: {usage['total']}")
    print(f"Used: {usage['used']}")
    print(f"Free: {usage['free']}")
