#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

ENVCODE=$1
LOCATION=$2
PIPELINE_NAME=$3
ENVTAG=$4


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

if [[ -z "$3" ]]
  then
    echo "Pipeline name to package"
    exit 1
fi


echo "Performing bicep template deployment"
if [[ -z "$4" ]]
    then
        ./install.sh $1 $2
    else
        ./install.sh $1 $2 $4
fi

echo "Performing configuration"
./configure.sh $1

echo "Performing pipeline packaging"
./package.sh $1 $3

set +x