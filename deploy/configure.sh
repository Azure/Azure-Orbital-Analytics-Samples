#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.


ENVCODE=$1

echo "configuration started ..."

set -x

# get synapse workspace and pool
SYNAPSE_WORKSPACE=$(az synapse workspace list --query "[?tags.workspaceId && tags.workspaceId == 'default'].name" -o tsv -g $1-pipeline-rg)
echo $SYNAPSE_WORKSPACE
SYNAPSE_WORKSPACE_RG=$(az synapse workspace list --query "[?tags.workspaceId && tags.workspaceId == 'default'].resourceGroup" -o tsv -g $1-pipeline-rg)
echo $SYNAPSE_WORKSPACE_RG
SYNAPSE_POOL=$(az synapse spark pool list --workspace-name ${SYNAPSE_WORKSPACE} --resource-group ${SYNAPSE_WORKSPACE_RG} --query "[?tags.poolId && tags.poolId == 'default'].name" -o tsv -g $1-pipeline-rg)
echo $SYNAPSE_POOL

if [[ -n $SYNAPSE_WORKSPACE ]] && [[ -n $SYNAPSE_WORKSPACE_RG ]] && [[ -n $SYNAPSE_POOL ]]
then
    # upload synapse pool 
    az synapse spark pool update --name ${SYNAPSE_POOL} --workspace-name ${SYNAPSE_WORKSPACE} --resource-group ${ENVCODE}-pipeline-rg --library-requirements 'environment.yml'
fi

# get batch account
BATCH_ACCT=$(az batch account list --query "[?tags.type && tags.type == 'batch'].name" -o tsv -g $1-orc-rg)
echo $BATCH_ACCT

if [[ -n $BATCH_ACCT ]]
then
    # create batch job for custom vision model
    az batch job create --id 'custom-vision-model-job' --pool-id 'data-cpu-pool'
fi

SYNAPSE_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'synapse'].name" -o tsv -g $1-pipeline-rg)
echo $SYNAPSE_STORAGE_ACCT

if [[ -n $SYNAPSE_STORAGE_ACCT ]]
then
    # create a container to upload the spark job python files
    az storage container create --name "spark-jobs" --account-name ${SYNAPSE_STORAGE_ACCT}
    # uploads the spark job python files
    az storage blob upload-batch --destination "spark-jobs" --account-name ${SYNAPSE_STORAGE_ACCT} --source '../src/transforms/spark-jobs'
fi

set +x

echo "configuration completed!"
