# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os, argparse, sys
import json
import glob
from osgeo import gdal
import logging
from notebookutils import mssparkutils

from pathlib import Path

# collect args
parser = argparse.ArgumentParser(description='Arguments required to run convert to png function')
parser.add_argument('--storage_account_name', type=str, required=True, help='Name of the storage account name where the input data resides')
parser.add_argument('--storage_account_key', required=True, help='Key to the storage account where the input data resides')
parser.add_argument('--storage_container', type=str, required=True, help='Container under which the input data resides')
parser.add_argument('--src_folder_name', default=None, required=True, help='Folder containing the source file for cropping')
parser.add_argument('--config_file_name', required=True, help='Config file name')

# parse Args
args = parser.parse_args()

def convert_directory(
    input_path,
    output_path,
    config_file,
    logger,
    default_options={"format": "png", "metadata": False},
):
    gdal.UseExceptions()

    logger.info("looking for config file: %s", config_file)

    translate_options_dict = default_options
    logger.debug("default config options: %s", translate_options_dict)

    try:
        # read config file
        with open(config_file, "r") as config:
            config_file_dict = json.load(config)
            logger.debug("read in %s", config_file_dict)
            translate_options_dict.update(config_file_dict)
    except Exception as e:
        # config file is missing or there is issue reading the config file
        logger.error("error reading config file %s", e)
        sys.exit(1)

    logger.info("using config options: %s", translate_options_dict)

    keep_metadata = translate_options_dict.pop("metadata")

    opt = gdal.TranslateOptions(**translate_options_dict)

    logger.debug("looking for input files in %s", input_path)
    for in_file in os.scandir(input_path):
        in_name = in_file.name
        logger.info("ingesting file %s", in_file.path)
        # ! this is a landmine; will error for files w/o extension but with '.', and for formats with spaces
        out_name = os.path.splitext(in_name)[0] + "." + translate_options_dict["format"]
        out_path = os.path.join(output_path, out_name)
        try:
            # call gdal to convert the file format
            gdal.Translate(out_path, in_file.path, options=opt)
        except Exception as e:
            logger.error("gdal error: %s", e)
            sys.exit(1)
        else:
            logger.info("successfully translated %s", out_path)

    # check to see if we need to carry over the geo-coordinates / metadata file?
    if not keep_metadata:
        xml_glob = os.path.join(output_path, "*.aux.xml")
        logger.debug(f"deleting metadata files that match {xml_glob}")
        for xml_file in glob.glob(xml_glob):
            logger.debug(f"deleting metadata file f{xml_file}")
            os.remove(xml_file)


if __name__ == "__main__":

    # enable logging
    logging.basicConfig(
        level=logging.DEBUG, format="%(asctime)s:%(levelname)s:%(name)s:%(message)s"
    )
    logger = logging.getLogger("image_convert")

    # unmount any previously mounted storage account container
    mssparkutils.fs.unmount(f'/{args.storage_container}') 

    mssparkutils.fs.mount( 
        f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net', 
        f'/{args.storage_container}', 
        {"accountKey": args.storage_account_key} 
    )

    jobId = mssparkutils.env.getJobId()

    input_path = f'/synfs/{jobId}/{args.storage_container}/{args.src_folder_name}'
    config_path = f'/synfs/{jobId}/{args.storage_container}/config/{args.config_file_name}'
    output_path = f'/synfs/{jobId}/{args.storage_container}'

    logger.debug(f"input data directory {input_path}")
    logger.debug(f"output data directory {output_path}")
    logger.debug(f"config file path {config_path}")

    convert_directory(input_path, output_path, config_path, logger)

    # scan the directory to find tif files to convert to png file format
    for in_file in os.scandir(input_path):

        # tif file extensions are removed so that we can use the same file name for png
        file_name = os.path.basename(in_file.path).replace('.tif', '')
        
        copy_src_file_name = f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{file_name}'
        copy_dst_file_name = f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/convert/{file_name}'

        # move source png file to destination path 
        mssparkutils.fs.mv(
            f'{copy_src_file_name}.png',
            f'{copy_dst_file_name}.png',
            True
        )

        # move source xml (geo-coordinates) to destination path
        mssparkutils.fs.mv(
            f'{copy_src_file_name}.png.aux.xml',
            f'{copy_dst_file_name}.png.aux.xml',
            True
        )        