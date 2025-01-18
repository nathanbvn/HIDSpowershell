# HIDSpowershell
Visual HIDS in powershell 

## Installation

### Prerequisites:
- **Operating System:** Windows
- **Access to PowerShell**
- **Access to Local Files** (for monitoring local machines)
- **Access to Remote Files** (for monitoring remote machines)

### Steps to Prepare for HIDS Usage:
To use our HIDS, you must allow the execution of scripts signed with a self-signed certificate. Follow these steps:

1. Set the **ExecutionPolicy** to `RemoteSigned` by running the following command in PowerShell:
   ```powershell
   Set-ExecutionPolicy RemoteSigned
   ```
   
Note: You can also set it to Bypass or Unrestricted, but these options are less secure than RemoteSigned.

When launching HIDS, you will be presented with two options:
- Monitoring the local machine.
- Monitoring a remote machine.

  
*Remote Monitoring Configuration*:
For remote monitoring, you need to configure both the HIDS-running machine and the machine to be monitored:

- Open PowerShell as an administrator.

- Ensure the network category is set to Private using: `Get-NetConnectionProfile`

- If the category is not private, update it using:

```powershell
Set-NetConnectionProfile -InterfaceIndex <interface_number> -NetworkCategory Private
```

Note: The category might revert to Public automatically. Verify it before each use.

- Allow the computer to receive remote PowerShell commands:
```powershell
Enable-PSRemoting
```

- Add the target machine's IP address to the trusted hosts:
```powershell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "<target_ip>"
```

- Verify the script's signature to ensure its integrity:

```powershell
Get-AuthenticodeSignature "C:\path\to\hids.ps1"
```


## Usage
Now it's time to use the HIDS to monitor your files and ensure their integrity.

Running the Script:
Navigate to the folder containing the downloaded script in PowerShell, then execute:

```powershell
.\hids.ps1
```

Upon running the script, the application window will appear, presenting two options:

- Local Monitoring
- Remote Monitoring


### Local Monitoring:

![image](https://github.com/user-attachments/assets/11632ba0-e351-47c6-8af7-c4b59fe55b87)


For local monitoring, fill out the following:

- Folder Path to Monitor: Specify the directory to watch.
- Destination Email Address: Provide an email where notifications will be sent if any file/directory changes are detected.
  
You can then start the monitoring process, which will run in the background until you stop it.

## Remote Monitoring:

![image](https://github.com/user-attachments/assets/78d0755a-50b2-4a04-a256-54e0e3ad8024)


For remote monitoring, fill out the following:

- Destination Email Address: Provide an email for notifications when changes are detected.
- Target Machine's IP Address: Include the IP of the machine to monitor (ensure it is listed in TrustedHosts as explained earlier).
- Folder Path to Monitor: Specify the directory on the remote machine to watch.

Note: To test remote monitoring, you can use the address 127.0.0.1 (localhost). This will monitor your host machine but simulate a remote connection.

Once configured, you can start remote monitoring, which will run in the background until you stop it.
