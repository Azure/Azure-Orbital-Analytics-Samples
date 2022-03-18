#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# parameters
envCode=${envCode:-"${1}"}

NO_DELETE_DATA_RESOURCE_GROUP=${NO_DELETE_DATA_RESOURCE_GROUP:-"false"}
DATA_RESOURCE_GROUP=${DATA_RESOURCE_GROUP:-"${envCode}-data-rg"}

NO_DELETE_MONITORING_RESOURCE_GROUP=${NO_DELETE_MONITORING_RESOURCE_GROUP:-"false"}
MONITORING_RESOURCE_GROUP=${MONITORING_RESOURCE_GROUP:-"${envCode}-monitor-rg"}

NO_DELETE_NETWORKING_RESOURCE_GROUP=${NO_DELETE_NETWORKING_RESOURCE_GROUP:-"false"}
NETWORKING_RESOURCE_GROUP=${NETWORKING_RESOURCE_GROUP:-"${envCode}-network-rg"}

NO_DELETE_ORCHESTRATION_RESOURCE_GROUP=${NO_DELETE_ORCHESTRATION_RESOURCE_GROUP:-"false"}
ORCHESTRATION_RESOURCE_GROUP=${ORCHESTRATION_RESOURCE_GROUP:-"${envCode}-orc-rg"}

NO_DELETE_PIPELINE_RESOURCE_GROUP=${NO_DELETE_PIPELINE_RESOURCE_GROUP:-"false"}
PIPELINE_RESOURCE_GROUP=${PIPELINE_RESOURCE_GROUP:-"${envCode}-pipeline-rg"}

if [[ ${NO_DELETE_DATA_RESOURCE_GROUP} != "true" ]] && [[ ${NO_DELETE_DATA_RESOURCE_GROUP} == "false" ]]; then
    set -x
    az group delete --name ${DATA_RESOURCE_GROUP} --no-wait --yes
    set +x
fi

if [ "${NO_DELETE_MONITORING_RESOURCE_GROUP}" != "true" ] && [ "${NO_DELETE_MONITORING_RESOURCE_GROUP}" == "false" ]; then
    set -x
    az group delete --name ${MONITORING_RESOURCE_GROUP} --no-wait --yes
    set +x
fi

if [ "${NO_DELETE_NETWORKING_RESOURCE_GROUP}" != "true" ] && [ "${NO_DELETE_NETWORKING_RESOURCE_GROUP}" == "false" ]; then
    set -x
    az group delete --name ${NETWORKING_RESOURCE_GROUP} --no-wait --yes
    set +x
fi

if [ "${NO_DELETE_ORCHESTRATION_RESOURCE_GROUP}" != "true" ] && [ "${NO_DELETE_ORCHESTRATION_RESOURCE_GROUP}" == "false" ]; then
    set -x
    az group delete --name ${ORCHESTRATION_RESOURCE_GROUP} --no-wait --yes
    set +x
fi

if [ "${NO_DELETE_PIPELINE_RESOURCE_GROUP}" != "true" ] && [ "${NO_DELETE_PIPELINE_RESOURCE_GROUP}" == "false" ]; then
    set -x
    az group delete --name ${PIPELINE_RESOURCE_GROUP} --no-wait --yes
    set +x
fi

