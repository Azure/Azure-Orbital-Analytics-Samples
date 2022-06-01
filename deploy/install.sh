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
envCode=${1:-${envCode}}
location=${2:-${location}}
deploymentName=${3:-${deploymentName:-"${envTag}-deploy"}}
envTag=${4:-${envTag:-"synapse-${envCode}"}}
deployBatchAccount=${5:-${deployBatchAccount:-"true"}}

DEPLOYMENT_SCRIPT="az deployment sub create -l $location -n $deploymentName \
    -f ./deploy/infra/main.bicep \
    -p \
    location=$location \
    environmentCode=$envCode \
    environment=$envTag \
    deployBatchAccount=$deployBatchAccount"
$DEPLOYMENT_SCRIPT
set +x

