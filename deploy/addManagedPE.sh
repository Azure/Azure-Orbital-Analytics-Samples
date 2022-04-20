#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

set +x
if [[ -z "$1" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi
ENVCODE=$1

create_synapase_managed_private_endpoint() {
    local tmpfile=$(mktemp)
    local synpaseWorkspace=$1
    local peName=$2
    local groupId=$3
    local privateLinkResourceId=$4

    echo "creating MPE if not exist for $peName"
    # check if peName exists
    local checkPeExists=$(az synapse managed-private-endpoints show \
     --pe-name $peName -otsv --query "id" --workspace-name $synpaseWorkspace 2>/dev/null || echo '')
    
    if [[ -z $checkPeExists ]];
    then
        jq -n -r \
        --arg groupId "$groupId" \
        --arg privateLinkResourceId "$privateLinkResourceId" \
        '{groupId:$groupId, privateLinkResourceId:$privateLinkResourceId}' > $tmpfile

        az synapse managed-private-endpoints create \
            --file @$tmpfile \
            --pe-name $peName \
            --workspace-name $1

        sleep 60
        local provisioningState=$(az synapse managed-private-endpoints show --pe-name $peName \
            --workspace-name $synpaseWorkspace -o tsv --query "properties.provisioningState")
        while [[ $provisioningState != "Succeeded" ]];
        do
            sleep 10
            provisioningState=$(az synapse managed-private-endpoints show --pe-name $peName \
            --workspace-name $synpaseWorkspace -o tsv --query "properties.provisioningState")
            echo "provisioningState of $peName: $provisioningState"
        done
    fi    
}

approve_synapase_managed_private_endpoint() {
    local resourceGroup=$1
    local resourceName=$2
    local resourceType=$3

    local PE_CONNECTION=$(az network private-endpoint-connection list -g $resourceGroup -n $resourceName \
                    --type $resourceType  --query "[0]" -ojson 2>/dev/null || echo '')
    if [[ -n $PE_CONNECTION ]];
    then
        local PE_CONNECTION_ID=$(echo $PE_CONNECTION | jq -r '.id')
        local PE_CONNECTION_APPROVAL_STATUS=$(echo $PE_CONNECTION | jq -r '.properties.privateLinkServiceConnectionState.status')

        if [[ $PE_CONNECTION_APPROVAL_STATUS != "Approved" ]];
        then
            az network private-endpoint-connection approve \
                --id $PE_CONNECTION_ID --description "Approved by script"
            echo "$PE_CONNECTION_ID got approved"
        fi
    fi
}

# wait for SYNAPSE_STORAGE_ACCT showing up in azcli and approve its managed private endpoint first.
SYNAPSE_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'synapse'].name" -o tsv -g $ENVCODE-pipeline-rg)
while [[ -z $SYNAPSE_STORAGE_ACCT ]];
do
   sleep 30
   SYNAPSE_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'synapse'].name" -o tsv -g $ENVCODE-pipeline-rg)
done
approve_synapase_managed_private_endpoint $ENVCODE-pipeline-rg $SYNAPSE_STORAGE_ACCT "Microsoft.Storage/storageAccounts"

# Create Managed Private Endpoints (PE) if not exist
PIPELINE_KV=$(az keyvault list --query "[?tags.usage && tags.usage == 'linkedService']" -ojson -g $ENVCODE-pipeline-rg)
while [[ $PIPELINE_KV == '[]' ]];
do
   sleep 30
   PIPELINE_KV=$(az keyvault list --query "[?tags.usage && tags.usage == 'linkedService']" -ojson -g $ENVCODE-pipeline-rg)
done
PIPELINE_KV_NAME=$(echo $PIPELINE_KV | jq -r '.[0].name')
PIPELINE_KV_ID=$(echo $PIPELINE_KV | jq -r '.[0].id')
create_synapase_managed_private_endpoint "$ENVCODE-pipeline-syn-ws" "$ENVCODE-mpe-pipeline-kv" "vault" "$PIPELINE_KV_ID"

DATA_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'raw']" -ojson -g $ENVCODE-data-rg)
while [[ $DATA_STORAGE_ACCT == '[]' ]]
do
   sleep 30
   DATA_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'raw']" -ojson -g $ENVCODE-data-rg)
done
DATA_STORAGE_ACCT_NAME=$(echo $DATA_STORAGE_ACCT | jq -r '.[0].name')
DATA_STORAGE_ACCT_ID=$(echo $DATA_STORAGE_ACCT | jq -r '.[0].id')
create_synapase_managed_private_endpoint "$ENVCODE-pipeline-syn-ws" "$ENVCODE-mpe-data-raw" "dfs" "$DATA_STORAGE_ACCT_ID"

DATA_KV=$(az keyvault list --query "[?tags.usage && tags.usage == 'general']" -ojson -g $ENVCODE-data-rg)
while [[ $DATA_KV == '[]' ]];
do
    sleep 30
    DATA_KV=$(az keyvault list --query "[?tags.usage && tags.usage == 'general']" -ojson -g $ENVCODE-data-rg)
done
DATA_KV_NAME=$(echo $DATA_KV | jq -r '.[0].name')
DATA_KV_ID=$(echo $DATA_KV | jq -r '.[0].id')
create_synapase_managed_private_endpoint "$ENVCODE-pipeline-syn-ws" "$ENVCODE-mpe-data-kv" "vault" "$DATA_KV_ID"


# Approve remaining Managed Private Endpoints (PE)
approve_synapase_managed_private_endpoint $ENVCODE-pipeline-rg $PIPELINE_KV_NAME "Microsoft.Keyvault/vaults"
approve_synapase_managed_private_endpoint $ENVCODE-data-rg $DATA_STORAGE_ACCT_NAME "Microsoft.Storage/storageAccounts"
approve_synapase_managed_private_endpoint $ENVCODE-data-rg $DATA_KV_NAME "Microsoft.Keyvault/vaults"
