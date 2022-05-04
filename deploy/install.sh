#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

set -x
PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"
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
SECURITY_ENABLED=${SECURITY_ENABLED:-false}
PREVENT_DATA_EXFILTRATION=${PREVENT_DATA_EXFILTRATION:-false}
# Check if vnet exists.
# This is needed since vnet template tries to delete existing private enpoints
# from the security enabled vnet when re-running its template.
VNET_ID=$(az network vnet show \
  -n "${envCode}-vnet" -g "${envCode}-network-rg" --query id -otsv \
  2>/dev/null || echo '')
if [[ -z "${VNET_ID}" ]]
then
  CREATE_VNET_SUBNETS=true
else
  CREATE_VNET_SUBNETS=false
fi

DEPLOYMENT_SCRIPT="az deployment sub create -l $location -n $deploymentName \
    -f ./deploy/infra/main.bicep \
    -p \
    location=$location \
    environmentCode=$envCode \
    environment=$envTag \
    createVnetSubnets=$CREATE_VNET_SUBNETS \
    securityEnabled=$SECURITY_ENABLED \
    preventDataExfiltration=$PREVENT_DATA_EXFILTRATION"
$DEPLOYMENT_SCRIPT

if [[ $SECURITY_ENABLED ]]
then
  # make sure to add synapse managed private endpoints before adding
  # private endpoints for synapse to custom vnet
  ${PRJ_ROOT}/deploy/addManagedPE.sh $envCode

  # after adding managed vnet, now we are adding private endpoints to
  # custom vnet using bicep
  DEPLOYMENT_SCRIPT="az deployment sub create -l $location \
    -n $deploymentName-security-addon \
    -f ${PRJ_ROOT}/deploy/infra/security-addons.bicep \
    -p  \
      environmentCode=$envCode \
      location=$location"
  $DEPLOYMENT_SCRIPT
fi

set +x