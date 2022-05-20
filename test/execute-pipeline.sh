#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"

ENV_CODE=${1:-${ENV_CODE}}
BATCH_ACCOUNT_NAME=${2:-${BATCH_ACCOUNT_NAME}}
PIPELINE_NAME=${3:-${PIPELINE_NAME}}

BATCH_JOB_NAME=${4:-${BATCH_JOB_NAME}}
RAW_DATA_STORAGE_ACCOUNT_CONTAINER_NAME=${5:-${RAW_DATA_STORAGE_ACCOUNT_CONTAINER_NAME}}
RAW_DATA_STORAGE_ACCOUNT_NAME=${6:-${RAW_DATA_STORAGE_ACCOUNT_NAME}}
RAW_DATA_STORAGE_ACCOUNT_RG_NAME=${7:-${RAW_DATA_STORAGE_ACCOUNT_RG_NAME}}
SYNAPSE_WORKSPACE_NAME=${7:-${SYNAPSE_WORKSPACE_NAME}}
AOI=${8:-${AOI}}
PARAMETER_FILE_PATH=${9:-${PARAMETER_FILE_PATH}}
SUBSTITUTE_PARAMS=${10:-${SUBSTITUTE_PARAMS}}

set -e

if [[ -z "$ENV_CODE" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi

if [[ -z "$BATCH_ACCOUNT_NAME" ]]
  then
    echo "Batch Account Name value not supplied"
    exit 1
fi

if [[ -z "$PIPELINE_NAME" ]]; then
    PIPELINE_NAME="custom-vision-model"
fi
if [[ -z "$PARAMETER_FILE_PATH" ]]; then
    PARAMETER_FILE_PATH="${PRJ_ROOT}/test/${PIPELINE_NAME}-parameters.json"
fi
if [[ -z "$SUBSTITUTE_PARAMS" ]]; then
    SUBSTITUTE_PARAMS="true"
fi
if [[ "${SUBSTITUTE_PARAMS,,}" == "true" ]]; then
    if [[ -z "$RAW_DATA_STORAGE_ACCOUNT_CONTAINER_NAME" ]]; then
        RAW_DATA_STORAGE_ACCOUNT_CONTAINER_NAME=${PIPELINE_NAME}-${ENV_CODE}
    fi
    if [[ -z "$RAW_DATA_STORAGE_ACCOUNT_RG_NAME" ]]; then
        RAW_DATA_STORAGE_ACCOUNT_RG_NAME="${ENV_CODE}-data-rg"
    fi
    if [[ -z "$RAW_DATA_STORAGE_ACCOUNT_NAME" ]]; then
        RAW_DATA_STORAGE_ACCOUNT_NAME=$(az storage account list --resource-group $RAW_DATA_STORAGE_ACCOUNT_RG_NAME --query [0].name -o tsv)
    fi
    if [[ -z "$RAW_DATA_STORAGE_ACCOUNT_KEY" ]]; then
        RAW_DATA_STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group ${RAW_DATA_STORAGE_ACCOUNT_RG_NAME} --account-name ${RAW_DATA_STORAGE_ACCOUNT_NAME} --query "[0].value" --output tsv)
    fi
    if [[ -z "$BATCH_JOB_NAME" ]]; then
        BATCH_JOB_NAME="${ENV_CODE}-data-cpu-pool"
    fi
    if [[ -z "$SYNAPSE_WORKSPACE_NAME" ]]; then
        SYNAPSE_WORKSPACE_NAME="${ENV_CODE}-pipeline-syn-ws"
    fi
    if [[ -z "$AOI" ]]; then
        AOI="-117.063550 32.749467 -116.999386 32.812946"
    fi
    BATCH_ACCOUNT_ID=$(az batch account list --query "[?name == '${BATCH_ACCOUNT_NAME}'].id" -o tsv)
    BATCH_ACCOUNT_RG_NAME=$(az resource show --ids ${BATCH_ACCOUNT_ID} --query resourceGroup -o tsv)
    BATCH_ACCOUNT_LOCATION=$(az batch account show  --name ${BATCH_ACCOUNT_NAME} --resource-group ${BATCH_ACCOUNT_RG_NAME} --query "location" --output tsv)

    export RAW_DATA_STORAGE_ACCOUNT_CONTAINER_NAME
    export RAW_DATA_STORAGE_ACCOUNT_NAME
    export RAW_DATA_STORAGE_ACCOUNT_KEY
    export BATCH_ACCOUNT_NAME
    export BATCH_JOB_NAME
    export BATCH_ACCOUNT_LOCATION
    export AOI

    envsubst < ${PARAMETER_FILE_PATH} > /tmp/parameters.json
    export PARAMETER_FILE_PATH="/tmp/parameters.json"
fi

PIPELINE_RUN_ID=$(az synapse pipeline create-run \
    --workspace-name $SYNAPSE_WORKSPACE_NAME \
    --name "E2E Custom Vision Model Flow" \
    --parameters @"${PARAMETER_FILE_PATH}" \
    --query runId --output tsv 2>/dev/null)
echo $PIPELINE_RUN_ID