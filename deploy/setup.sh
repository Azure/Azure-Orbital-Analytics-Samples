#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

ENVCODE=$ENVCODE
LOCATION=$LOCATION
PIPELINE_NAME=$PIPELINE_NAME
ENVTAG=$ENVTAG


set -x

if [[ -z "$ENVCODE" ]]
  then
    echo "Environment Code value not supplied"
    exit 1
fi

if [[ -z "$LOCATION" ]]
  then
    echo "Location value not supplied"
    exit 1
fi

echo "Performing bicep template deployment"
if [[ -z "$ENVTAG" ]]
    then
        ./deploy/install.sh "$ENVCODE" "$LOCATION"
    else
        ./deploy/install.sh "$ENVCODE" "$LOCATION" "$ENVTAG"
fi

echo "Performing configuration"
./deploy/configure.sh "$ENVCODE"

if [[ -z "$PIPELINE_NAME" ]]
  then
    echo "Skipping pipeline packaging"
  else
    echo "Performing pipeline packaging"
    ./deploy/package.sh "$ENVCODE" "$PIPELINE_NAME"
fi

set +x