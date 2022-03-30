#!/bin/bash

base=$(pwd)

docker run -u 1000:1000 \
           -v "$base/examples/in/:/data/in" \
           -v "$base/examples/out/:/data/out" \
           -v "$base/config.mine.json:/data/config.json" \
           custom_vision_offline