# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import shutil
import argparse, sys
from osgeo import gdal
import logging
from notebookutils import mssparkutils

dst_folder_name = 'warp'

# collect args
parser = argparse.ArgumentParser(description='Arguments required to run warp function')
parser.add_argument('--storage_account_name', type=str, required=True, help='Name of the storage account name where the input data resides')
parser.add_argument('--storage_account_key', required=True, help='Key to the storage account where the input data resides')
parser.add_argument('--storage_container', type=str, required=True, help='Container under which the input data resides')
parser.add_argument('--src_folder_name', default=None, required=True, help='Folder containing the source file for cropping')

# parse Args
args = parser.parse_args()

def warp(
    input_path: str, 
    output_path: str, 
    file_name: str):

    gdal.UseExceptions()

    # specify options and run Warp
    kwargs = {'format': 'GTiff', 'dstSRS': '+proj=lcc +datum=WGS84 +lat_1=25 +lat_2=60 +lat_0=42.5 +lon_0=-100 +x_0=0 +y_0=0 +units=m +no_defs', 'srcSRS': '+proj=longlat +datum=WGS84 +no_defs'}
    ds = gdal.Warp(f'{output_path}/output_warp.tif', f'{input_path}/{file_name}', **kwargs)

    # close file and flush to disk
    ds = None

if __name__ == "__main__":

    # enable logging
    logging.basicConfig(
        level=logging.DEBUG, format="%(asctime)s:%(levelname)s:%(name)s:%(message)s"
    )
    logger = logging.getLogger("image_convert")

    # unmount any previously mounted storage account
    mssparkutils.fs.unmount(f'/{args.storage_container}') 

    # mount the storage account containing data required for this transform
    mssparkutils.fs.mount( 
        f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net', 
        f'/{args.storage_container}', 
        {"accountKey": args.storage_account_key} 
    )

    jobId = mssparkutils.env.getJobId()

    input_path = f'/synfs/{jobId}/{args.storage_container}/{args.src_folder_name}'
    output_path = f'/synfs/{jobId}/{args.storage_container}/{dst_folder_name}'

    logger.debug(f"input data directory {input_path}")
    logger.debug(f"output data directory {output_path}")

    # create a temporary placeholder for the folder path to be available
    mssparkutils.fs.put(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{dst_folder_name}/__processing__.txt', 'started tiling ...', True)

    try:
        files = mssparkutils.fs.ls(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{args.src_folder_name}')
        
        for file in files:
            if not file.isDir and file.name.endswith('.tif'):
                warp(input_path, output_path, file.name)

        # clean up the temporary placeholder on successful run
        mssparkutils.fs.rm(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{dst_folder_name}/__processing__.txt', True)
    except:
        # clean up the temporary placeholder on failed run
        mssparkutils.fs.append(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{dst_folder_name}/__processing__.txt', 'tiling  errored out', True)
        raise
    