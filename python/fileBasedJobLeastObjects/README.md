# Find File-based Protection Group with the Least Objects using Python

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This python script finds the file-based physical protection group using the least number of protected objects.

## Download the script

You can download the scripts using the following commands:

```bash
# download commands
curl -O https://raw.githubusercontent.com/cohesity/community-automation-samples/main/python/fileBasedJobLeastObjects/fileBasedJobLeastObjects.py
curl -O https://raw.githubusercontent.com/cohesity/community-automation-samples/main/python/pyhesity.py
chmod +x fileBasedJobLeastObjects.py
# end download commands
```

## Components

* [fileBasedJobLeastObjects.py](https://raw.githubusercontent.com/cohesity/community-automation-samples/main/python/fileBasedJobLeastObjects/fileBasedJobLeastObjects.py): the main python script
* [pyhesity.py](https://raw.githubusercontent.com/cohesity/community-automation-samples/main/python/pyhesity/pyhesity.py): the Cohesity REST API helper module

Place both files in a folder together and run the main script like so:

```bash
./fileBasedJobLeastObjects.py -v mycluster \
                              -u myusername \
                              -d mydomain.net
```

To filter the protection groups based on a string match:

```bash
./fileBasedJobLeastObjects.py -v mycluster \
                              -u myusername \
                              -d mydomain.net \
                              -n 'some-string'
```

## Authentication Parameters

* -v, --vip: (optional) DNS or IP of the Cohesity cluster to connect to (default is helios.cohesity.com)
* -u, --username: (optional) username to authenticate to Cohesity cluster (default is helios)
* -d, --domain: (optional) domain of username (defaults to local)
* -i, --useApiKey: (optional) use API key for authentication
* -pwd, --password: (optional) password or API key
* -np, --noprompt: (optional) do not prompt for password
* -mcm, --mcm: (optional) connect through MCM
* -c, --clustername: (optional) helios/mcm cluster to connect to
* -m, --mfacode: (optional) MFA code for authentication
* -l, --showlist: (optional) return list of matching jobs

## Other Parameters

* -n, --namematch: (optional) substring to filter list of protection groups
