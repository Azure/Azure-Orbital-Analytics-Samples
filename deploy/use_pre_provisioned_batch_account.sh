#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"

environment_code=${1}

target_batch_account_name=${2}
target_batch_account_resource_group_name=${3}

target_batch_pool_mount_storage_account_name=${4}
target_batch_pool_mount_storage_account_resource_group_name=${5}

target_batch_account_pool_name=${10:-"${environment_code}-data-cpu-pool"}
batch_account_role=${11:-"Contributor"}

set -e

# Verify that infrastructure and batch account are in same location
batch_account_location=$(az batch account show  --name ${target_batch_account_name} --resource-group ${target_batch_account_resource_group_name} --query "location" --output tsv)
synapse_workspace_location=$(az synapse workspace show --name ${source_synapse_workspace_name} --resource-group ${source_synapse_resource_group_name} --query "location" --output tsv)
if [[ "${batch_account_location}" != ${synapse_workspace_location} ]]; then
    echo "Batch Account and Synapse Workspace are not in same location!!!"
    exit -1
fi

# Grant access to batch account for Managed Identities
python3 ${PRJ_ROOT}/deploy/batch_account.py \
    --env_code ${env_code} \
    --target_batch_account_name ${target_batch_account_name} \
    --target_batch_account_resource_group_name ${target_batch_account_resource_group_name} \
    --batch_account_role ${batch_account_role}

# Deploy Batch Pool
target_batch_pool_mount_storage_account_key=$(az storage account keys list --resource-group ${target_batch_pool_mount_storage_account_resource_group_name} --account-name ${target_batch_pool_mount_storage_account_name} --query "[0].value" --output tsv)
target_batch_pool_mount_storage_account_file_url=$(az storage account show --resource-group ${target_batch_pool_mount_storage_account_resource_group_name} --name ${target_batch_pool_mount_storage_account_name}  --query "primaryEndpoints.file" --output tsv)

echo
echo "Deploying batch pool \"${target_batch_account_pool_name}\" on batch account \"${target_batch_account_name}\""
az deployment group create --resource-group "${environment_code}-orc-rg" \
    --template-file ${PRJ_ROOT}/deploy/infra/create_cpu_batch_account_pool.bicep \
    --parameters \
        environmentCode=${environment_code} \
        projectName="${environment_code}-orc" \
        batchAccountName=${target_batch_account_name} \
        batchAccountResourceGroup=${target_batch_account_resource_group_name} \
        batchAccountCpuOnlyPoolName="${target_batch_account_pool_name}" \
        batchAccountPoolMountAccountName=${target_batch_pool_mount_storage_account_name} \
        batchAccountPoolMountAccountKey=${target_batch_pool_mount_storage_account_key} \
        batchAccountPoolMountFileUrl="${target_batch_pool_mount_storage_account_file_url}volume-a"
