#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"

environment_code=${1}
target_batch_account_name=${2}

pipeline_name=${3:-'custom-vision-model-v2'}
target_batch_account_role=${4:-"Contributor"}
target_batch_account_pool_name=${5:-"${environment_code}-data-cpu-pool"}
target_batch_account_storage_account_name=${6:-""}

target_batch_pool_mount_storage_account_name=${7:-""}
target_batch_pool_mount_storage_account_resource_group_name=${8:-""}

if [[ -z "$environment_code" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi

if [[ -z "$target_batch_account_name" ]]
  then
    echo "Batch Account Name value not supplied"
    exit 1
fi

set -e

target_batch_account_id=$(az batch account list --query "[?name == '${target_batch_account_name}'].id" -o tsv)
target_batch_account_resource_group_name=$(az resource show --ids ${target_batch_account_id} --query resourceGroup -o tsv)
target_batch_account_storage_account_name=$(az storage account list --resource-group $target_batch_account_resource_group_name --query [0].name -o tsv)
target_batch_pool_mount_storage_account_resource_group_name="${environment_code}-data-rg"
target_batch_pool_mount_storage_account_name=$(az storage account list --resource-group $target_batch_pool_mount_storage_account_resource_group_name --query [0].name -o tsv)
source_synapse_workspace_name="${environment_code}-pipeline-syn-ws"
source_synapse_resource_group_name="${environment_code}-pipeline-rg"
# Verify that infrastructure and batch account are in same location
batch_account_location=$(az batch account show  --name ${target_batch_account_name} --resource-group ${target_batch_account_resource_group_name} --query "location" --output tsv)
synapse_workspace_location=$(az synapse workspace show --name ${source_synapse_workspace_name} --resource-group ${source_synapse_resource_group_name} --query "location" --output tsv)
if [[ "${batch_account_location}" != ${synapse_workspace_location} ]]; then
    echo "Batch Account and Synapse Workspace are not in same location!!!"
    exit -1
fi

# Grant access to batch account for Managed Identities
python3 ${PRJ_ROOT}/deploy/batch_account.py \
    --env_code ${environment_code} \
    --target_batch_account_name ${target_batch_account_name} \
    --target_batch_account_resource_group_name ${target_batch_account_resource_group_name} \
    --batch_account_role ${target_batch_account_role}

# Deploy Batch Pool
target_batch_pool_mount_storage_account_key=$(az storage account keys list --resource-group ${target_batch_pool_mount_storage_account_resource_group_name} --account-name ${target_batch_pool_mount_storage_account_name} --query "[0].value" --output tsv)
target_batch_pool_mount_storage_account_file_url=$(az storage account show --resource-group ${target_batch_pool_mount_storage_account_resource_group_name} --name ${target_batch_pool_mount_storage_account_name}  --query "primaryEndpoints.file" --output tsv)

echo
echo "Deploying batch pool \"${target_batch_account_pool_name}\" on batch account \"${target_batch_account_name}\""
az deployment group create --resource-group "${environment_code}-orc-rg" \
    --template-file ${PRJ_ROOT}/deploy/infra/create_cpu_batch_account_pool.bicep \
    --parameters \
        environmentCode=${environment_code} \
        projectName="orc" \
        acrName="${environment_code}orcacr"\
        batchAccountName=${target_batch_account_name} \
        batchAccountResourceGroup=${target_batch_account_resource_group_name} \
        batchAccountCpuOnlyPoolName="${target_batch_account_pool_name}" \
        batchAccountPoolMountAccountName=${target_batch_pool_mount_storage_account_name} \
        batchAccountPoolMountAccountKey=${target_batch_pool_mount_storage_account_key} \
        batchAccountPoolMountFileUrl="${target_batch_pool_mount_storage_account_file_url}volume-a"

# Following steps will configure the resources as done in configure.sh script
# get synapse workspace and pool
source_synapse_pool=$(az synapse spark pool list \
    --workspace-name ${source_synapse_workspace_name} \
    --resource-group ${source_synapse_resource_group_name} \
    --query "[?tags.poolId && tags.poolId == 'default'].name" -o tsv)

if [[ -n $source_synapse_workspace_name ]] && [[ -n $source_synapse_resource_group_name ]] && [[ -n $source_synapse_pool ]]
then
    # upload synapse pool
    az synapse spark pool update \
        --name ${source_synapse_pool} \
        --workspace-name ${source_synapse_workspace_name} \
        --resource-group ${source_synapse_resource_group_name} \
        --library-requirements "${PRJ_ROOT}/deploy/environment.yml"
fi

# get batch account key
target_batch_account_key=$(az batch account keys list --name ${target_batch_account_name} --resource-group ${target_batch_account_resource_group_name} | jq ".primary")

if [[ -n $target_batch_account_name ]]
then
    az batch account login \
        --name ${target_batch_account_name} \
        --resource-group ${target_batch_account_resource_group_name}
    # create batch job for custom vision model
    az batch job create \
        --id ${target_batch_account_pool_name} \
        --pool-id ${target_batch_account_pool_name} \
        --account-name ${target_batch_account_name} \
        --account-key ${target_batch_account_key}
fi
source_synapse_storage_account=$(az storage account list --query "[?tags.store && tags.store == 'synapse'].name" -o tsv -g ${source_synapse_resource_group_name})
echo $source_synapse_storage_account

if [[ -n $source_synapse_storage_account ]]
then
    # create a container to upload the spark job python files
    az storage container create --name "spark-jobs" --account-name ${source_synapse_storage_account}
    # uploads the spark job python files
    az storage blob upload-batch --destination "spark-jobs" --account-name ${source_synapse_storage_account} --source "${PRJ_ROOT}/src/transforms/spark-jobs"
fi

# Following steps will package as done in package.sh script
target_batch_account_storage_account=$(az storage account list --query "[?tags.store && tags.store == 'batch'].name" -o tsv -g $target_batch_account_resource_group_name)
key_vault=$(az keyvault list --query "[?tags.usage && tags.usage == 'linkedService'].name" -o tsv -g $environment_code-pipeline-rg)
source_synapse_pool=$(az synapse spark pool list --workspace-name $source_synapse_workspace_name --resource-group $source_synapse_resource_group_name --query "[?tags.poolId && tags.poolId == 'default'].name" -o tsv -g $source_synapse_resource_group_name)

PACKAGING_SCRIPT="python3 ${PRJ_ROOT}/deploy/package.py --raw_storage_account_name $target_batch_pool_mount_storage_account_name \
    --synapse_storage_account_name $source_synapse_storage_account \
    --batch_storage_account_name $target_batch_account_storage_account_name \
    --batch_account $target_batch_account_name \
    --linked_key_vault $key_vault \
    --synapse_pool_name $source_synapse_pool \
    --location $batch_account_location \
    --pipeline_name $pipeline_name"

$PACKAGING_SCRIPT