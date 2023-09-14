# Certificate Improvements using Python

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

Contributor: Priyadharsini

The script helps initialise certificate handling for clusters using multi-cluster registration or protecting HyperV data

## Components

* cert.py.py: the main python script
* pyhesity.py: the Cohesity python helper module

You can download the scripts using the following commands:

```bash
# download commands
curl -O https://raw.githubusercontent.com/cohesity/community-automation-samples/main/python/cert/cert.py
curl -O https://raw.githubusercontent.com/cohesity/community-automation-samples/main/python/pyhesity/pyhesity.py
chmod +x cert.py
# end download commands
```

Place both files in a folder together and run the main script like so:

```bash
# example
./cert.py --cluster cluster.json
# end example
```

```json
cluster.json file sample
{
    "primary": 
        {
            "ip":"10.2.20.17", 
            "username":"admin",
            "mfaCode":"1234"
        },
    "targets": 
    [
        {
            "ip":"10.2.20.1", 
            "username":"admin", 
            "password":"1234"
        }
    ]
}
```

Designate any cluster in your environment as primary cluster from which keys would be copied to all the other clusters. This is  to obtain the set of keys to keep a uniform trust chain across all clusters

If password is not provided with file, you will be prompted on terminal
If MFA is enabled, please provide MFACode for Totp.
NOTE: scripted MFA via email is disabled

## The Python Helper Module - pyhesity.py

The helper module provides functions to simplify operations such as authentication, api calls, storing encrypted passwords, and converting date formats. The module requires the requests python module.

## The Main Python Script - cert.py

This script helps with bootstrapping each target cluster with primary cluster's Cohesity CA Keys

### Installing the Prerequisites

```bash
sudo yum install python-requests
```

or

```bash
sudo easy_install requests
```

If you enter the wrong password, you can re-enter the password like so:

```python
> from pyhesity import *
> apiauth(updatepw=True)
Enter your password: *********************
```
