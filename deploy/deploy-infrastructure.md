# Prerequisites

The deployment script uses following tools, please follow the links provided to install the suggested tools on your computer using which you would execute the script.

- [git](https://github.com/git-guides/install-git) 
- [az cli](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [jq](https://stedolan.github.io/jq/download/)
- The scripts are executed on bash shell, so if using a computer with windows based operating system, install a [WSL](https://docs.microsoft.com/windows/wsl/about) environment to execute the script.
- Install bicep on az cli using command `az bicep install`.
- The bicep templates have been written to adhere to the syntax and rules for bicep version >= 0.8.9. Please check your bicep version using `az bicep version` if you run into bicep related errors.
- The user performing the deployment of the bicep template and the associated scripts should have `Owner` role assigned at the subscription to which the resources are being deployed.
- This solution assumes no interference from Policies deployed to your tenant preventing resources from being deployed. 
- Get the repository to find the scripts. Clone the repository using following command.

```bash
git clone git@github.com:Azure/Azure-Orbital-Analytics-Samples.git
```

Alternatively, one can use Azure Cloud Bash to deploy this sample solution in their Azure subscription.

## Preparing to execute the script

Before executing the script one would need to login to azure using `az` cli and set the correct subscription in which they want to provision the resources.

```bash
az login
az account set -s <subscription_id>
```

## Infrastructure Deployment

To install, configure and package the infrastructure for dependencies one can execute the script [setup.sh](./setup.sh)

Script has been written to be executed with minimalistic input, it requires following input
- `environmentCode` which serves as the prefix for infrastructure services names. Allows only alpha numeric(no special characters) and must be between 3 and 8 characters.
- `location` which suggests which azure region infrastructure is deployed in.

```bash
./deploy/setup.sh <environmentCode> <location>

```

Also, one can override other optional arguments for the scripts

```bash
./deploy/setup.sh <environmentCode> <location> <envTag> <pipelineName> <preprovisionedBatchAccountName> <aiModelInfraType> <deployPgsql>

```

- `environmentTag`/`envTag` serves as a simple label / tag to all resources being deployed as part of the bicep template to your subscription.
- `pipelineName` refers to the name of the pipeline that is to be package for deployment to your Synapse Workspace. Allowed value is custom-vision-model.
- `aiModelInfraType` refers to the infrastructure type used to deploy and execute ai-model. Allowed values are: "batch-account", "aks"
- `preprovisionedAiModelInfraName` refers to an existing infrastructure(batch-account/aks) name to be used ai-model deployment
- `deployPgsql` whether to deploy PostgreSQL instance to store the results. Allowed values are: true, false.

Following table summarizes the arguments for the script:

Arguments | Required | Type | Sample value
----------|-----------|-------|-------
environmentCode | yes | string | aoi
location | yes | string | westus
envTag | no | string | synapse\-\<environmentCode\>
pipelineName | no | string | Allowed value: custom-vision-model
aiModelInfraType | no | string | Allowed values: batch-account, aks (default value: batch-account) 
preprovisionedBatchAccountName | no | string | aoibatchaccount
deployPgsql | no | boolean | true


[setup.sh](./setup.sh) executes tasks in 3 steps
- installs the infrastructure using [install.sh](./install.sh) script.
- configures the infrastructure for setting up the dependecies using [configure.sh](./configure.sh) script.
- packages the pipeline code to imported into synapse for standalone executions using [package.sh](./package.sh) script.

## Verifying infrastructure resources

Once setup has been executed one can check for following resource-groups and resources to confirm the successful execution.

Following is the list of resource-groups and resources that should be created if we executed the command `./deploy/setup.sh aoi <region>`

- `aoi-data-rg`

    This resource group houses data resources.

    - Storage account named `rawdata<10-character-random-string>` to store raw input data for pipelines.
    - Keyvault named `kvd<10-character-random-string>` to store credentials as secrets.
    - Postgres Single Server DB named `pg<10-character-random-string>`

- `aoi-monitor-rg`

    This resource group houses monitoring resources.

    - App Insights instance named `aoi-monitor-appinsights` for monitoring.
    - Log Analytics workspace named `aoi-monitor-workspace` to store monitoring data.

- `aoi-network-rg`

    This resource group houses networking resources.

    - Virtual network named `aoi-vnet` which has 3 subnets.

        - `pipeline-subnet`
        - `data-subnet`
        - `orchestration-subnet`
    - It also has a list security groups to restrict access on the network.

- `aoi-orc-rg`

    This resource group houses pipeline orchestration resources.

    - Storage account named `batchacc<10-character-random-string>` for batch account.
    - Batch Account named `batchact<10-character-random-string>`.

        Also, go to the Batch Account and switch to the pools blade. Look for one or more pools created by the bicep template. Make sure the resizing of the pool is completed without any errors. 
        
        - Error while resizing the pools are indicated by red exclamation icon next to the pool. Most common issues causing failure are related to the VM Quota limitations.
        - Resizing may take a few minutes. Pools that are resizing are indicated by `0 -> 1` numbers under dedicated nodes column. Pools that have completed resizing should show the number of dedicated nodes. 

        Wait for all pools to complete resizing before moving to the next steps.

        Note: The Bicep template adds the Synapse workspace's Managed Identity to the Batch Account as `Contributor`. Alternatively, Custom Role Definitions can be used to assign the Synapse workspace's Managed Identity to the Batch Account with required Azure RBAC operations.

    - Keyvault named `kvo<10-character-random-string>`.
    - User managed identity `aoi-orc-umi` for access and authentication.
    - Azure Container registry instance named `acr<10-character-random-string>` to store container images.

- `aoi-pipeline-rg`

    This resource group houses Synapse pipeline resources.

    - Keyvault instance named `kvp<10-character-random-string>` to hold secrets for pipeline.
    - Storage account named `synhns<10-character-random-string>` for Synapse workspace.
    - Synapse workspace named `synws<10-character-random-string>` to hold pipeline resources.
    - Synapse spark pool `pool<10-character-random-string>` to run analytics.

# Cleanup Script

We have a cleanup script to cleanup the resource groups and thus the resources provisioned using the `environmentCode`.
As discussed above the `environmentCode` is used as prefix to generate resource group names, so the cleanup-script deletes the resource groups with generated names.

Execute the cleanup script as follows:

```bash
./deploy/cleanup.sh <environmentCode>
```

For eg.
```bash
./deploy/cleanup.sh aoi
```

If one wants not to delete any specific resource group and thus resource they can use NO_DELETE_*_RESOURCE_GROUP environment variable, by setting it to true

```bash
NO_DELETE_DATA_RESOURCE_GROUP=true
NO_DELETE_MONITORING_RESOURCE_GROUP=true
NO_DELETE_NETWORKING_RESOURCE_GROUP=true
NO_DELETE_ORCHESTRATION_RESOURCE_GROUP=true
NO_DELETE_PIPELINE_RESOURCE_GROUP=true
./deploy/cleanup.sh <environmentCode>
```