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
DEPLOY_BATCH_ACCOUNT=${5:-${DEPLOY_BATCH_ACCOUNT:-"true"}}
DEPLOY_PGSQL=${6:-${DEPLOY_PGSQL:-"true"}}

DEPLOYMENT_SCRIPT="az deployment sub create -l $LOCATION -n $DEPLOYMENT_NAME \
    -f ./deploy/infra/main.bicep \
    -p \
    location=$LOCATION \
    environmentCode=$ENV_CODE \
    environment=$ENV_TAG \
    deployBatchAccount=$DEPLOY_BATCH_ACCOUNT \
    deployPgSQL=$DEPLOY_PGSQL \
    postgresAdminLoginPass=$POSTGRES_ADMIN_LOGIN_PASS"
$DEPLOYMENT_SCRIPT
set +x

