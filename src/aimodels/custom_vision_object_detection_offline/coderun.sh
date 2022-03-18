#! /bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

export APP_INPUT_DIR="examples/in"
export APP_OUTPUT_DIR="examples/out"
export APP_CONFIG_DIR="config.mine.json"

# mkdir -p ${APP_INPUT_DIR} ${APP_OUTPUT_DIR}

python -m cProfile src/custom_vision.py > perf.txt
