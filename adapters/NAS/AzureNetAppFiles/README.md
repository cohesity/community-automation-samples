# Protect Azure NetApp Files with Cohesity Generic NAS Pre & Post Script

## Overview

Cohesity custom pre & post script for Azure NetApp Files, allows you to backup specific snapshots of Azure NetApp Files to Cohesity storage.

### Prerequisites

Below is the list of prerequisites which should meet before configuring the Protection Group:

1. Ensure that you have a Linux Control VM configured and have access to Azure NetApp Files volumes


2. Prepare SSH access and scripts on Linux VM:

``` bash
# Log in to the Linux VM and enter the command 
cd .ssh 

```
  * Copy the SSH key from Protection Group Pre & Post Scripts section and Paste the copied SSH Key in the authorized_keys file.
``` bash
cat >> authorized_keys
# Press Contrl+D to save the file

```
  * Create a new directory called scripts in the Linux VM and create new files in it
``` bash 
mkdir scripts

```
  * Download the scripts from the current folder

  ``` bash
  # Copy create_anf_snapshot.ps1 content and paste in the file create_anf_snapshot.ps1

cat > create_anf_snapshot.ps1

# Press Contrl+D to save the file

   # Copy delete_anf_snapshot.ps1 content and paste in the file delete_anf_snapshot.ps1

   cat > delete_anf_snapshot.ps1
   # Press Contrl+D to save the file
```

  * Change permissions on the created script files
  ``` bash
  chmod a+x *.ps1 
  ```


  * Configure the Pre & Postscript in the Protection Group
  * In the Pre & Post Scripts, enable the Pre-Script toggle button.
  * In the Script Path, enter the full path of the create_anf_snapshots.ps1 file
In the Script Params, enter the params in the below format and replace the values with your Azure and Azure NetApp Files values except for the SnapshotName.
```
-AppID '7f2c948e-ffb4-4d49-ac24-66e5bbe3d8e5' -TenantID '75818451-2edd-4f92-8f36-47882b1a59b5' -SecretString '***your secret key value***' -ResourceGroupName 'cohesitywestus-rg' -Region 'westus' -AccountName 'anf' -PoolName 'cp' -VolumeName 'anfvol01' -SnapshotName 'coh_snap1'

```
 * In Pre & Post Scripts, enable the Post-Script toggle button.
* In the Script Path, enter the full path of the delete_anf_snapshots.ps1 file
 * In the Script Params, enter the params in the below format and replace the values with your Azure and Azure NetApp Files values except for the SnapshotName.
 ```
-AppID '7f2c948e-ffb4-4d49-ac24-66e5bbe3d8e5' -TenantID '75818451-2edd-4f92-8f36-47882b1a59b5' -SecretString '***your secret key value***' -ResourceGroupName 'cohesitywestus-rg' -AccountName 'anf' -PoolName 'cp' -VolumeName 'anfvol01' -SnapshotName 'coh_snap1'

```

### Run script

* The script will now run whenever the protection group is run

### Have any question

Send me an email at saran.ravi@cohesity.com
