# Fixing linefeeds

The shell script [install.sh](./install.sh) might be edited on windows and might have carriage returns in the file.
This would create issues while executing the script on a non-windows environment.

To fix the problem use `sed` command as follows to fix the file.

- For ubuntu/linux based env
```
$ sed -i 's/\r$//' install.sh
```

- For mac based env
```
$ sed -i '' 's/\r$//' install.sh
```

# Prerequisites

The deployment script uses following tools, please follow the links provided to install the suggested tools on your computer using which you would execute the script.

- [bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- [az cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [jq](https://stedolan.github.io/jq/download/)

- The scripts are executed on bash shell, so if using a computer with windows based operating system, install a [WSL](https://docs.microsoft.com/en-us/windows/wsl/about) environment to execute the script.

- Get the repository to find the scripts. Clone the repository using following command.
```
$ git clone git@github.com:Azure/Azure-Orbital-Analytics-Samples.git
```

One would need [git](https://github.com/git-guides/install-git) cli tool to download the repository.

Alternatively, you can use Azure Cloud Bash to deploy this sample solution to your Azure subscription.

# How does scripts work?

The shell script runs an `az cli` command to invoke `bicep` tool.

This command recieves the bicep template as input, and converts the bicep templates into an intermediate ARM template output which is then submitted to Azure APIs to create the Azure resources.


# Executing the script

Before executing the script one would need to login to azure using `az` cli and set the correct subscription in which they want to provision the resources.

```
$ az login
$ az account set -s <subscription_id>
```

Script has been written to be executed with a minimimalistic input, it requires an input of `environment-code` which serves as the prefix for infrastructure services names.

To install infrastructure execute install.sh script as follows

```
./install.sh <environment-code>
```

For eg.

```
$ ./install.sh aoi-demo
```

# Using bicep template

Users can also use bicep template directly instead of using the script `install.sh`

To deploy the resources using the bicep template use the command as follows:

```
$ az deployment sub create -l <region_name> -n <deployment_name> -f main.bicep -p location=<region_name> environmentCode=<environment_name_prefix> environment=<tag_value>
```

For eg.
```
$ az deployment sub create -l <region> -n aoi -f main.bicep -p location=<region> environmentCode=aoi-demo environment=devSynapse
```


# Verifying infrastructure resources

Once setup has been executed one can check for following resource-groups and resources to confirm the successfull execution.

Following is the list of resource-groups and resources that should be created if we executed the command `./install.sh aoi-demo`

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
    - Keyvault named `aoi-demo-orc-kv`.
    - User managed identity `aoi-demo8-orc-umi` for access and authentication.
    - Azure Container registry instance named `aoi-demoorcacr` to store container images.

- `aoi-demo-pipeline-rg`

    This resource group houses Synapse pipeline resources.

    - Keyvault instance named `aoi-demo-pipeline-kv` to hold secrets for pipeline.
    - Storage account named `synhns<6-character-random-string>` for Synapse workspace.
    - Synapse workspace named `aoi-demo-pipeline-syn-ws` to hold pipeline resources.
    - Synapse spark pool `pool<6-character-random-string>` to run analytics.

# Packaging the Synapse Pipeline

To package the Synapse pipeline, run the `package.sh` script by following the syntax below:

```
$ ./package.sh <environment-code> <location-of-batch-account>
```

Once the above step completes, a zip file is generated. Upload the generated zip files to your Synapse Studio by following the steps below:

1. Open the Synapse Studio
2. Switch to Integrate tab on the left
3. At the top of the left pane, click on the "+" dropdown and select "Import resources from support files"
4. When prompted to select a file, pick the zip file generated in the previous step
5. Pipelines and its dependencies are imported to the Synapse Studio. Validate the components being imported for any errors
6. Click "Publish all" and wait for the imported components to be published


# Prepare Azure Synapse Analytics for Pipeline execution

Before running the pipeline, the following steps are required to configure the Synapse pool for Spark job execution.

1. Go to the Azure Synapse Analytics instance in the `<environment-code>-pipeline-rg` and switch to the Apache Spark pools blade
2. Pick the Spark pool that you will use to run the Spark jobs, then go to Packages on the left pane from the Spark pool page
3. In the next page, use the upload option under "Requirement files" to upload the `environment.yaml` file under deploy folder in this repo
4. Save and allow the Spark pool to apply the new requirements file

Next, upload your Python scripts required for the Spark job execution to a Storage account. 

1. Open the Storage account created in the `<environment-code>-pipeline-rg` resource group
2. Create a container named "spark-jobs" and upload the contents of the `transform\spark-jobs` folder in this repo to the newly created container

# Prepare to run the pipeline

Before running the pipeline, we need to prepare the Storage Account to host the Geospatial data.

- A separate container to host the raw, intermediate and final results of the transforms and AI Model.
- Config folder with configuration files listed below :

    - [Specification document](../src/aimodels/custom_vision_object_detection_offline/spec/custom_vision_object_detection.json) configuration file that is provided by the AI Model partner.

    Refer to the [Custom Vision Model Readme file](../src/aimodels/custom_vision_object_detection_offline/README.md) to build the docker image and prepare your specification document.

    - [Config file](../src/aimodels/custom_vision_object_detection_offline/config/config-pool-model-json.json) specific to the AI Model that contains parameters to be passed to the AI Model.
    - [Config file](../src/transforms/spark-jobs/raster_crop/config/config-aoi.json) for Crop transformation that container the Area of Interest to crop to.
    - [Config file](../src/transforms/spark-jobs/raster_convert/config/config-img-convert-png.json) for GeoTiff to Png transform.
    - [Config file](../src/transforms/spark-jobs/pool_geolocation/config/config-pool-geolocation.json) for pool gelocation transform which converts Image coordinates to Geolocation coordinates.

- Raw folder with one or more GeoTiff files to be processed

## Running the pipeline

To run the pipeline, open the Synapse Studio for the Synapse workspace that you have created. Make sure you have followed the steps in the `Deployment Procedures` to deploy and configure the solution.

- Open the `E2E Custom Vision Model Flow` and click on debug button

- When presented with the parameters, fill out the values. Below table provide the details on that each parameter represents.

| parameter | description |
|--|--|
| Prefix | A random string for distinguishing each run of the pipeline. Use a random string betwee 4 to 6 characters long. Example - hj4t |
| AoiName | A descriptive name to your Area of Interest. Example - LosAngeles |
| StorageSasToken | This is the SasToken to be used for retrieving the input data, reading the config file and writing the output data back to a storage account. An expiry time of minimum 3 hours is recommended for the Sas token. |
| RawDataContainer | Name of the container where the raw data from the source (say Geospatial) is stored. |
| StorageAccountConnStr | Connection string to the storage account containing the input data and config file. Also, used for writing back to the storage account |
| StorageAccountKey | Primary key of the storage account containing the input data and config file. Also, used for writing back to the storage account. |

- Once the parameters are entered, click ok to submit and kick off the pipeline.

- Wait for the pipeline to complete.

# Cleanup Script

We have a cleanup script to cleanup the resource groups and thus the resources provisioned using the `environment-code`.
As discussed above the `environment-code` is used as prefix to generate resource group names, so the cleanup-script deletes the resource groups with generated names.

Execute the cleanup script as follows:

```
$ ./cleanup.sh <environment-code>
```

For eg.
```
$ ./cleanup.sh aoi-demo
```

If one wants not to delete any specific resource group and thus resource they can use NO_DELETE_*_RESOURCE_GROUP environment variable, by setting it to true

```
$ NO_DELETE_DATA_RESOURCE_GROUP=true
$ NO_DELETE_MONITORING_RESOURCE_GROUP=true
$ NO_DELETE_NETWORKING_RESOURCE_GROUP=true
$ NO_DELETE_ORCHESTRATION_RESOURCE_GROUP=true
$ NO_DELETE_PIPELINE_RESOURCE_GROUP=true
$ ./cleanup.sh <environment-code>
```
