#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"
ENV_CODE=${1:-${ENV_CODE}}

AI_MODEL_INFRA_TYPE=${2:-${AI_MODEL_INFRA_TYPE:-"batch-account"}} # Currently supported values are aks and batch-account

AI_MODEL_INFRA_RESOURCE_NAME=${3:-${AI_MODEL_INFRA_RESOURCE_NAME}}
AI_MODEL_INFRA_RG_NAME=${4:-$AI_MODEL_INFRA_RG_NAME}

BATCH_ACCOUNT_POOL_NAME=${5:-${BATCH_ACCOUNT_POOL_NAME:-"${ENV_CODE}-data-cpu-pool"}}

SYNAPSE_WORKSPACE_RG=${6:-${SYNAPSE_WORKSPACE_RG:-"${ENV_CODE}-pipeline-rg"}}
SYNAPSE_WORKSPACE=${7:-${SYNAPSE_WORKSPACE:-"${ENV_CODE}-pipeline-syn-ws"}}
SYNAPSE_POOL=${8:-${SYNAPSE_POOL}}
SYNAPSE_STORAGE_ACCOUNT=${9:-${SYNAPSE_STORAGE_ACCOUNT}}


if [[ "$AI_MODEL_INFRA_TYPE" != "batch-account" ]] && [[ "$AI_MODEL_INFRA_TYPE" != "aks" ]]; then
  echo "Invalid value for AI_MODEL_INFRA_TYPE! Supported values are 'aks' and 'batch-account'."
  exit 1
fi

echo "configuration started ..."
set -ex

# get synapse workspace and pool
if [[ -z "$SYNAPSE_WORKSPACE" ]]; then
    SYNAPSE_WORKSPACE=$(az synapse workspace list --query "[?tags.workspaceId && tags.workspaceId == 'default'].name" -o tsv -g ${SYNAPSE_WORKSPACE_RG})
fi
if [[ -z "$SYNAPSE_POOL" ]]; then
    SYNAPSE_POOL=$(az synapse spark pool list --workspace-name ${SYNAPSE_WORKSPACE} --resource-group ${SYNAPSE_WORKSPACE_RG} --query "[?tags.poolId && tags.poolId == 'default'].name" -o tsv)
fi
if [[ -n $SYNAPSE_WORKSPACE ]] && [[ -n $SYNAPSE_WORKSPACE_RG ]] && [[ -n $SYNAPSE_POOL ]]; then
    # upload synapse pool 
    az synapse spark pool update --name ${SYNAPSE_POOL} --workspace-name ${SYNAPSE_WORKSPACE} --resource-group ${SYNAPSE_WORKSPACE_RG} --library-requirements "${PRJ_ROOT}/deploy/environment.yml"
fi

if [[ -z "$SYNAPSE_STORAGE_ACCOUNT" ]]; then
    SYNAPSE_STORAGE_ACCOUNT=$(az storage account list --query "[?tags.store && tags.store == 'synapse'].name" -o tsv -g ${SYNAPSE_WORKSPACE_RG})
fi

if [[ -n $SYNAPSE_STORAGE_ACCOUNT ]]; then
    # create a container to upload the spark job python files
    az storage container create --name "spark-jobs" --account-name ${SYNAPSE_STORAGE_ACCOUNT}
    # uploads the spark job python files
    az storage blob upload-batch --destination "spark-jobs" --account-name ${SYNAPSE_STORAGE_ACCOUNT} --source "${PRJ_ROOT}/src/transforms/spark-jobs" --overwrite
fi

if [[ "$AI_MODEL_INFRA_TYPE" == "batch-account" ]]; then
    echo "Selected AI model processing infra-type: Batch-Account!!!"

    BATCH_ACCOUNT_NAME=$AI_MODEL_INFRA_RESOURCE_NAME
    BATCH_ACCOUNT_RG_NAME=$AI_MODEL_INFRA_RG_NAME

    # get batch account
    if [[ -z "$BATCH_ACCOUNT_NAME" ]] && [[ -z "$BATCH_ACCOUNT_RG_NAME" ]]; then
        BATCH_ACCOUNT_RG_NAME="${ENV_CODE}-orc-rg"
    fi
    if [[ -z "$BATCH_ACCOUNT_NAME" ]]; then
        BATCH_ACCOUNT_NAME=$(az batch account list --query "[?tags.type && tags.type == 'batch'].name" -o tsv -g ${BATCH_ACCOUNT_RG_NAME})
    fi
    if [[ -z "$BATCH_ACCOUNT_RG_NAME" ]]; then
        BATCH_ACCOUNT_ID=$(az batch account list --query "[?name == '${BATCH_ACCOUNT_NAME}'].id" -o tsv)
        BATCH_ACCOUNT_RG_NAME=$(az resource show --ids ${BATCH_ACCOUNT_ID} --query resourceGroup -o tsv)
    fi
    BATCH_ACCOUNT_KEY=$(az batch account keys list --name ${BATCH_ACCOUNT_NAME} --resource-group ${BATCH_ACCOUNT_RG_NAME} | jq ".primary")
    if [[ -n $BATCH_ACCOUNT_NAME ]] && [[ -n $BATCH_ACCOUNT_KEY ]]
    then
        az batch account login --name ${BATCH_ACCOUNT_NAME} --resource-group ${BATCH_ACCOUNT_RG_NAME}
        # create batch job for custom vision model
        az batch job create --id ${BATCH_ACCOUNT_POOL_NAME} --pool-id ${BATCH_ACCOUNT_POOL_NAME} --account-name ${BATCH_ACCOUNT_NAME} --account-key ${BATCH_ACCOUNT_KEY} || true
    fi
elif [[ "$AI_MODEL_INFRA_TYPE" == "aks" ]]; then
    echo "Selected AI model processing infra-type: AKS!!!"
    DATA_RESOURCE_GROUP="${ENV_CODE}-data-rg"
    AKS_NAMESPACE=vision
    PV_SUFFIX=fileshare
    PV_NAME="${ENV_CODE}-${AKS_NAMESPACE}-${PV_SUFFIX}"

    RAW_STORAGE_ACCT=$(az storage account list --query "[?tags.store && tags.store == 'raw'].name" -o tsv -g $DATA_RESOURCE_GROUP)
    RAW_STORAGE_KEY=$(az storage account keys list --resource-group $DATA_RESOURCE_GROUP --account-name $RAW_STORAGE_ACCT --query "[0].value" -o tsv)
    VISION_FILE_SHARE_NAME=$(az storage share list --account-key $RAW_STORAGE_KEY --account-name $RAW_STORAGE_ACCT --query "[].name" -o tsv)

    AKS_CLUSTER_NAME=$(az aks list -g ${ENV_CODE}-orc-rg --query "[?tags.type && tags.type == 'k8s'].name" -otsv)
    while [[ ${AKS_CLUSTER_NAME} == '' ]];
    do
        sleep 60
        AKS_CLUSTER_NAME=$(az aks list -g ${ENV_CODE}-orc-rg --query "[?tags.type && tags.type == 'k8s'].name" -otsv)
    done
    # force to provision aks-command namespace
    az aks command invoke -g ${ENV_CODE}-orc-rg -n ${AKS_CLUSTER_NAME} -c "kubectl get ns"
    az aks get-credentials --resource-group ${ENV_CODE}-orc-rg --name ${AKS_CLUSTER_NAME} --context ${AKS_CLUSTER_NAME} --overwrite-existing
    kubectl config set-context ${AKS_CLUSTER_NAME}

    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $AKS_NAMESPACE
EOF

    cat <<EOF | kubectl -n $AKS_NAMESPACE apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: azure-secret
  namespace: $AKS_NAMESPACE
type: Opaque
stringData:
  azurestorageaccountname: ${RAW_STORAGE_ACCT}
  azurestorageaccountkey: ${RAW_STORAGE_KEY}
EOF

    cat <<EOF | kubectl -n $AKS_NAMESPACE apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${PV_NAME}
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: azurefile-csi
  csi:
    driver: file.csi.azure.com
    readOnly: false
    volumeHandle: ${PV_NAME}
    volumeAttributes:
      resourceGroup: ${DATA_RESOURCE_GROUP}
      shareName: ${VISION_FILE_SHARE_NAME}
    nodeStageSecretRef:
      name: azure-secret
      namespace: ${AKS_NAMESPACE}
  mountOptions:
    - dir_mode=0777
    - file_mode=0777
    - uid=0
    - gid=0
    - mfsymlinks
    - cache=strict
    - nosharesock
    - nobrl
EOF

    cat << EOF | kubectl -n $AKS_NAMESPACE apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PV_NAME}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azurefile-csi
  volumeName: ${PV_NAME}
  resources:
    requests:
      storage: 5Gi
EOF
fi # end of "$AI_MODEL_INFRA_TYPE" == "aks"

echo "configuration completed!"
