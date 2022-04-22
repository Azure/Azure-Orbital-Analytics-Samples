#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"

environment_code=${1}

target_batch_account_name=${2}
target_batch_account_resource_group_name=${3}

target_batch_pool_mount_storage_account_name=${4}
target_batch_pool_mount_storage_account_resource_group_name=${5}

source_synapse_workspace_name=${6:-"${environment_code}-pipeline-syn-ws"}
source_synapse_resource_group_name=${7:-"${environment_code}-pipeline-rg"}
source_batch_account_query_umi_name=${8:-"${environment_code}-orc-umi"}
source_batch_account_query_umi_resource_group_name=${9:-"${environment_code}-orc-rg"}
target_batch_account_pool_name=${10:-"${environment_code}-data-cpu-pool"}
batch_account_role=${11:-"Contributor"}

set -e

# Verify that infrastructure and batch account are in same location
batch_account_location=$(az batch account show  --name ${target_batch_account_name} --resource-group ${target_batch_account_resource_group_name} --query "location" --output tsv)
syanpse_workspace_location=$(az synapse workspace show --name ${source_synapse_workspace_name} --resource-group ${source_synapse_resource_group_name} --query "location" --output tsv)
if [[ "${batch_account_location}" != ${syanpse_workspace_location} ]]; then
    echo "Batch Account and Syanpse Workspace are not in same location!!!"
    exit -1
fi

# Grant access to batch account for Managed Identities
python3 ${PRJ_ROOT}/deploy/batch_account.py \
    --source_synapse_workspace_name ${source_synapse_workspace_name} \
    --source_synapse_workspace_resource_group_name ${source_synapse_resource_group_name} \
    --source_batch_account_query_umi_name ${source_batch_account_query_umi_name} \
    --source_batch_account_query_umi_resource_group_name ${source_batch_account_query_umi_resource_group_name} \
    --target_batch_account_name ${target_batch_account_name} \
    --target_batch_account_resource_group_name ${target_batch_account_resource_group_name} \
    --batch_account_role ${batch_account_role}

# Deploy Batch Pool
target_batch_pool_mount_storage_account_key=$(az storage account keys list --resource-group ${target_batch_pool_mount_storage_account_resource_group_name} --account-name ${target_batch_pool_mount_storage_account_name} --query "[0].value" --output tsv)
target_batch_pool_mount_storage_account_file_url=$(az storage account show --resource-group ${target_batch_pool_mount_storage_account_resource_group_name} --name ${target_batch_pool_mount_storage_account_name}  --query "primaryEndpoints.file" --output tsv)

echo
echo "Deploying batch pool \"${target_batch_account_pool_name}\" on batch account \"${target_batch_account_name}\""
az deployment group create --resource-group ${source_batch_account_query_umi_resource_group_name} \
    --template-file ${PRJ_ROOT}/deploy/infra/create_cpu_batch_account_pool.bicep \
    --parameters \
        environmentCode=${environment_code} \
        projectName="${environment_code}-orc" \
        batchAccountName=${target_batch_account_name} \
        batchAccountResourceGroup=${target_batch_account_resource_group_name} \
        batchAccountPoolCheckUamiName=${source_batch_account_query_umi_name} \
        batchAccountLocation=${batch_account_location} \
        batchAccountCpuOnlyPoolName="${target_batch_account_pool_name}" \
        batchAccountPoolMountAccountName=${target_batch_pool_mount_storage_account_name} \
        batchAccountPoolMountAccountKey=${target_batch_pool_mount_storage_account_key} \
        batchAccountPoolMountFileUrl="${target_batch_pool_mount_storage_account_file_url}volume-a"
