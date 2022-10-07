#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"

ENV_CODE=${1:-${ENV_CODE}}

BATCH_ACCOUNT_NAME=${2:-${BATCH_ACCOUNT_NAME:-"pipelinecibatch"}}
PIPELINE_NAME=${3:-${PIPELINE_NAME:-"custom-vision-model"}}

DESTINATION_CONTAINER_NAME=${4:-${DESTINATION_CONTAINER_NAME:-"${PIPELINE_NAME}-${ENV_CODE}"}}
DESTINATION_STORAGE_ACCOUNT_NAME=${5:-${DESTINATION_STORAGE_ACCOUNT_NAME}}
DESTINATION_STORAGE_ACCOUNT_RG_NAME=${6:-${DESTINATION_STORAGE_ACCOUNT_RG_NAME:-"${ENV_CODE}-data-rg"}}
SOURCE_CONTAINER_NAME=${7:-${SOURCE_CONTAINER_NAME:-${PIPELINE_NAME}}}
SOURCE_STORAGE_ACCOUNT_NAME=${8:-${SOURCE_STORAGE_ACCOUNT_NAME:-"pipelineciresources"}}
SOURCE_STORAGE_ACCOUNT_RG_NAME=${9:-${SOURCE_STORAGE_ACCOUNT_RG_NAME:-"ci-resources"}}
SYNAPSE_RESOURCE_GROUP_NAME=${10:-${SYNAPSE_RESOURCE_GROUP_NAME:-"${ENV_CODE}-pipeline-rg"}}
SYNAPSE_WORKSPACE_NAME=${11:-${SYNAPSE_WORKSPACE_NAME}}
BATCH_JOB_NAME=${12:-${BATCH_JOB_NAME:-"${ENV_CODE}-data-cpu-pool"}}
AOI_PARAMETER_VALUE=${13:-${AOI_PARAMETER_VALUE:-"-117.063550 32.749467 -116.999386 32.812946"}}
PIPELINE_FILE_NAME=${14:-${PIPELINE_FILE_NAME:-"E2E Custom Vision Model Flow.json"}}
PARAMETER_FILE_PATH=${15:-${PARAMETER_FILE_PATH:-"${PRJ_ROOT}/test/${PIPELINE_NAME}-parameters.json"}}
SUBSTITUTE_PARAMS=${16:-${SUBSTITUTE_PARAMS:-"true"}}

set -ex

if [[ -z "$ENV_CODE" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi

if [[ -z "$DESTINATION_STORAGE_ACCOUNT_NAME" ]]; then
    DESTINATION_STORAGE_ACCOUNT_NAME=$(az storage account list --resource-group $DESTINATION_STORAGE_ACCOUNT_RG_NAME --query [0].name -o tsv)
fi
if [[ -z "$STORAGE_ACCOUNT_KEY" ]]; then
    STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group ${DESTINATION_STORAGE_ACCOUNT_RG_NAME} --account-name ${DESTINATION_STORAGE_ACCOUNT_NAME} --query "[0].value" --output tsv)
fi
if [[ -z "$SOURCE_STORAGE_ACCOUNT_KEY" ]]; then
    SOURCE_STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group ${SOURCE_STORAGE_ACCOUNT_RG_NAME} --account-name ${SOURCE_STORAGE_ACCOUNT_NAME} --query "[0].value" --output tsv)
fi

if [[ -z "$SYNAPSE_WORKSPACE_NAME" ]]; then
    SYNAPSE_WORKSPACE_NAME=$(az synapse workspace list --query "[?tags.workspaceId && tags.workspaceId == 'default'].name" -o tsv -g ${SYNAPSE_RESOURCE_GROUP_NAME})
fi
# Create container in destination storage account
echo "Creating container ${DESTINATION_CONTAINER_NAME} on storage account ${DESTINATION_STORAGE_ACCOUNT_NAME}"
az storage container create --name ${DESTINATION_CONTAINER_NAME} --account-name ${DESTINATION_STORAGE_ACCOUNT_NAME} --account-key ${STORAGE_ACCOUNT_KEY}

# Upload test data to destination storage account container
echo "Copying resources to storage container ${DESTINATION_CONTAINER_NAME} on storage account ${DESTINATION_STORAGE_ACCOUNT_NAME}"
az storage blob copy start \
  --destination-blob raw/sample_4326.tif \
  --destination-container ${DESTINATION_CONTAINER_NAME} \
  --account-name ${DESTINATION_STORAGE_ACCOUNT_NAME} \
  --account-key ${STORAGE_ACCOUNT_KEY} \
  --source-container ${SOURCE_CONTAINER_NAME} \
  --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
  --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
  --source-blob raw/sample_4326.tif

az storage blob copy start \
  --destination-blob config/config.json \
  --destination-container ${DESTINATION_CONTAINER_NAME} \
  --account-name ${DESTINATION_STORAGE_ACCOUNT_NAME} \
  --account-key ${STORAGE_ACCOUNT_KEY} \
  --source-container ${SOURCE_CONTAINER_NAME} \
  --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
  --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
  --source-blob config/config.json

az storage blob copy start \
  --destination-blob config/custom_vision_object_detection.json \
  --destination-container ${DESTINATION_CONTAINER_NAME} \
  --account-name ${DESTINATION_STORAGE_ACCOUNT_NAME} \
  --account-key ${STORAGE_ACCOUNT_KEY} \
  --source-container ${SOURCE_CONTAINER_NAME} \
  --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
  --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
  --source-blob config/custom_vision_object_detection.json

# Install Pipeline
echo "Preparing commands to install pipeline components"
mkdir /tmp/packaged-pipeline
unzip ${PIPELINE_NAME}.zip -d /tmp/packaged-pipeline/
echo "#!/usr/bin/env bash" > /tmp/install-pipeline.sh
echo "set -ex" >> /tmp/install-pipeline.sh
chmod +x /tmp/install-pipeline.sh
python3 ${PRJ_ROOT}/test/create-pipeline-install-commands.py \
    --file_name "/tmp/packaged-pipeline/pipeline/${PIPELINE_FILE_NAME}" \
    --resource_group_name ${SYNAPSE_RESOURCE_GROUP_NAME} \
    --workspace_name ${SYNAPSE_WORKSPACE_NAME} >> /tmp/install-pipeline.sh

echo "Installing pipeline components"
/tmp/install-pipeline.sh

# Create pipeline parameter file
if [[ "${SUBSTITUTE_PARAMS,,}" == "true" ]]; then
    echo "Generating parameter file for pipeline execution"
    BATCH_ACCOUNT_ID=$(az batch account list --query "[?name == '${BATCH_ACCOUNT_NAME}'].id" -o tsv)
    BATCH_ACCOUNT_RG_NAME=$(az resource show --ids ${BATCH_ACCOUNT_ID} --query resourceGroup -o tsv)
    BATCH_ACCOUNT_LOCATION=$(az batch account show  --name ${BATCH_ACCOUNT_NAME} --resource-group ${BATCH_ACCOUNT_RG_NAME} --query "location" --output tsv)

    export RAW_DATA_STORAGE_ACCOUNT_CONTAINER_NAME=${DESTINATION_CONTAINER_NAME}
    export RAW_DATA_STORAGE_ACCOUNT_NAME=${DESTINATION_STORAGE_ACCOUNT_NAME}
    export RAW_DATA_STORAGE_ACCOUNT_KEY=${DESTINATION_STORAGE_ACCOUNT_RG_NAME}
    export BATCH_ACCOUNT_NAME
    export BATCH_JOB_NAME
    export BATCH_ACCOUNT_LOCATION
    export AOI=${AOI_PARAMETER_VALUE}

    envsubst < ${PARAMETER_FILE_PATH} > /tmp/parameters.json
    export PARAMETER_FILE_PATH="/tmp/parameters.json"
fi

# Execute pipeline
echo "Executing ${PIPELINE_NAME} pipeline"
PIPELINE_RUN_ID=$(az synapse pipeline create-run \
    --workspace-name ${SYNAPSE_WORKSPACE_NAME} \
    --name "E2E Custom Vision Model Flow" \
    --parameters @"${PARAMETER_FILE_PATH}" \
    --query runId --output tsv 2>/dev/null)

# Check pipeline run status
${PRJ_ROOT}/test/check-pipeline-status.sh ${ENV_CODE} ${PIPELINE_RUN_ID}
