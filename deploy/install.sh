#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

set -x

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
envCode=${envCode:-"${1}"}
location=${location:-"${2}"}
envTag=${envTag:-"synapse-${envCode}"}
deploymentName=${3:-"${envTag}-deploy"}

DEPLOYMENT_SCRIPT="az deployment sub create -l $location -n $deploymentName \
    -f ./deploy/infra/main.bicep \
    -p \
    location=$location \
    environmentCode=$envCode \
    environment=$envTag"
$DEPLOYMENT_SCRIPT
set +x

