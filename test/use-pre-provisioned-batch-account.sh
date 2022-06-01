#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"

ENV_CODE=${1:-${ENV_CODE}}
DESTINATION_BATCH_ACCOUNT_NAME=${2:-${DESTINATION_BATCH_ACCOUNT_NAME}}

PIPELINE_NAME=${3:-${PIPELINE_NAME:-"custom-vision-model-v2"}}
DESTINATION_BATCH_ACCOUNT_ROLE=${4:-${DESTINATION_BATCH_ACCOUNT_ROLE:-"Contributor"}}
DESTINATION_BATCH_ACCOUNT_POOL_NAME=${5:-${DESTINATION_BATCH_ACCOUNT_POOL_NAME:-"${ENV_CODE}-data-cpu-pool"}}
DESTINATION_BATCH_ACCOUNT_STORAGE_ACCOUNT_NAME=${6:-${DESTINATION_BATCH_ACCOUNT_STORAGE_ACCOUNT_NAME}}

BATCH_POOL_MOUNT_STORAGE_ACCOUNT_NAME=${7:-${BATCH_POOL_MOUNT_STORAGE_ACCOUNT_NAME}}
BATCH_POOL_MOUNT_STORAGE_ACCOUNT_RG_NAME=${8:-${BATCH_POOL_MOUNT_STORAGE_ACCOUNT_RG_NAME}}

if [[ -z "$ENV_CODE" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi

if [[ -z "$DESTINATION_BATCH_ACCOUNT_NAME" ]]
  then
    echo "Batch Account Name value not supplied"
    exit 1
fi

set -ex

DESTINATION_BATCH_ACCOUNT_ID=$(az batch account list --query "[?name == '${DESTINATION_BATCH_ACCOUNT_NAME}'].id" -o tsv)
DESTINATION_BATCH_ACCOUNT_RG_NAME=$(az resource show --ids ${DESTINATION_BATCH_ACCOUNT_ID} --query resourceGroup -o tsv)
DESTINATION_BATCH_ACCOUNT_STORAGE_ACCOUNT_NAME=$(az storage account list --resource-group $DESTINATION_BATCH_ACCOUNT_RG_NAME --query [0].name -o tsv)
BATCH_POOL_MOUNT_STORAGE_ACCOUNT_RG_NAME="${ENV_CODE}-data-rg"
BATCH_POOL_MOUNT_STORAGE_ACCOUNT_NAME=$(az storage account list --resource-group $BATCH_POOL_MOUNT_STORAGE_ACCOUNT_RG_NAME --query [0].name -o tsv)
SOURCE_SYNAPSE_WORKSPACE_NAME="${ENV_CODE}-pipeline-syn-ws"
SOURCE_SYNAPSE_WORKSPACE_RG_NAME="${ENV_CODE}-pipeline-rg"

# Verify that infrastructure and batch account are in same location
BATCH_ACCOUNT_LOCATION=$(az batch account show  --name ${DESTINATION_BATCH_ACCOUNT_NAME} --resource-group ${DESTINATION_BATCH_ACCOUNT_RG_NAME} --query "location" --output tsv)
SYNAPSE_WORKSPACE_LOCATION=$(az synapse workspace show --name ${SOURCE_SYNAPSE_WORKSPACE_NAME} --resource-group ${SOURCE_SYNAPSE_WORKSPACE_RG_NAME} --query "location" --output tsv)
if [[ "${BATCH_ACCOUNT_LOCATION}" != ${SYNAPSE_WORKSPACE_LOCATION} ]]; then
    echo "Batch Account and Synapse Workspace are not in same location!!!"
    exit -1
fi

# Grant access to batch account for Managed Identities
python3 ${PRJ_ROOT}/test/batch_account.py \
    --env_code ${ENV_CODE} \
    --target_batch_account_name ${DESTINATION_BATCH_ACCOUNT_NAME} \
    --target_batch_account_resource_group_name ${DESTINATION_BATCH_ACCOUNT_RG_NAME} \
    --batch_account_role ${DESTINATION_BATCH_ACCOUNT_ROLE}

# Deploy Batch Pool
BATCH_POOL_MOUNT_STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group ${BATCH_POOL_MOUNT_STORAGE_ACCOUNT_RG_NAME} --account-name ${BATCH_POOL_MOUNT_STORAGE_ACCOUNT_NAME} --query "[0].value" --output tsv)
BATCH_POOL_MOUNT_STORAGE_ACCOUNT_FILE_URL=$(az storage account show --resource-group ${BATCH_POOL_MOUNT_STORAGE_ACCOUNT_RG_NAME} --name ${BATCH_POOL_MOUNT_STORAGE_ACCOUNT_NAME}  --query "primaryEndpoints.file" --output tsv)

echo
echo "Deploying batch pool \"${DESTINATION_BATCH_ACCOUNT_POOL_NAME}\" on batch account \"${DESTINATION_BATCH_ACCOUNT_NAME}\""
az deployment group create --resource-group "${ENV_CODE}-orc-rg" \
    --template-file ${PRJ_ROOT}/deploy/infra/create_cpu_batch_account_pool.bicep \
    --parameters \
        environmentCode=${ENV_CODE} \
        projectName="orc" \
        acrName="${ENV_CODE}orcacr"\
        batchAccountName=${DESTINATION_BATCH_ACCOUNT_NAME} \
        batchAccountResourceGroup=${DESTINATION_BATCH_ACCOUNT_RG_NAME} \
        batchAccountCpuOnlyPoolName="${DESTINATION_BATCH_ACCOUNT_POOL_NAME}" \
        batchAccountPoolMountAccountName=${BATCH_POOL_MOUNT_STORAGE_ACCOUNT_NAME} \
        batchAccountPoolMountAccountKey=${BATCH_POOL_MOUNT_STORAGE_ACCOUNT_KEY} \
        batchAccountPoolMountFileUrl="${BATCH_POOL_MOUNT_STORAGE_ACCOUNT_FILE_URL}volume-a"
