#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"

ENV_CODE=${1:-${ENV_CODE}}

BATCH_ACCOUNT_NAME=${2:-${BATCH_ACCOUNT_NAME:-"stellarbatchdev"}}
PIPELINE_NAME=${3:-${PIPELINE_NAME:-"custom-vision-model-v2"}}

DESTINATION_CONTAINER_NAME=${4:-${DESTINATION_CONTAINER_NAME:-"${PIPELINE_NAME}-${ENV_CODE}"}}
DESTINATION_STORAGE_ACCOUNT_NAME=${5:-${DESTINATION_STORAGE_ACCOUNT_NAME}}
DESTINATION_STORAGE_ACCOUNT_RG_NAME=${6:-${DESTINATION_STORAGE_ACCOUNT_RG_NAME:-"${ENV_CODE}-data-rg"}}
SOURCE_CONTAINER_NAME=${7:-${SOURCE_CONTAINER_NAME:-${PIPELINE_NAME}}}
SOURCE_STORAGE_ACCOUNT_NAME=${8:-${SOURCE_STORAGE_ACCOUNT_NAME:-"stellarciresources"}}
SOURCE_STORAGE_ACCOUNT_RG_NAME=${9:-${SOURCE_STORAGE_ACCOUNT_RG_NAME:-"ci-resources"}}
SYNAPSE_RESOURCE_GROUP_NAME=${10:-${SYNAPSE_RESOURCE_GROUP_NAME:-"${ENV_CODE}-pipeline-rg"}}
SYNAPSE_WORKSPACE_NAME=${11:-${SYNAPSE_WORKSPACE_NAME:-"${ENV_CODE}-pipeline-syn-ws"}}
BATCH_JOB_NAME=${12:-${BATCH_JOB_NAME:-"${ENV_CODE}-data-cpu-pool"}}
AOI_PARAMETER_VALUE=${13:-${AOI_PARAMETER_VALUE:-"-117.063550 32.749467 -116.999386 32.812946"}}
PARAMETER_FILE_PATH=${14:-${PARAMETER_FILE_PATH:-"${PRJ_ROOT}/test/${PIPELINE_NAME}-parameters.json"}}
SUBSTITUTE_PARAMS=${15:-${SUBSTITUTE_PARAMS:-"true"}}


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

# Create container in destination storage account
echo "Creating container ${DESTINATION_CONTAINER_NAME} on storage account ${DESTINATION_STORAGE_ACCOUNT_NAME}"
az storage container create --name ${DESTINATION_CONTAINER_NAME} --account-name ${DESTINATION_STORAGE_ACCOUNT_NAME} --account-key ${STORAGE_ACCOUNT_KEY}


# Upload test data to destination storage account container
echo "Copying resources"
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
  
if [[ "${PIPELINE_NAME}" == "custom-vision-model" ]]; then
  az storage blob copy start \
    --destination-blob config/config-aoi.json \
    --destination-container ${DESTINATION_CONTAINER_NAME} \
    --account-name ${DESTINATION_STORAGE_ACCOUNT_NAME} \
    --account-key ${STORAGE_ACCOUNT_KEY} \
    --source-container ${SOURCE_CONTAINER_NAME} \
    --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
    --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
    --source-blob config/config-aoi.json

  az storage blob copy start \
    --destination-blob config/config-img-convert-png.json \
    --destination-container ${DESTINATION_CONTAINER_NAME} \
    --account-name ${DESTINATION_STORAGE_ACCOUNT_NAME} \
    --account-key ${STORAGE_ACCOUNT_KEY} \
    --source-container ${SOURCE_CONTAINER_NAME} \
    --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
    --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
    --source-blob config/config-img-convert-png.json

  az storage blob copy start \
    --destination-blob config/config-pool-geolocation.json \
    --destination-container ${DESTINATION_CONTAINER_NAME} \
    --account-name ${DESTINATION_STORAGE_ACCOUNT_NAME} \
    --account-key ${STORAGE_ACCOUNT_KEY} \
    --source-container ${SOURCE_CONTAINER_NAME} \
    --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
    --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
    --source-blob config/config-pool-geolocation.json
fi

# Install Pipeline
mkdir packaged-pipeline
unzip ${PIPELINE_NAME}.zip -d ./packaged-pipeline/
echo "#!/usr/bin/env bash" > install-pipeline.sh
echo "set -ex" >> install-pipeline.sh
chmod +x install-pipeline.sh
python3 ./test/create-pipeline-install-commands.py \
    --file_name "./packaged-pipeline/pipeline/E2E Custom Vision Model Flow.json" \
    --resource_group_name ${SYNAPSE_RESOURCE_GROUP_NAME} \
    --workspace_name ${SYNAPSE_WORKSPACE_NAME} >> install-pipeline.sh
cat install-pipeline.sh
./install-pipeline.sh

# Create pipeline parameter file

if [[ "${SUBSTITUTE_PARAMS,,}" == "true" ]]; then
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
PIPELINE_RUN_ID=$(az synapse pipeline create-run \
    --workspace-name ${SYNAPSE_WORKSPACE_NAME} \
    --name "E2E Custom Vision Model Flow" \
    --parameters @"${PARAMETER_FILE_PATH}" \
    --query runId --output tsv 2>/dev/null)

# Check pipeline run status
./test/check-pipeline-status.sh ${ENV_CODE} ${PIPELINE_RUN_ID}
