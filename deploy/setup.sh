#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

ENV_CODE=${1:-${ENV_CODE}}
LOCATION=${2:-${LOCATION}}
PIPELINE_NAME=${3:-${PIPELINE_NAME}}
ENV_TAG=${4:-${ENV_TAG}}
PRE_PROVISIONED_BATCH_ACCOUNT_NAME=${5:-$PRE_PROVISIONED_BATCH_ACCOUNT_NAME}


set -ex

if [[ -z "$ENV_CODE" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi

if [[ -z "$LOCATION" ]]
  then
    echo "Location value not supplied"
    exit 1
fi

if [[ -z "$PRE_PROVISIONED_BATCH_ACCOUNT_NAME" ]]
  then
    DEPLOY_BATCH_ACCOUNT="true"
  else
    DEPLOY_BATCH_ACCOUNT="false"
fi

echo "Performing bicep template deployment"
if [[ -z "$ENV_TAG" ]]
    then
        DEPLOY_BATCH_ACCOUNT=${DEPLOY_BATCH_ACCOUNT} \
          ./deploy/install.sh "$ENV_CODE" "$LOCATION" 
    else
        DEPLOY_BATCH_ACCOUNT=${DEPLOY_BATCH_ACCOUNT} \
          ./deploy/install.sh "$ENV_CODE" "$LOCATION" "$ENV_TAG"
fi

if [[ "$DEPLOY_BATCH_ACCOUNT" == "false" ]]; then
  echo "Setting up the batch account!!!"
  ./test/use-pre-provisioned-batch-account.sh \
    "$ENV_CODE" \
    "$PRE_PROVISIONED_BATCH_ACCOUNT_NAME" \
    "$PIPELINE_NAME"
fi

echo "Performing configuration"
./deploy/configure.sh \
  "$ENV_CODE" \
  "$PRE_PROVISIONED_BATCH_ACCOUNT_NAME"

if [[ -z "$PIPELINE_NAME" ]]
  then
    echo "Skipping pipeline packaging"
  else
    echo "Performing pipeline packaging"
    ./deploy/package.sh \
      "$ENV_CODE" \
      "$PIPELINE_NAME" \
      "$PRE_PROVISIONED_BATCH_ACCOUNT_NAME"
fi
