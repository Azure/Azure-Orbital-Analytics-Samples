# Overview of Infrastructure deployment and configuration

This sample uses bicep templates to deploy the infrastructure resources. By default, the sample uses the following Azure services:
- Azure Batch Account
- Azure Synapse Analytics
- Azure Key Vault
- Azure Storage Account
- Azure Networking
- Azure Log Analytics

# Prerequisites

The prerequisites depend to an extent on whether you will be deploying this sample on Linux or on Windows. Follow the guidance in the appropriate section below for your environment. 

## Owner Role
Regardless of whether you are using Linux or Windows, before beginning to deploy this sample, make sure you have **Owner** role assigned on the subscription that you want to use for the deployment. This role is required to grant IAM roles to managed identities in bicep templates.

## Linux Prerequisites
The deployment script uses tools listed below. Before running the script, make sure you have them installed. You can use the links provided to install the suggested tools.

- [git](https://github.com/git-guides/install-git)
- [az cli](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [jq](https://stedolan.github.io/jq/download/)
- Install bicep on az cli using command  `az bicep install` and ensure the bicep version is >=0.8.9.

## Windows Prerequisites
The easiest way to run the commands needed to set up the required infrastructure on Windows is to use Cloud Shell, because it includes all necessary components, such as git, az cli, and jq. To open a Cloud Shell terminal, do the following:

1. In the subscription that you want to deploy the sample to, click the **Cloud Shell** icon in the top ribbon, just to the right of the Search bar.
2. This opens a Cloud Shell terminal on the screen. In the upper left side of that terminal, make sure **Bash** is selected, not PowerShell.

With the Cloud Shell Bash terminal open, proceed to running the commands under Infrastructure Deployment below.

# Infrastructure Deployment

## Get Repository and Scripts
Get the repository to find the scripts. Clone the repository using the following command:

```bash
git clone git@github.com:Azure/Azure-Orbital-Analytics-Samples.git
```

## Set Subscription
Before executing the script, please login to azure using `az` cli and set the subscription in which you want to provision the resources.

```bash
az login
az account set -s <subscription_id>
```

## Run the Setup Script
Run the following command to install, configure and generate the custom vision model package:

```bash
./deploy/scripts/setup.sh <environmentCode> <location>
```

Where:
- **environmentCode** is a string you provide that is used as a prefix for Azure resource groups and resource names. It must consist of only alphanumeric characters (no special characters) and must be between 3 and 8 characters in length.
- **location** is a valid Azure region.

For example, you may use a command such as the following:

```bash
./deploy/scripts/setup.sh aoi eastus
```

[setup.sh](./scripts/setup.sh) performs the following three tasks:
1. Installs the infrastructure using the [install.sh](./scripts/install.sh) script.
2. Configures the infrastructure for setting up the dependencies using the [configure.sh](./scripts/configure.sh) script.
3. Packages the pipeline code to a zip file using the [package.sh](./scripts/package.sh) script.

After the script has run successfully, use the following steps to check to make sure the batch account pool has been created successfully:

1. Find the batch account named as `batchact<10-character-random-string>` under the resource group `<environment-code>-orc-rg`.
2. In the batch account, switch to the **Pools** blade. Look for a pool whose name begins with the environment code you had used. Make sure the resizing of the pool is completed without any errors. Resizing may take a few minutes. Pools that are resizing are indicated by `0 -> 1` numbers under dedicated nodes column. Pools that have completed resizing should show the number of dedicated nodes.

Errors encountered while resizing the pools are indicated by red exclamation icon next to the pool. Most common issues causing failure are related to the VM Quota limitations. If you run into this issue, try increasing the quota. You may need to contact Azure support to increase the quota.

# Run the Synapse Pipeline

Use the following steps to find the Synapse Pipeline in the Synapse Gallery:

1. Find your Synapse workspace named as `synws<10-character-random-string>` in the resource group `<environment-code>-pipeline-rg`.
2. Click **Workspace web URL** to open the Synapse Workspace portal home page.
3. Click **Knowledge center**.
4. Click **Browse gallery**.
5. Click **Pipelines** in the top menu.
6. In the search box type **space** to find the pipeline named **Spaceborne Data Analysis Master Pipeline**.
7. Click the pipeline name to select it, and click the **Continue** button at the bottom of the page.

Follow the steps in [instructions.md](./gallery/instructions.md) to configure and run the pipeline.

## Cleanup Script

When you are finished with this sample deployment, you can use a cleanup script to clean up the resource groups and remove the resources provisioned using your chosen **environmentCode**.
As mentioned above, the environmentCode is used as prefix to generate resource group and resource names, so the cleanup script deletes the resource groups whose names begin with that prefix.

Run the cleanup script as follows:

```bash
./deploy/scripts/cleanup.sh <environmentCode>
```

For example:
```bash
./deploy/scripts/cleanup.sh aoi
```

If you do not want to delete a specific resource group and the resources contained with in it, use the NO_DELETE_*_RESOURCE_GROUP environment variable, by setting it to **true** as shown:

```bash
NO_DELETE_DATA_RESOURCE_GROUP=true
NO_DELETE_MONITORING_RESOURCE_GROUP=true
NO_DELETE_NETWORKING_RESOURCE_GROUP=true
NO_DELETE_ORCHESTRATION_RESOURCE_GROUP=true
NO_DELETE_PIPELINE_RESOURCE_GROUP=true
./deploy/scripts/cleanup.sh <environmentCode>
```