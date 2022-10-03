#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

ENV_CODE=${1:-${ENV_CODE}}
LOCATION=${2:-${LOCATION}}
PIPELINE_NAME=${3:-${PIPELINE_NAME:-"custom-vision-model"}}
ENV_TAG=${4:-${ENV_TAG}}
PRE_PROVISIONED_AI_MODEL_INFRA_NAME=${5:-$PRE_PROVISIONED_AI_MODEL_INFRA_NAME}
AI_MODEL_INFRA_TYPE=${6:-${AI_MODEL_INFRA_TYPE:-"batch-account"}} # Currently supported values are aks and batch-account
DEPLOY_PGSQL=${7:-${DEPLOY_PGSQL:-"true"}}

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

if [[ "$AI_MODEL_INFRA_TYPE" != "batch-account" ]] && [[ "$AI_MODEL_INFRA_TYPE" != "aks" ]]; then
  echo "Invalid value for AI_MODEL_INFRA_TYPE! Supported values are 'aks' and 'batch-account'."
  exit 1
fi

if [[ -z "$PRE_PROVISIONED_AI_MODEL_INFRA_NAME" ]]
  then
    DEPLOY_AI_MODEL_INFRA="true"
  else
    DEPLOY_AI_MODEL_INFRA="false"
fi

echo "Performing bicep template deployment"
if [[ -z "$ENV_TAG" ]]
  then
    DEPLOY_PGSQL=${DEPLOY_PGSQL} \
    DEPLOY_AI_MODEL_INFRA=${DEPLOY_AI_MODEL_INFRA} \
    AI_MODEL_INFRA_TYPE=${AI_MODEL_INFRA_TYPE} \
      ./deploy/install.sh "$ENV_CODE" "$LOCATION" 
  else
    DEPLOY_PGSQL=${DEPLOY_PGSQL} \
    DEPLOY_AI_MODEL_INFRA=${DEPLOY_AI_MODEL_INFRA} \
    AI_MODEL_INFRA_TYPE=${AI_MODEL_INFRA_TYPE} \
      ./deploy/install.sh "$ENV_CODE" "$LOCATION" "$ENV_TAG"
fi

if [[ "${DEPLOY_AI_MODEL_INFRA}" == "false" ]] && [[ "${AI_MODEL_INFRA_TYPE}" == "batch-account" ]]; then
  echo "Setting up the batch account!!!"
  ./test/use-pre-provisioned-batch-account.sh \
    "$ENV_CODE" \
    "$PRE_PROVISIONED_AI_MODEL_INFRA_NAME" \
    "$PIPELINE_NAME"
fi

echo "Performing configuration"
./deploy/configure.sh \
  "$ENV_CODE" \
  "$AI_MODEL_INFRA_TYPE" \
  "$PRE_PROVISIONED_AI_MODEL_INFRA_NAME" 

if [[ -z "$PIPELINE_NAME" ]]
  then
    echo "Skipping pipeline packaging"
  else
    echo "Performing pipeline packaging"
    DEPLOY_PGSQL=${DEPLOY_PGSQL} \
      ./deploy/package.sh \
      "$ENV_CODE" \
      "$PIPELINE_NAME" \
      "$AI_MODEL_INFRA_TYPE" \
      "$PRE_PROVISIONED_AI_MODEL_INFRA_NAME"
fi
