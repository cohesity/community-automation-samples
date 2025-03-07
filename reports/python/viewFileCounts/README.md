# List View File and Folder Counts ising Python

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This script collects the file and folder count per view. Output is written to a CSV file.

## Download the script

Run these commands to download the scripts into your current directory

```bash
curl -O https://raw.githubusercontent.com/cohesity/community-automation-samples/main/reports/python/viewFileCounts/viewFileCounts.py
curl -O https://raw.githubusercontent.com/cohesity/community-automation-samples/main/python/pyhesity.py
chmod +x viewFileCounts.py
```

## Components

* viewFileCounts.py: the main powershell script
* pyhesity.py: the Cohesity REST API helper module

Place both files in a folder together and run the main script like so:

```bash
#example
./viewFileCounts.py -v mycluster \
                    -u myusername \
                    -d mydomain.net
#end example
```

## Parameters

* -v, --vip: Cohesity cluster to connect to
* -u, --username: Cohesity username
* -d, --domain: (optional) Active Directory domain (defaults to 'local')
