#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

set -eu

# Setup parameters
envCode=${envCode:-"${1}"}
deploymentName=${2:-"synapse-${envCode}"}
location=${location:-"westus"}
envTag=${envTag:-"synapseBicep"}

DEPLOYMENT_SCRIPT="az deployment sub create -l $location -n $deploymentName \
    -f ./infra/main.bicep \
    -p \
    location=$location \
    environmentCode=$envCode \
    environment=$envTag"
set -x
$DEPLOYMENT_SCRIPT
