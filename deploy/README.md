# Prerequisites

The deployment script uses following tools, please follow the links provided to install the suggested tools on your computer using which you would execute the script.

- [bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install)
- [az cli](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [docker cli](https://docs.docker.com/get-docker/)
- [jq](https://stedolan.github.io/jq/download/)

- The scripts are executed on bash shell, so if using a computer with windows based operating system, install a [WSL](https://docs.microsoft.com/windows/wsl/about) environment to execute the script.

- The user performing the deployment of the bicep template and the associated scripts should have `Owner` role assigned at the subscription to which the resources are being deployed.
- The bicep templates have been written to adhere to the syntax and rules for bicep version >= 0.8.9. Please check your bicep version using `az bicep version` or `bicep --version` if you run into bicep related errors.
- This solution assumes no interference from Policies deployed to your tenant preventing resources from being deployed. 

- Get the repository to find the scripts. Clone the repository using following command.
```bash
git clone git@github.com:Azure/Azure-Orbital-Analytics-Samples.git
```

One would need [git](https://github.com/git-guides/install-git) cli tool to download the repository.

Alternatively, you can use Azure Cloud Bash to deploy this sample solution to your Azure subscription.

# How does scripts work?

The shell script runs an `az cli` command to invoke `bicep` tool.

This command recieves the bicep template as input, and converts the bicep templates into an intermediate ARM template output which is then submitted to Azure APIs to create the Azure resources.

# Overview of deployment and configuration

The deployment involves the following steps outlined below:

No | Step | Duration (approx.) | Required / Optional
---|------|----------|---------------------
1 | Preparing to execute the script | 1 minute | required
2 | Deployment of Infrastructure using bicep template | 10 minutes | required
3 | Configuring the Resources | 5 minutes | required
4 | Packaging the Synapse pipline (optional) | 2 minutes | optional
5 | Importing from Git Repository (optional) | 5 minutes | optional
6 | Verifying infrastructure resources | 5 minutes | required
7 | Load the Custom Vision Model to your Container Registry (optional) | 10 minutes | optional

Steps 2 through 4 can instead be deployed using a single script below:

```bash
./deploy/setup.sh <environmentCode> <location> <pipelineName> <envTag>

```
or

```bash
./deploy/setup.sh <environmentCode> <location> <pipelineName> <envTag> <preprovisionedBatchAccountName> <deployPgsql>

```

If you like to package other pipelines or re-package an updated/modified pipeline, follow the instructions under `Packaging the Synapse pipeline` section. The script mentioned in that section can be rerun multiple times.

Arguments | Required | Type | Sample value
----------|-----------|-------|-------
environmentCode | yes | string | aoi
location | yes | string | westus
pipelineName | no | string | Allowed value: custom-vision-model
envTag | no | string | synapse\-\<environmentCode\>
preprovisionedBatchAccountName | no | string | aoibatchaccount
deployPgsql | no | boolean | false

**Note**: If you do not pass the optional pipelineName parameter value, no zip file will be generated. You may however run the `package.sh` script to generate a zip file after running the `setup.sh` script to generate the zip file.

## Preparing to execute the script

Before executing the script one would need to login to azure using `az` cli and set the correct subscription in which they want to provision the resources.

```bash
az login
az account set -s <subscription_id>
```

Script has been written to be executed with minimalistic input, it requires following input
- `environmentCode` which serves as the prefix for infrastructure services names. Allows only alpha numeric(no special characters) and must be between 3 and 8 characters.
- `location` which suggests which azure region infrastructure is deployed in.
- `environmentTag` / `envTag` serves as a simple label / tag to all resources being deployed as part of the bicep template to your subscription.
- `pipelineName` refers to the name of the pipeline that is to be package for deployment to your Synapse Workspace. Allowed value is custom-vision-model.

## Deployment of Infrastructure using bicep template

If you have deployed the solution using `setup.sh` script, you should skip this step. However, if you have not run the `setup.sh` script, the steps outlined in this section are required.

To install infrastructure execute install.sh script as follows

```bash
./deploy/install.sh <environmentCode> <location> <envTag>

```

or 

```bash
./deploy/install.sh <environmentCode> <location> <envTag> <deploymentName> <deployBatchAccount> <deployPgsql>

```

You will be prompted to enter in a password for postgres. If left empty, an auto generated password will be created and stored in the keyvault. The password requirements are listed below:
- Between 8 characters and 128 characters
- Must contain characters from three of the following categories – English uppercase letters, English lowercase letters, numbers (0-9), and non-alphanumeric characters (!, $, #, %, etc.). 
- Your password cannot contain all or part of the login name. Part of a login name is defined as three or more consecutive alphanumeric characters.

Default values for the parameters are provided in the script itself.

Arguments | Required | Type | Sample value
----------|-----------|-------|------------
environmentCode | yes | string | aoi
location | yes | string |westus
envTag | no | string | synapse\-\<environmentCode\>
deploymentName | no | string | aoi-deploy
deployBatchAccount | no | boolean | false
deployPgsql | no | boolean | false


For eg.

```bash
./deploy/install.sh aoi westus demo
```

or 

```bash
./deploy/install.sh aoi westus demo aoi-deploy false false
```

Users can also use bicep template directly instead of using the script `install.sh`

To deploy the resources using the bicep template use the command as follows:

```bash
az deployment sub create -l <region_name> -n <deployment_name> -f main.bicep -p location=<region_name> environmentCode=<environment_name_prefix> environment=<tag_value>
```

For eg.
```bash
az deployment sub create -l <region> -n aoi -f main.bicep -p location=<region> environmentCode=aoi environment=synapse-aoi
```


## Configuring the Resources

If you have deployed the solution using `setup.sh` script, you should skip this step. However, if you have not run the `setup.sh` script, the steps outlined in this section are required.

Next step is to configure your resources and set them up with the required dependencies like Python files, Library requirements and so on, before importing the Synapse pipeline. Run the `configure.sh` script below to perform the configuration:

```bash
./deploy/configure.sh <environmentCode>
```
or

```bash
./deploy/configure.sh <environmentCode> <batchAccountName> <batchAccountRG> <batchAccountKey> <batchAccountPoolName> <synapseWorkspaceRG> <synapseWorkspace> <synapsePool> <synapseStorageAccount>
```

Arguments | Required | Type | Sample value
----------|-----------|-------|-------------
environmentCode | yes | string | aoi
batchAccountName | no | string | aoibatchaccount
batchAccountRG | no | string | aoibatchaccountrg
batchAccountKey | no | string | 2kfdof824lre-03k...d8kj4899==
batchAccountPoolName | no | string | aoibatchaccountpool
synapseWorkspaceRG | no | string | aoisynapseworkspacerg
synapseWorkspace | no | string | aoisynapseworksapce
synapsePool | no | string | synapsepoolname
synapseStorageAccount | no | string | synrawdatastorage


## Packaging the Synapse Pipeline

You may repeat the steps outlined in this section multiple times to package the pipeline irrespective of whether you have already run the `package.sh` script or `setup.sh` script. 

To package the Synapse pipeline, run the `package.sh` script by following the syntax below:

```bash
./deploy/package.sh <environmentCode> <pipelineName>
```
or

```bash
./deploy/package.sh <environmentCode> <pipelineName> <batchAccountName> <batchAccountRG> <batchAccountStorageAccountName> <keyVaultName> <rawStorageAccountRG> <rawStorageAccountName> <synapseWorkspaceRG> <synapseWorkspace> <synapseStorageAccount> <synapsePool> <deployPgsql>
```

Arguments | Required | Type | Sample value
----------|-----------|-------|---------------
environmentCode | yes | string | aoi
pipelineName | no | string | Allowed Value: custom-vision-model
batchAccountName | no | string | aoibatchaccount
batchAccountRG | no | string | aoibatchaccountrg
batchAccountStorageAccountName | no | string | aoibatchstorageaccount
keyVaultName | no | string | aoiKeyVault
rawStorageAccountRG | no | string | aoi-data-rg
rawStorageAccountName | no | string | rawdata34keh240
synapseWorkspaceRG | no | string | aoisynapseworkspacerg
synapseWorkspace | no | string | aoisynapseworksapce
synapseStorageAccount | no | string | synrawdatastorage
synapsePool | no | string | synapsepoolname
deployPgsql | no | boolean | false

## Importing from Git Repository

Unzip the contents of the ZIP file generate by running the `package.sh` or `setup.sh` with pipelineName and use the contents to load them to your repository.

A few things to consider prior to integration of Git / GitHub Repository with Synapse Studio:

* Do not bring the files from [workflow folder](../src/workflow) directly into your repository that you will use to integrate with Synapse Studio. You will need to run `package.sh` or `setup.sh` to replace placeholders in one or more files before checking-in the files to your repository to be used with the Synapse Studio. 
* You can either create a new repository or use a forked version of the [Azure Orbital Analytics Sample](https://github.com/Azure/Azure-Orbital-Analytics-Samples) repository. If you use a new repository, use the Unzipped contents of the ZIP file to load into your new repository. If you use forked version of the [Azure Orbital Analytics Sample](https://github.com/Azure/Azure-Orbital-Analytics-Samples) repository, overwrite the contents of [Custom vision model workflow folder](../src/workflow/custom-vision-model) with the Unzipped contents.


To import pipeline into the Synape Studio is through Source Control repository like GitHub or Azure DevOps repository, refer to the document on [Source Control](https://docs.microsoft.com/azure/synapse-analytics/cicd/source-control) to learn about Git Integration for Azure Synapse Analytics and how to setup.

**Note**: Once the Synapse Studio is linked to your repository, make sure you publish all the components. Failure to publish the components imported by linked Synapse Studio to Github / ADO repository, will result in errors when running the pipeline.

## Verifying infrastructure resources

Once setup has been executed one can check for following resource-groups and resources to confirm the successful execution.

Following is the list of resource-groups and resources that should be created if we executed the command `./deploy/install.sh aoi <region>`

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


## Load the Custom Vision Model to your Container Registry

There are three ways to load an AI Model with this pipeline. Below are the three options. 

Use one of the three options listed below. For option b and option c, either use `registry` property to pass credentials (requires update to the pipeline) or have your Batch Account pool configured with the ACR credentials when setting up the Batch Account pool.

a. Use the publicly hosted Custom Vision Model as GitHub Packages. 

No additional steps are required for this approach. Custom Vision Model is containerized image that can be pulled from `docker pull ghcr.io/azure/azure-orbital-analytics-samples/custom_vision_offline:latest`. The [Specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) in this repository already points to the publicly hosted GitHub Registry.

b. Download the publicly hosted Custom Vision Model and host it on your Container Registry.

Run the shell cmds below to pull and push the image to your Container Registry.


```bash

docker pull ghcr.io/azure/azure-orbital-analytics-samples/custom_vision_offline:latest

docker tag ghcr.io/azure/azure-orbital-analytics-samples/custom_vision_offline:latest <container-registry-name>.azurecr.io/custom_vision_offline:latest

az acr login --name <container-registry-name>

docker push <container-registry-name>.azurecr.io/custom_vision_offline:latest

```

Update the `algImageName` value in [Specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) to point to the new image location.

c. BYOM (Bring-your-own-Model) and host it on your Container Registry.

If you have the image locally, run the shell cmds below to push the image to your Container Registry.

```bash

docker tag custom_vision_offline:latest <container-registry-name>.azurecr.io/custom_vision_offline:latest

az acr login --name <container-registry-name>

docker push <container-registry-name>.azurecr.io/custom_vision_offline:latest

```
Update the `algImageName` value in [Specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) to point to the new image location.

Note: When using a private Container Registry, update `containerSettings` property in your [Custom Vision Object Detection](/src/workflow/pipeline/Custom%20Vision%20Object%20Detection.json) pipeline and add the following sub-property in order to authenticate to Container Registry :
```json
"registry": {
        "registryServer": "",
        "username": "",
        "password": ""
    }
```

The above change will need to be made to the `Custom Vision Model Transform` pipeline. Look for activity named `Custom Vision` of type Web activity and update the body property (under Settings tab) for that activity.

[Specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) and [Configuration file](../src/aimodels/custom_vision_object_detection_offline/config/config.json) required to run the Custom Vision Model.

- Specification document - This solution has a framework defined to standardized way of running AI Models as containerized solutions. A Specification document works as a contract definition document to run an AI Model.

- Configuration file - Each AI Model may require one or more parameters to run the model. This parameters driven by the end users are passed to the AI Model in the form of a configuration file. The schema of these configuration file is specific to the AI Model and hence we provide a template for the end user to plug-in their values.

# Running the pipeline (Custom Vision Model)

Before starting the pipeline, prepare the storage account in <environmentCode>-data-rg resource group by creating a container for the pipeline run.

- Create a new container for every pipeline run. Make sure the container name does not exceed 8 characters.

- Under the newly created container, add two folders. One folder named `config` with the following configuration files:

    - [Specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) configuration file that is provided by the AI Model partner.
    - [Config file](../src/aimodels/custom_vision_object_detection_offline/config/config.json) specific to the AI Model that contains parameters to be passed to the AI Model.
    coordinates.

    Another folder named `raw` with sample Geotiff to be processed by the pipeline. You can use this [Geotiff file](https://aoigeospatial.blob.core.windows.net/public/samples/sample_4326.tif) hosted as a sample or any Geotiff with CRS of EPSG 4326.

    When using this sample file, update your `AOI` parameter when kicking off the workflow with bbox value of `-117.063550 32.749467 -116.999386 32.812946`.

To run the pipeline, open the Synapse Studio for the Synapse workspace that you have created and follow the below listed steps.

- Open the `E2E Custom Vision Model Flow` and click on debug button

- When presented with the parameters, fill out the values. Below table provide the details on that each parameter represents if batch-account (by default) is provisioned in infrastructure setup.

| parameter | description |
|--|--|
| Prefix | This is the Storage container name created in [Running the pipeline section](#running-the-pipeline) that hosts the Raw data|
| StorageAccountName | Name of the Storage Account in <environmentCode>-data-rg resource group that hosts the Raw data |
| AOI | Area of Interest over which the AI Model is run |
| BatchAccountName | Name of the Batch Account in <environmentCode>-orc-rg resource group to run the AI Model |
| BatchJobName | Job name within the Batch Account in <environmentCode>-orc-rg resource group that runs the AI Model |
| BatchLocation | Location of the Batch Account in <environmentCode>-orc-rg resource group that runs the AI Model |

- In case AKS (Azure Kubernetes Service) is provisioned, parameters and their descriptions are:

| parameter | description |
|--|--|
| Prefix | This is the Storage container name created in [Running the pipeline section](#running-the-pipeline) that hosts the Raw data|
| StorageAccountName | Name of the Storage Account in <environmentCode>-data-rg resource group that hosts the Raw data |
| AOI | Area of Interest over which the AI Model is run |
| AksManagementRestApiURL | AKS Management Rest API Endpoint URL where Azure Synapse makes request calls to send kubectl commands to. Refer to [doc](https://docs.microsoft.com/en-us/rest/api/aks/managed-clusters/run-command). |
| PersistentVolumeClaim | Persistent Volume Claim Name used for the AI-Model execution Kubernetes pod. This is preconfigured during setup and configuration, and can be found from Azure portal (provisioned AKS-> 'Storage'-> 'Persistent volume claims'). |

- Once the parameters are entered, click ok to submit and kick off the pipeline.

- Wait for the pipeline to complete.

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

# Using different infrastructure to host AI-Model execution

We have introduced the work to cater to the need of customers to use different infrastructure types to host the execution of AI-Models:

Previously, we had the AI-Model executing on Azure Batch Account, now we are extending this to use AKS.

To help users we have introduced a new variable `AI_MODEL_INFRA_TYPE` in [setup.sh](./setup.sh) to suggest which infrastructure type they would want to use.

`AI_MODEL_INFRA_TYPE` currently supports 2 values, with default being `batch-account`: 
- `batch-account` 
- `aks`

Those users requiring to execute AI-Model against `batch-account` will not need any changes to their commands, however, those who want to execute against `aks`, can simply execute by setting the environment variable `AI_MODEL_INFRA_TYPE`.

```bash
AI_MODEL_INFRA_TYPE=aks ./deploy/setup.sh <environmentCode> <location> <pipelineName> <envTag>
```

# Attributions And Disclaimers

- [Geotiff file](https://aoigeospatial.blob.core.windows.net/public/samples/sample_4326.tif) provided as sample are attributed to NAIP Imagery available via [Planetary Computer](https://planetarycomputer.microsoft.com) They are covered under [USDA](https://ngda-imagery-geoplatform.hub.arcgis.com)