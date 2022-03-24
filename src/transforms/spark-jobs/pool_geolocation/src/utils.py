# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import json
import logging
import logging.config
import os
from jsonschema import validate
from pathlib import Path
from typing import Union

logger = logging.getLogger(__name__)

##########################################################################################
# files & download
##########################################################################################


schema_str = '{'\
    '"title": "config",' \
    '"type": "object",' \
    '"properties": {' \
        '"probability_cutoff": {' \
            '"type": "number"' \
        '},' \
        '"height": {' \
            '"type": "number"' \
        '},' \
        '"width": {' \
            '"type": "number"' \
        '},' \
        '"geometry": {' \
            '"$ref": "#/$defs/geometry"' \
        '}' \
    '},' \
    '"required": [' \
        '"width",' \
        '"height"' \
    ']' \
'}'

def parse_config(config_path: Path, default_config: dict):
    config = default_config

    logger.debug(f"default config options are {config}")

    logger.debug(f"reading config file {config_path}")
    schema = json.loads(schema_str)

    # load config file from path
    with open(config_path, "r") as f:
        config_file = json.load(f)

    logger.debug(f"provided configuration is {config_file}")
    logger.debug(f"validating provided config")

    # validate the config file with the schema
    validate(config_file, schema)

    config.update(config_file)
    logger.info(f"using configuration {config}")

    return config


##########################################################################################
# logging
##########################################################################################


def init_logger(
    name: str,
    level: Union[int, str],
    format: str = "%(asctime)s:[%(levelname)s]:%(name)s:%(message)s",
):
    # enable and configure logging
    logger = logging.getLogger(name)
    logger.setLevel(level)
    ch = logging.StreamHandler()
    ch.setLevel(level)
    ch.setFormatter(logging.Formatter(format))
    logger.addHandler(ch)

    return logger