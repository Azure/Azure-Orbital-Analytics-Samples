#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# This script automates the following activities & should be run prior to
# executing the pipeline template from Synapse gallery.
#       * Create storage container under "<envcode>-data-rg" resource group
#       * Copy the sample TIF into the newly created storage container
#       * Copy the configurations required for Object Detection

set -e

ENV_CODE=${1:-${ENV_CODE}}

if [[ -z "$ENV_CODE" ]]
then
    echo "Missing Environment Code"
    exit 1
fi

# Default name for the container
container_name="${ENV_CODE}-test-container"

# Retrieve the respective values for the environment variables
AZURE_STORAGE_ACCOUNT=$(az storage account list --resource-group "${ENV_CODE}-data-rg" --query [0].name -o tsv)
AZURE_STORAGE_KEY=$(az storage account keys list --account-name "$AZURE_STORAGE_ACCOUNT" --query [0].value -o tsv)
AZURE_STORAGE_AUTH_MODE=key

export AZURE_STORAGE_ACCOUNT
export AZURE_STORAGE_KEY
export AZURE_STORAGE_AUTH_MODE

# Declare an associated array for dictionaries
declare -A array

key1='sample_4326.tif'
value1='https://raw.githubusercontent.com/Azure/Azure-Orbital-Analytics-Samples/main/deploy/sample_data/sample_4326.tif'

key2='custom_vision_object_detection.json'
value2='https://raw.githubusercontent.com/Azure/Azure-Orbital-Analytics-Samples/main/src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json'

key3='config.json'
value3='https://raw.githubusercontent.com/Azure/Azure-Orbital-Analytics-Samples/main/src/aimodels/custom_vision_object_detection_offline/config/config.json'

array["raw/$key1"]="$value1"
array["config/$key2"]="$value2"
array["config/$key3"]="$value3"

echo "Creating storage container $container_name.."
if ! az storage container create --name "$container_name" --fail-on-exist;
then
    echo "Failed during storage container creation"
    exit 1
else
    echo "Container $container_name created successfully"
fi

for key in "${!array[@]}"; do
    echo "Copying $key from source"
    az storage blob copy start --destination-blob $key --destination-container "$container_name" --source-uri "${array[$key]}"
done
