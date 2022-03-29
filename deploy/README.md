# Prerequisites

The deployment script uses following tools, please follow the links provided to install the suggested tools on your computer using which you would execute the script.

- [bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install)
- [az cli](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [docker cli](https://docs.docker.com/get-docker/)
- [jq](https://stedolan.github.io/jq/download/)

- The scripts are executed on bash shell, so if using a computer with windows based operating system, install a [WSL](https://docs.microsoft.com/windows/wsl/about) environment to execute the script.

- This solution assumes no interference from Policies deployed to your tenant preventing resources from being deployed. 

- The bicep templates included in this solution are not idempotent. Use the template for greenfield deployment only.

- Get the repository to find the scripts. Clone the repository using following command.
```bash
git clone git@github.com:Azure/Azure-Orbital-Analytics-Samples.git
```

One would need [git](https://github.com/git-guides/install-git) cli tool to download the repository.

Alternatively, you can use Azure Cloud Bash to deploy this sample solution to your Azure subscription.

# How does scripts work?

The shell script runs an `az cli` command to invoke `bicep` tool.

This command recieves the bicep template as input, and converts the bicep templates into an intermediate ARM template output which is then submitted to Azure APIs to create the Azure resources.


# Executing the script

Before executing the script one would need to login to azure using `az` cli and set the correct subscription in which they want to provision the resources.

```bash
az login
az account set -s <subscription_id>
```

Script has been written to be executed with minimalistic input, it requires following input
- `environmentCode` which serves as the prefix for infrastructure services names.
- `location` which suggests which azure region infrastructure is deployed in.

To install infrastructure execute install.sh script as follows

```bash
./deploy/install.sh <environmentCode> <location> <envTag>

```

Default values for the parameters are provided in the script itself.

Arguments | Required | Sample value
----------|-----------|-------
environmentCode | yes | aoi
location | yes | westus
envTag | no | synapse\-\<environmentCode\>


For eg.

```bash
./deploy/install.sh aoi-demo westus demo


```

# Using bicep template

Users can also use bicep template directly instead of using the script `install.sh`

To deploy the resources using the bicep template use the command as follows:

```bash
az deployment sub create -l <region_name> -n <deployment_name> -f main.bicep -p location=<region_name> environmentCode=<environment_name_prefix> environment=<tag_value>
```

For eg.
```bash
az deployment sub create -l <region> -n aoi -f main.bicep -p location=<region> environmentCode=aoi-demo environment=devSynapse
```

# Verifying infrastructure resources

Once setup has been executed one can check for following resource-groups and resources to confirm the successful execution.

Following is the list of resource-groups and resources that should be created if we executed the command `./deploy/install.sh aoi-demo`

- `aoi-demo-data-rg`

    This resource group houses data resources.

    - Storage account named `rawdata<6-character-random-string>` to store raw input data for pipelines.
    - Keyvault named `aoi-demo-data-kv` to store credentials as secrets.

- `aoi-demo-monitor-rg`

    This resource group houses monitoring resources.

    - App Insights instance named `aoi-demo-monitor-appinsights` for monitoring.
    - Log Analytics workspace named `aoi-demo-monitor-workspace` to store monitoring data.

- `aoi-demo-network-rg`

    This resource group houses networking resources.

    - Virtual network named `aoi-demo-vnet` which has 3 subnets.

        - `pipeline-subnet`
        - `data-subnet`
        - `orchestration-subnet`
    - It also has a list security groups to restrict access on the network.

- `aoi-demo-orc-rg`

    This resource group houses pipeline orchestration resources.

    - Storage account named `aoi-demoorcbatchact` for batch account.
    - Batch Account named `batchacc<6-character-random-string>`.

        Also, go to the Batch Account and switch to the pools blade. Look for one or more pools created by the bicep template. Make sure the resizing of the pool is completed without any errors. 
        
        - Error while resizing the pools are indicated by red exclamation icon next to the pool. Most common issues causing failure are related to the VM Quota limitations.
        - Resizing may take a few minutes. Pools that are resizing are indicated by `0 -> 1` numbers under dedicated nodes column. Pools that have completed resizing should show the number of dedicated nodes. 

        Wait for all pools to complete resizing before moving to the next steps.

    - Keyvault named `aoi-demo-orc-kv`.
    - User managed identity `aoi-demo8-orc-umi` for access and authentication.
    - Azure Container registry instance named `aoi-demoorcacr` to store container images.

- `aoi-demo-pipeline-rg`

    This resource group houses Synapse pipeline resources.

    - Keyvault instance named `aoi-demo-pipeline-kv` to hold secrets for pipeline.
    - Storage account named `synhns<6-character-random-string>` for Synapse workspace.
    - Synapse workspace named `aoi-demo-pipeline-syn-ws` to hold pipeline resources.
    - Synapse spark pool `pool<6-character-random-string>` to run analytics.


# Load the Custom Vision Model to your Container Registry

Custom Vision Model is containerized image that can be downloaded as tar.gz file and loaded to your Container Registry. To load the image to your Container Registry, follow the steps below:

```bash
curl https://stllrairbusdatav2.blob.core.windows.net/public/images/custom_vision_offline.tar.gz --output custom_vision_offline.tar.gz

docker load < custom_vision_offline.tar.gz

docker tag custom_vision_offline <container-registry-name>.azurecr.io/custom_vision_offline:latest

az acr login --name <container-registry-name>

docker push <container-registry-name>.azurecr.io/custom_vision_offline:latest

```

Once the image is loaded to your Container Registry, update the [specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) with the Container Registry details.

[Specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) and [Configuration file](../src/aimodels/custom_vision_object_detection_offline/config/config.json) required to run the Custom Vision Model.

- Specification document - This solution has a framework defined to standardized way of running AI Models as containerized solutions. A Specification document works as a contract definition document to run an AI Model.

- Configuration file - Each AI Model may require one or more parameters to run the model. This parameters driven by the end users are passed to the AI Model in the form of a configuration file. The schema of these configuration file is specific to the AI Model and hence we provide a template for the end user to plug-in their values.

# Configuring the Resources

Next step is to configure your resources and set them up with the required dependencies like Python files, Library requirements and so on, before importing the Synapse pipeline. Run the `configure.sh` script below to perform the configuration:

```bash
./deploy/configure.sh <environmentCode>
```

# Packaging the Synapse Pipeline

To package the Synapse pipeline, run the `package.sh` script by following the syntax below:

```bash
./deploy/package.sh <environmentCode>
```

Once the above step completes, a zip file is generated. Upload the generated zip files to your Synapse Studio by following the steps below:

1. Open the Synapse Studio
2. Switch to Integrate tab on the left
3. At the top of the left pane, click on the "+" dropdown and select "Import resources from support files"
4. When prompted to select a file, pick the zip file generated in the previous step
5. Pipelines and its dependencies are imported to the Synapse Studio. Validate the components being imported for any errors
6. Click "Publish all" and wait for the imported components to be published

## Running the pipeline

To run the pipeline, open the Synapse Studio for the Synapse workspace that you have created and follow the below listed steps.

- Open the `E2E Custom Vision Model Flow` and click on debug button

- When presented with the parameters, fill out the values. Below table provide the details on that each parameter represents.

| parameter | description |
|--|--|
| Prefix | A random string for each run of the pipeline. Use a random string betwee 4 to 6 characters long. Example - hj4t3d |
| StorageAccountName | Name of the Storage Account that hosts the Raw data |
| StorageAccountKey | Access Key of the Storage Account that hosts the Raw data |
| BatchAccountName | Name of the Batch Account to run the AI Model |
| BatchJobName | Job name within the Batch Account that runs the AI Model |
| BatchLocation | Location of the Batch Account that runs the AI Model |

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
./deploy/cleanup.sh aoi-demo
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
