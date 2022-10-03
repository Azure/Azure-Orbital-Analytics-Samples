## Executing the pipeline

We have uploaded the pipeline to shared-gallery for Azure Synapse.
If you have come to this document following the references to shared-gallery then proceed to [instructions.md](./gallery/instructions.md) for executing the pipeline.

Following sections describe how to package, upload and execute the pipeline on Azure Synapse.

## Packaging the Synapse Pipeline

To package the Synapse pipeline, run the `package.sh` script use following the minimalistic syntax:

```bash
./deploy/package.sh <environmentCode>
```

If you want to execute overriding the default values for the script, following is the syntax and description of parameters.

```bash
./deploy/package.sh <environmentCode> <pipelineName> <aiModelInfraType> \
    <aiModelResourceName> <aiModelResourceGroupName> <aiModelStorageAccountName> \
    <keyVaultName> \
    <rawStorageAccountRG> <rawStorageAccountName> \
    <synapseWorkspaceRG> <synapseWorkspaceName> <synapseStorageAccountName> <synapsePool> \
    <deployPgsql>
```

Arguments | Required | Type | Sample value
----------|-----------|-------|---------------
environmentCode | yes | string | aoi
pipelineName | no | string | Allowed Value: custom-vision-model
aiModelInfraType | no | string | Allowed values: batch-account, aks (default value: batch-account)
aiModelResourceName | no | string | aoibatchaccount
aiModelStorageAccountName | no | string | aoibatchaccountrg
aiModelResourceGroupName | no | string | aoibatchstorageaccount
keyVaultName | no | string | aoiKeyVault
rawStorageAccountRG | no | string | aoi-data-rg
rawStorageAccountName | no | string | rawdata34keh240
synapseWorkspaceRG | no | string | aoisynapseworkspacerg
synapseWorkspaceName | no | string | aoisynapseworksapce
synapseStorageAccountName | no | string | synrawdatastorage
synapsePool | no | string | synapsepoolname
deployPgsql | no | boolean | false

## Upload the pipeline to Azure Synapse

We can use git source control method of Azure Synapse to import pipeline using a git repository.

Unzip the contents of the ZIP file generate by running the `package.sh` or `setup.sh` and use the contents to load them to your repository.

A few things to consider prior to integration of Git / GitHub Repository with Synapse Studio:

* Do not bring the files from [workflow folder](../src/workflow) directly into your repository that you will use to integrate with Synapse Studio. You will need to run `package.sh` or `setup.sh` to replace placeholders in one or more files before checking-in the files to your repository to be used with the Synapse Studio. 
* You can either create a new repository or use a forked version of the [Azure Orbital Analytics Sample](https://github.com/Azure/Azure-Orbital-Analytics-Samples) repository. If you use a new repository, use the unzipped contents of the ZIP file to load into your new repository. If you use forked version of the [Azure Orbital Analytics Sample](https://github.com/Azure/Azure-Orbital-Analytics-Samples) repository, overwrite the contents of [Custom vision model workflow folder](../src/workflow/custom-vision-model) with the Unzipped contents.


Pipeline can be imported into the Synape Studio through Source Control repository like GitHub or Azure DevOps repository, refer to the document on [Source Control](https://docs.microsoft.com/azure/synapse-analytics/cicd/source-control) to learn about Git Integration for Azure Synapse Analytics and how to setup.

**Note**: Once the Synapse Studio is linked to your repository, make sure you publish all the components. Failure to publish the components imported by linked Synapse Studio to Github / ADO repository, will result in errors when running the pipeline.

# Running the pipeline (Custom Vision Model)

Before starting the pipeline, prepare the storage account in <environmentCode>-data-rg resource group by creating a container for the pipeline run.

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

# Attributions And Disclaimers

- [Geotiff file](https://aoigeospatial.blob.core.windows.net/public/samples/sample_4326.tif) provided as sample are attributed to NAIP Imagery available via [Planetary Computer](https://planetarycomputer.microsoft.com) They are covered under [USDA](https://ngda-imagery-geoplatform.hub.arcgis.com)