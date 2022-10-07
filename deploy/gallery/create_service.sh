#! /usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# This script creates the required linked service & the spark 
# job definition on the Synapse workspace and should be run 
# prior to executing the pipeline template from Synapse gallery.

set -e

ENV_CODE=${1:-${ENV_CODE}}

if [[ -z ${ENV_CODE} ]]
  then
    echo "Missing Environment Code"
    exit 1
fi

base_dir="$(cd "$(dirname "$0")/../../" && pwd)"

# Uncompress the custom vision model package
if ! unzip "${base_dir}"/custom-vision-model.zip -d "${base_dir}"/custom-vision-model-"${ENV_CODE}";
then
    echo "Unzip failed please check .."
    exit 1
else
    echo "Unzip completed successfully"
fi

pkg_dir=${base_dir}/custom-vision-model-${ENV_CODE}

# The following one's are created on the Synapse workspace to run 
# the pipeline template in Synapse gallery.
services=("linked-service" "spark-job-definition")

for item in "${services[@]}"
do
    if [[ $item == "linked-service" ]]
    then
       folder_name="linkedService"
    else
       folder_name="sparkJobDefinition"
    fi

    for file in "${pkg_dir}/${folder_name}"/*.json
    do
        full_name="${file}"
        file_name=$(basename -s .json "${file}")
        # Edit the json file format to work with Synapse CLI commands
        if [[ $folder_name == "sparkJobDefinition" ]]
        then
            contents="$(jq '.properties' "${full_name}")" && echo -E "${contents}" > "${full_name}"
            sleep 5
        fi
        # Create the linked services and spark job definition on Synapse workspace
        echo "Creating ${item} please wait.."
        SYNAPSE_WORKSPACE_NAME=$(az synapse workspace list --query "[?tags.workspaceId && tags.workspaceId == 'default'].name" -o tsv -g "${ENV_CODE}-pipeline-rg")
        az synapse "${item}" create --workspace-name "${SYNAPSE_WORKSPACE_NAME}" \
            --name "${file_name}" --file @"${full_name}"
    done
done
