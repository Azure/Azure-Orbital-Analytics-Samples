#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"
set -ex

ENVCODE=$1
PIPELINE_NAME=$2

echo 'Retrieving resources from Azure ...'
RAW_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'raw'].name" -o tsv -g $ENVCODE-data-rg)
SYNAPSE_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'synapse'].name" -o tsv -g $ENVCODE-pipeline-rg)
BATCH_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'batch'].name" -o tsv -g $ENVCODE-orc-rg)
BATCH_ACCT=$(az batch account list --query "[?tags.type && tags.type == 'batch'].name" -o tsv -g $ENVCODE-orc-rg)
BATCH_ACCT_LOCATION=$(az batch account list --query "[?tags.type && tags.type == 'batch'].location" -o tsv -g $ENVCODE-orc-rg)
KEY_VAULT=$(az keyvault list --query "[?tags.usage && tags.usage == 'linkedService'].name" -o tsv -g $ENVCODE-pipeline-rg)
SYNAPSE_WORKSPACE=$(az synapse workspace list --query "[?tags.workspaceId && tags.workspaceId == 'default'].name" -o tsv -g $ENVCODE-pipeline-rg)
echo $SYNAPSE_WORKSPACE
SYNAPSE_WORKSPACE_RG=$(az synapse workspace list --query "[?tags.workspaceId && tags.workspaceId == 'default'].resourceGroup" -o tsv -g $ENVCODE-pipeline-rg)
echo $SYNAPSE_WORKSPACE_RG
SYNAPSE_POOL=$(az synapse spark pool list --workspace-name $SYNAPSE_WORKSPACE --resource-group $SYNAPSE_WORKSPACE_RG --query "[?tags.poolId && tags.poolId == 'default'].name" -o tsv -g $ENVCODE-pipeline-rg)
echo $SYNAPSE_POOL
DB_SERVER_NAME=$(az postgres server list --resource-group $ENVCODE-data-rg --query '[].fullyQualifiedDomainName' -o tsv)
echo $DB_SERVER_NAME
DB_NAME=$(az postgres server list --resource-group $ENVCODE-data-rg --query '[].name' -o tsv)
echo $DB_NAME
DB_USERNAME=$(az postgres server list --resource-group $ENVCODE-data-rg --query '[].administratorLogin' -o tsv)@$DB_NAME
echo $DB_USERNAME

echo 'Retrieved resource from Azure and ready to package'
PACKAGING_SCRIPT="python3 ${PRJ_ROOT}/deploy/package.py --raw_storage_account_name $RAW_STORAGE_ACCT \
    --synapse_storage_account_name $SYNAPSE_STORAGE_ACCT \
    --batch_storage_account_name $BATCH_STORAGE_ACCT \
    --batch_account $BATCH_ACCT \
    --linked_key_vault $KEY_VAULT \
    --synapse_pool_name $SYNAPSE_POOL \
    --location $BATCH_ACCT_LOCATION \
    --pipeline_name $PIPELINE_NAME \
    --pg_db_username $DB_USERNAME \
    --pg_db_server_name $DB_SERVER_NAME"

echo $PACKAGING_SCRIPT
set -x

echo 'Starting packaging script ...'
$PACKAGING_SCRIPT

echo 'Packaging script completed'