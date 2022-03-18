#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

set -ex

echo 'Retrieving resources from Azure ...'
RAW_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'raw'].name" -o tsv -g $1-data-rg)
SYNAPSE_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'synapse'].name" -o tsv -g $1-pipeline-rg)
BATCH_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'batch'].name" -o tsv -g $1-orc-rg)
BATCH_ACCT=$(az batch account list --query "[?tags.type && tags.type == 'batch'].name" -o tsv -g $1-orc-rg)
KEY_VAULT=$(az keyvault list --query "[?tags.usage && tags.usage == 'linkedService'].name" -o tsv -g $1-pipeline-rg)
SYNAPSE_WORKSPACE=$(az synapse workspace list --query "[?tags.workspaceId && tags.workspaceId == 'default'].name" -o tsv -g $1-pipeline-rg)
echo $SYNAPSE_WORKSPACE
SYNAPSE_WORKSPACE_RG=$(az synapse workspace list --query "[?tags.workspaceId && tags.workspaceId == 'default'].resourceGroup" -o tsv -g $1-pipeline-rg)
echo $SYNAPSE_WORKSPACE_RG
SYNAPSE_POOL=$(az synapse spark pool list --workspace-name ${SYNAPSE_WORKSPACE:0:${#SYNAPSE_WORKSPACE}-1} --resource-group ${SYNAPSE_WORKSPACE_RG:0:${#SYNAPSE_WORKSPACE_RG}-1} --query "[?tags.poolId && tags.poolId == 'default'].name" -o tsv -g $1-pipeline-rg)
echo $SYNAPSE_POOL

echo 'Retrieved resource from Azure and ready to package'
PACKAGING_SCRIPT="python3 package.py --raw_storage_account_name ${RAW_STORAGE_ACCT:0:${#RAW_STORAGE_ACCT}-1} \
    --synapse_storage_account_name ${SYNAPSE_STORAGE_ACCT:0:${#SYNAPSE_STORAGE_ACCT}-1} \
    --batch_storage_account_name ${BATCH_STORAGE_ACCT:0:${#BATCH_STORAGE_ACCT}-1} \
    --batch_account ${BATCH_ACCT:0:${#BATCH_ACCT}-1} \
    --linked_key_vault ${KEY_VAULT:0:${#KEY_VAULT}-1} \
    --synapse_pool_name ${SYNAPSE_POOL:0:${#SYNAPSE_POOL}-1} \
    --location $2"

echo $PACKAGING_SCRIPT
set -x

echo 'Starting packaging script ...'
$PACKAGING_SCRIPT

echo 'Packaging script completed'