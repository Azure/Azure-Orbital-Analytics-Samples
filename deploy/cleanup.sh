#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

set -e

# parameters
ENV_CODE=${1:-"aoi"}
PRE_PROVISIONED_BATCH_ACCOUNT_NAME=${2:-$PRE_PROVISIONED_BATCH_ACCOUNT_NAME}

NO_DELETE_DATA_RESOURCE_GROUP=${NO_DELETE_DATA_RESOURCE_GROUP:-"false"}
DATA_RESOURCE_GROUP="${ENV_CODE}-data-rg"

NO_DELETE_MONITORING_RESOURCE_GROUP=${NO_DELETE_MONITORING_RESOURCE_GROUP:-"false"}
MONITORING_RESOURCE_GROUP="${ENV_CODE}-monitor-rg"

NO_DELETE_NETWORKING_RESOURCE_GROUP=${NO_DELETE_NETWORKING_RESOURCE_GROUP:-"false"}
NETWORKING_RESOURCE_GROUP="${ENV_CODE}-network-rg"

NO_DELETE_ORCHESTRATION_RESOURCE_GROUP=${NO_DELETE_ORCHESTRATION_RESOURCE_GROUP:-"false"}
ORCHESTRATION_RESOURCE_GROUP="${ENV_CODE}-orc-rg"

NO_DELETE_PIPELINE_RESOURCE_GROUP=${NO_DELETE_PIPELINE_RESOURCE_GROUP:-"false"}
PIPELINE_RESOURCE_GROUP="${ENV_CODE}-pipeline-rg"

if [[ ${NO_DELETE_DATA_RESOURCE_GROUP} != "true" ]] && [[ ${NO_DELETE_DATA_RESOURCE_GROUP} == "false" ]]; then
    set -x
    az group delete --name ${DATA_RESOURCE_GROUP} --no-wait --yes
    az deployment sub delete --name ${DATA_RESOURCE_GROUP} --no-wait --yes
    set +x
fi

if [ "${NO_DELETE_MONITORING_RESOURCE_GROUP}" != "true" ] && [ "${NO_DELETE_MONITORING_RESOURCE_GROUP}" == "false" ]; then
    set -x
    az group delete --name ${MONITORING_RESOURCE_GROUP} --no-wait --yes
    az deployment sub delete --name ${MONITORING_RESOURCE_GROUP} --no-wait --yes
    set +x
fi

if [ "${NO_DELETE_NETWORKING_RESOURCE_GROUP}" != "true" ] && [ "${NO_DELETE_NETWORKING_RESOURCE_GROUP}" == "false" ]; then
    set -x
    az group delete --name ${NETWORKING_RESOURCE_GROUP} --no-wait --yes
    az deployment sub delete --name ${NETWORKING_RESOURCE_GROUP} --no-wait --yes
    set +x
fi

if [ "${NO_DELETE_ORCHESTRATION_RESOURCE_GROUP}" != "true" ] && [ "${NO_DELETE_ORCHESTRATION_RESOURCE_GROUP}" == "false" ]; then
    set -x
    az group delete --name ${ORCHESTRATION_RESOURCE_GROUP} --no-wait --yes
    az deployment sub delete --name ${ORCHESTRATION_RESOURCE_GROUP} --no-wait --yes
    set +x
fi

if [ "${NO_DELETE_PIPELINE_RESOURCE_GROUP}" != "true" ] && [ "${NO_DELETE_PIPELINE_RESOURCE_GROUP}" == "false" ]; then
    set -x
    az group delete --name ${PIPELINE_RESOURCE_GROUP} --no-wait --yes
    az deployment sub delete --name ${PIPELINE_RESOURCE_GROUP} --no-wait --yes
    set +x
fi

BATCH_ACCOUNT_POOL_NAME=${BATCH_ACCOUNT_POOL_NAME:-"${ENV_CODE}-data-cpu-pool"}
NO_BATCH_ACCOUNT_POOL_NAME=${NO_BATCH_ACCOUNT_POOL_NAME:-"false"}
if [[ -z "$PRE_PROVISIONED_BATCH_ACCOUNT_NAME" ]] && [ "${NO_BATCH_ACCOUNT_POOL_NAME}" != "true" ] && [ "${NO_BATCH_ACCOUNT_POOL_NAME}" == "false" ]; then
    echo "Cleanup the batch pool and batch job"
    BATCH_ACCOUNT_ID=$(az batch account list --query "[?name == '${PRE_PROVISIONED_BATCH_ACCOUNT_NAME}'].id" -o tsv)
    BATCH_ACCOUNT_RG_NAME=$(az resource show --ids ${BATCH_ACCOUNT_ID} --query resourceGroup -o tsv)
    BATCH_ACCOUNT_KEY=$(az batch account keys list --name ${BATCH_ACCOUNT_NAME} --resource-group ${BATCH_ACCOUNT_RG_NAME} | jq ".primary")
    az batch pool delete --pool-id ${BATCH_ACCOUNT_POOL_NAME} --account-name ${PRE_PROVISIONED_BATCH_ACCOUNT_NAME} --account-key ${BATCH_ACCOUNT_KEY}
fi