#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

ENV_CODE=${1:-${ENV_CODE}}
PIPELINE_NAME=${2:-${PIPELINE_NAME}}

DESTINATION_CONTAINER_NAME=${3:-${DESTINATION_CONTAINER_NAME}}
STORAGE_ACCOUNT_NAME=${4:-${STORAGE_ACCOUNT_NAME}}
STORAGE_ACCOUNT_RG_NAME=${5:-${STORAGE_ACCOUNT_RG_NAME}}
SOURCE_CONTAINER_NAME=${6:-${SOURCE_CONTAINER_NAME}}
SOURCE_STORAGE_ACCOUNT_NAME=${7:-${SOURCE_STORAGE_ACCOUNT_NAME}}
SOURCE_STORAGE_ACCOUNT_RG_NAME=${8:-${SOURCE_STORAGE_ACCOUNT_RG_NAME}}

set -ex

if [[ -z "$ENV_CODE" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi

if [[ -z "$PIPELINE_NAME" ]]; then
    PIPELINE_NAME="custom-vision-model"
fi
if [[ -z "$DESTINATION_CONTAINER_NAME" ]]; then
    DESTINATION_CONTAINER_NAME=${PIPELINE_NAME}-${ENV_CODE}
fi
if [[ -z "$STORAGE_ACCOUNT_RG_NAME" ]]; then
    STORAGE_ACCOUNT_RG_NAME="${ENV_CODE}-data-rg"
fi
if [[ -z "$STORAGE_ACCOUNT_NAME" ]]; then
    STORAGE_ACCOUNT_NAME=$(az storage account list --resource-group $STORAGE_ACCOUNT_RG_NAME --query [0].name -o tsv)
fi
if [[ -z "$STORAGE_ACCOUNT_KEY" ]]; then
    STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group ${STORAGE_ACCOUNT_RG_NAME} --account-name ${STORAGE_ACCOUNT_NAME} --query "[0].value" --output tsv)
fi

if [[ -z "$SOURCE_CONTAINER_NAME" ]]; then
    SOURCE_CONTAINER_NAME=${PIPELINE_NAME}
fi
if [[ -z "$SOURCE_STORAGE_ACCOUNT_RG_NAME" ]]; then
    SOURCE_STORAGE_ACCOUNT_RG_NAME="ci-resources"
fi
if [[ -z "$SOURCE_STORAGE_ACCOUNT_NAME" ]]; then
    SOURCE_STORAGE_ACCOUNT_NAME="stellarciresources"
fi
if [[ -z "$SOURCE_STORAGE_ACCOUNT_KEY" ]]; then
    SOURCE_STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group ${SOURCE_STORAGE_ACCOUNT_RG_NAME} --account-name ${SOURCE_STORAGE_ACCOUNT_NAME} --query "[0].value" --output tsv)
fi

echo "Creating container ${DESTINATION_CONTAINER_NAME} on storage account ${STORAGE_ACCOUNT_NAME}"
az storage container create --name ${DESTINATION_CONTAINER_NAME} --account-name ${STORAGE_ACCOUNT_NAME} --account-key ${STORAGE_ACCOUNT_KEY}


echo "Copying resources"

az storage blob copy start \
  --destination-blob raw/sample_4326.tif \
  --destination-container ${DESTINATION_CONTAINER_NAME} \
  --account-name ${STORAGE_ACCOUNT_NAME} \
  --account-key ${STORAGE_ACCOUNT_KEY} \
  --source-container ${SOURCE_CONTAINER_NAME} \
  --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
  --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
  --source-blob raw/sample_4326.tif

az storage blob copy start \
  --destination-blob config/config.json \
  --destination-container ${DESTINATION_CONTAINER_NAME} \
  --account-name ${STORAGE_ACCOUNT_NAME} \
  --account-key ${STORAGE_ACCOUNT_KEY} \
  --source-container ${SOURCE_CONTAINER_NAME} \
  --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
  --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
  --source-blob config/config.json

az storage blob copy start \
  --destination-blob config/custom_vision_object_detection.json \
  --destination-container ${DESTINATION_CONTAINER_NAME} \
  --account-name ${STORAGE_ACCOUNT_NAME} \
  --account-key ${STORAGE_ACCOUNT_KEY} \
  --source-container ${SOURCE_CONTAINER_NAME} \
  --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
  --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
  --source-blob config/custom_vision_object_detection.json
  
if [[ "${PIPELINE_NAME}" == "custom-vision-model" ]]; then
  az storage blob copy start \
    --destination-blob config/config-aoi.json \
    --destination-container ${DESTINATION_CONTAINER_NAME} \
    --account-name ${STORAGE_ACCOUNT_NAME} \
    --account-key ${STORAGE_ACCOUNT_KEY} \
    --source-container ${SOURCE_CONTAINER_NAME} \
    --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
    --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
    --source-blob config/config-aoi.json

  az storage blob copy start \
    --destination-blob config/config-img-convert-png.json \
    --destination-container ${DESTINATION_CONTAINER_NAME} \
    --account-name ${STORAGE_ACCOUNT_NAME} \
    --account-key ${STORAGE_ACCOUNT_KEY} \
    --source-container ${SOURCE_CONTAINER_NAME} \
    --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
    --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
    --source-blob config/config-img-convert-png.json

  az storage blob copy start \
    --destination-blob config/config-pool-geolocation.json \
    --destination-container ${DESTINATION_CONTAINER_NAME} \
    --account-name ${STORAGE_ACCOUNT_NAME} \
    --account-key ${STORAGE_ACCOUNT_KEY} \
    --source-container ${SOURCE_CONTAINER_NAME} \
    --source-account-name ${SOURCE_STORAGE_ACCOUNT_NAME} \
    --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} \
    --source-blob config/config-pool-geolocation.json
fi