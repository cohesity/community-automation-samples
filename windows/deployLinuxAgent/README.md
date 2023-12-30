# Deploy Cohesity Agent for Linux (for Windows)

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This is a compiled binary that sets Cohesity agent gflags on linux hosts, via SSH.

## Download The Binary

<https://github.com/bseltz-cohesity/scripts/raw/master/windows/deployLinuxAgent/deployLinuxAgent.exe>

Run the tool like so:

```bash
#example
deployLinuxAgent.exe -s myhost1 -u myusername -f el-cohesity-agent-6.6.0d_u6-1.x86_64.rpm
#end example
```

## Parameters

* -s, --server: host to connect to (via SSH)
* -u, --username: username for SSH connection
* -pwd, --sourcepassword: (optional) will be prompted if omitted
* -f, --filepath: path to installer file