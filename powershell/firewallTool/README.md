# Update Firewall Rules using PowerShell

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This script adds/removes CIDR addresses from the firewall allow list of the specified service profile.

## Download the script

Run these commands from PowerShell to download the script(s) into your current directory

```powershell
# Download Commands
$scriptName = 'firewallTool'
$repoURL = 'https://raw.githubusercontent.com/cohesity/community-automation-samples/main/powershell'
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/$scriptName/$scriptName.ps1").content | Out-File "$scriptName.ps1"; (Get-Content "$scriptName.ps1") | Set-Content "$scriptName.ps1"
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/cohesity-api/cohesity-api.ps1").content | Out-File cohesity-api.ps1; (Get-Content cohesity-api.ps1) | Set-Content cohesity-api.ps1
# End Download Commands
```

## Components

* [firewallTool.ps1](https://raw.githubusercontent.com/cohesity/community-automation-samples/main/powershell/firewallTool/firewallTool.ps1): the main powershell script
* [cohesity-api.ps1](https://raw.githubusercontent.com/cohesity/community-automation-samples/main/powershell/cohesity-api/cohesity-api.ps1): the Cohesity REST API helper module

Place both files in a folder together, then we can run the script.

To display the allow list for a profile (e.g. SNMP):

```powershell
./firewallTool.ps1 -vip mycluster `
                   -username myusername `
                   -domain mydomain.net `
                   -profileName SNMP
```

To add an entry to the allow list for the SNMP profile:

```powershell
./firewallTool.ps1 -vip mycluster `
                   -username myusername `
                   -domain mydomain.net `
                   -profileName SNMP `
                   -addEntry `
                   -ip 172.31.0.0/16
```

To remove an entry from the allow list for the SNMP profile:

```powershell
./firewallTool.ps1 -vip mycluster `
                   -username myusername `
                   -domain mydomain.net `
                   -profileName SNMP `
                   -removeEntry `
                   -ip 172.31.0.0/16
```

## Authentication Parameters

* -vip: (optional) name or IP of Cohesity cluster (defaults to helios.cohesity.com)
* -username: (optional) name of user to connect to Cohesity (defaults to helios)
* -domain: (optional) your AD domain (defaults to local)
* -useApiKey: (optional) use API key for authentication
* -password: (optional) will use cached password or will be prompted
* -mcm: (optional) connect through MCM
* -mfaCode: (optional) TOTP MFA code
* -emailMfaCode: (optional) send MFA code via email
* -clusterName: (optional) cluster to connect to when connecting through Helios or MCM

## Firewall Parameters

* -ip: (optional) one or more CIDRs to add/remove (comma separated)
* -ipList: (optional) text file of CIDRs to add/remove (one per line)
* -addEntry: (optional) add specified CIDRs to allow list
* -removeEntry: (optional) remove specified CIDRs from allow list
* -profileName: (optional) name of service profile to modify. Valid profile names are 'Management', 'SNMP', 'S3', 'Data Protection', 'Replication', 'Reporting database', 'SSH', 'SMB', 'NFS'
