# Protect Dell EMC Unity with Cohesity Generic NAS Pre & Post Script

## Overview

Cohesity custom pre & post script for DELL EMC Unity will allow you to configure snapshot based
backup. This Script gives the capability to run the custom scripts on the Protected NAS
before and/or after the Protection Group runs.

### Prerequisites

Below is the list of prerequisites which should meet before configuring the Protection Group:

1. Unity Unisphere CLI Installation on UNIX/Linux Host

  * Unisphere CLI installation is required on Unix/Linux Host which would be hosting the Pre/Post Script to run the uemcli commands to the Unity target

  * Download the rpm from (here)[https://download.emc.com/downloads/DL69827_Dell-EMC-Unity-Unisphere-UEM-CLI-(SuSE-Linux-64-bit).rpm] and WinSCP it to UNIX/Linux Host

  * Run `yum localinstall <file_name>.rpm`

  * Test `which uemcli`

  > Note: Script is Tested with UnisphereCLI-SUSE-Linux-64-x86-en_US-5.0.3.984728-1.x86_64.rpm

2. Run below commands on the Unix/Linux Host:

```
uemcli -d <Unity Management IP Address> -u <username> -default
uemcli -d <Unity Management IP Address> -u <username> -p <Password> -saveUser

#Example
uemcli -d 10.2.166.184 -u admin -default
uemcli -d 10.2.166.184 -u admin -p Password123 -saveUser
```
  * This will save Unity's Management IP address, username, and password on the localhost and would not expose these via script.


3. Configure RSA authentication on the UNIX/Linux Host to authenticate Cohesity

  * Login to Cohesity DataPlatform UI

  * Navigate to Protection Group’s (the one created for Unity’s data protection) Advanced Settings

  * Edit the Pre & Post Scripts

  * Click **Copy Key to Clipboard** to copy the “Cluster SSH Public Key.” 

    ![copy-key](./images/copy-key.png)

  * Login to UNIX/Linux host 
   
  * Open the authorized_keys file (typically located in the ~/.ssh directory) and paste the entire string to the end of the file

  * Ensure authorized_keys permissions are set to 755

  * If the Cohesity hostname is not reachable from Unix/Linux host, then replace the hostname with an IP address.

    ![authorized-keys](./images/ssh-authorized-key.png)

4. Registering a Source, register the Unity’s filesystem share path to backup.

  To register a source,

  * Navigate to Data Protection > Sources

  * Click “Register Source” (+)  and choose NAS

  * Select NAS Source as “Mount Point.”

  * Select Mode as NFS or SMB

  * In the Mount Path: Specify the NFS/SMB volume snapshot share path that needs to be backed up. 

  ```
  Share Path format: <Unity Management IP>:/Cohesity_Unity_Snap_<NFS/CIFS>Share

  For Example - 

  For NFS Mode:
  Share Path: 10.2.166.185:/Cohesity_Unity_Snap_NFSShare

  where, 
  	10.2.166.185 - Unity Data IP
    /Cohesity_Unity_Snap_NFSShare - Path of the NFS snapshot share, which will be created by the script

  For CIFS Mode:
  Share Path: 10.2.166.185\Cohesity_Unity_Snap_CIFSShare 
  
  where, 
    10.2.166.185 - Unity Data IP
    /Cohesity_Unity_Snap_CIFSShare - Path of the CIFS snapshot share, which will be created by the script
  ```


* Toggle on “Skip Mount Point validation during registration.”

  ![skip-mount-point.png](./images/skip-mount-point.png)


### Run script

SAMPLE STEPS TO RUN THE SCRIPT. MODIFY IT ACCORDINGLY

> Note: In order to run this script, you need to have the privilege.json file in the same folder as the script. 

* Run the script using

  ```
  ./CustomPriv.ps1
  ```

* The script will prompt you some questions regarding vCenter and other information. 

* Enter the correct values and the script will add the required permission on vCenter for Cohesity to be able to perform Backup and Recovery

### Have any question

Send me an email at <YOUR_EMAIL_ADDRESS>
