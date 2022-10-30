# Cancel a Granular physical backup object using API's

## Overview

Currently if there is a need to cancel a running backup at an object level, it can be only done for VMware objects. This feature was introduced in 6.6.0d as tech preview feature on UI. Object level cancellation though is not limited to VMware objects only. One might need to do it for other sources like Physical as well. The capability is not on UI however uses the same set of API’s that are used for VMware object run cancellation.

This script allows one to cancel a running physical object at granular level


### Prerequisites

The script is a shell script. Following are the prerequisites:

1. A linux client with "jq" installed
2. The linux client should be able to communicate with cohesity cluster over port 443

