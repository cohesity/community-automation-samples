<!--
  Title: Cohesity PowerShell Module
  Description: This project provides a PowerShell Module for interacting with the Cohesity DataPlatform
  Author: Cohesity Inc
  -->

## Overview

This project is to host sample scripts or piece of automation that can be used by customers, SREs, SEs or anyone trying to automate certain workflow, written by any Cohesians. 

## Table of contents :scroll:

 - [Getting Started](#get-started)
 - [How can you contribute](#contribute)
 - [Suggestions and Feedback](#suggest)
 
 

## <a name="get-started"></a> Let's get started :hammer_and_pick:

### Pre-req

In order to contribute to this github repo, make sure you the following contents ready.

1. Automation script that you want to upload in the following format `workflow-scriptingLanguage.extension`. For example, `vmware-createVM-powerShell.ps1`.

2. A README with a small write up on what your script does and how to use it and sample output(if applicable). You can refer this [sample README](./SampleREADME.md).md to get started


## <a name="contribute"></a> Contribute :handshake:

1. Fork the `cohesity/community-automation-samples` repo.

2. Make your changes in a new git branch:

     ```shell
     git checkout -b my-fix-branch main
     ```
3. Add your script along with your README.md file in the correct folder. If there is no appropriate folder present, create one for your workflow, for example, NAS-Workflows.

4. Commit your changes using a descriptive commit message 

5. Push your branch to GitHub:

    ```shell
    git push origin my-fix-branch
    ```

6. In GitHub, send a pull request to `cohesity/community-automation-samples:main`.

## <a name="suggest"></a> Suggestions and Feedback :raised_hand:

We would love to hear from you. Please send your suggestions and feedback to: [cohesity-api-sdks@cohesity.com](mailto:cohesity-api-sdks@cohesity.com)

## License :shield:

Apache 2.0
