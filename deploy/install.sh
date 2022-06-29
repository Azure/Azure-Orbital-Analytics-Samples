#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

set -ex

if [[ -z "$1" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi

if [[ -z "$2" ]]
  then
    echo "Location value not supplied"
    exit 1
fi

# Setup parameters
ENV_CODE=${1:-${ENV_CODE}}
LOCATION=${2:-${LOCATION}}
ENV_TAG=${3:-${ENV_TAG:-"synapse-${ENV_CODE}"}}
DEPLOYMENT_NAME=${4:-${DEPLOYMENT_NAME:-"${ENV_TAG}-deploy"}}
DEPLOY_AI_MODEL_INFRA=${5:-${DEPLOY_AI_MODEL_INFRA:-"true"}}
AI_MODEL_INFRA_TYPE=${6:-${AI_MODEL_INFRA_TYPE:-"batch-account"}} # Currently supported values are aks and batch-account
DEPLOY_PGSQL=${7:-${DEPLOY_PGSQL:-"true"}}

if [[ "$AI_MODEL_INFRA_TYPE" != "batch-account" ]] && [[ "$AI_MODEL_INFRA_TYPE" != "aks" ]]; then
  echo "Invalid value for AI_MODEL_INFRA_TYPE! Supported values are 'aks' and 'batch-account'."
  exit 1
fi

DEPLOYMENT_SCRIPT="az deployment sub create -l $LOCATION -n $DEPLOYMENT_NAME \
    -f ./deploy/infra/main.bicep \
    -p \
    location=$LOCATION \
    environmentCode=$ENV_CODE \
    environment=$ENV_TAG \
    deployPgSQL=$DEPLOY_PGSQL \
    postgresAdminLoginPass=$POSTGRES_ADMIN_LOGIN_PASS \
    aiModelInfraType=$AI_MODEL_INFRA_TYPE \
    deployAiModelInfra=$DEPLOY_AI_MODEL_INFRA"
$DEPLOYMENT_SCRIPT
set +x

