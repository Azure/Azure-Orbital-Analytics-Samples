#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

PRJ_ROOT="$(cd `dirname "${BASH_SOURCE}"`/..; pwd)"

ENV_CODE=${1:-${ENV_CODE}}
PIPELINE_RUN_ID=${2:-${PIPELINE_RUN_ID}}
SYNAPSE_WORKSPACE_NAME=${3:-${SYNAPSE_WORKSPACE_NAME}}
SLEEP_TIME_BETWEEN_CHECK_STATUS=${4:-${SLEEP_TIME_BETWEEN_CHECK_STATUS:-300}}
SYNAPSE_WORKSPACE_RG=${5:-${SYNAPSE_WORKSPACE_RG:-"${ENV_CODE}-pipeline-rg"}}

if [[ -z "$ENV_CODE" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi

if [[ -z "$SYNAPSE_WORKSPACE_NAME" ]]; then
    SYNAPSE_WORKSPACE_NAME=$(az synapse workspace list --query "[?tags.workspaceId && tags.workspaceId == 'default'].name" -o tsv -g ${SYNAPSE_WORKSPACE_RG})
fi
if [[ -z "$SLEEP_TIME_BETWEEN_CHECK_STATUS" ]]; then
    SLEEP_TIME_BETWEEN_CHECK_STATUS=60
fi

set -ex

PIPELINE_RUN_STATUS=$(az synapse pipeline-run show --workspace-name ${SYNAPSE_WORKSPACE_NAME} --run-id ${PIPELINE_RUN_ID} --query status --output tsv)
while [[ "$PIPELINE_RUN_STATUS" != "Succeeded" ]] && [[ "$PIPELINE_RUN_STATUS" != "Failed" ]]
do
    echo "Pipeline status: ${PIPELINE_RUN_STATUS}"
    echo "Waiting for ${SLEEP_TIME_BETWEEN_CHECK_STATUS} seconds ...."
    sleep ${SLEEP_TIME_BETWEEN_CHECK_STATUS}
    PIPELINE_RUN_STATUS=$(az synapse pipeline-run show --workspace-name ${SYNAPSE_WORKSPACE_NAME} --run-id ${PIPELINE_RUN_ID} --query status --output tsv)
done

echo "Pipeline finished with status: ${PIPELINE_RUN_STATUS}"

if [[ "$PIPELINE_RUN_STATUS" == "Succeeded" ]]; then
    exit 0
fi
exit 1