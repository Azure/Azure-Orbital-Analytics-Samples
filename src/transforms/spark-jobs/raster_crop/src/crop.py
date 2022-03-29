# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os, argparse, sys
import shapely as shp
import shapely.geometry as geo
from osgeo import gdal
from notebookutils import mssparkutils

from pathlib import Path

sys.path.append(os.getcwd())

import utils

# collect args
parser = argparse.ArgumentParser(description='Arguments required to run crop function')
parser.add_argument('--storage_account_name', type=str, required=True, help='Name of the storage account name where the input data resides')
parser.add_argument('--storage_account_key', required=True, help='Key to the storage account where the input data resides')
parser.add_argument('--storage_container', type=str, required=True, help='Container under which the input data resides')
parser.add_argument('--src_folder_name', default=None, required=True, help='Folder containing the source file for cropping')
parser.add_argument('--config_file_name', required=True, help='Config file name')

# parse Args
args = parser.parse_args()

def crop(storage_account_name: str, 
    storage_account_key: str, 
    storage_container: str, 
    src_folder_name: str,
    config_file_name: str):
    '''
    Crops the GeoTiff to the Area of Interest (AOI)

    Inputs:
        storage_account_name - Name of the storage account name where the input data resides
        storage_account_key - Key to the storage account where the input data resides
        storage_container - Container under which the input data resides
        src_folder_name - Folder containing the source file for cropping
        config_file_name - Config file name

    Output:
        Cropped GeeTiff saved into the user specified directory
    '''
    # enable logging
    logger = utils.init_logger("stac_download")

    gdal.UseExceptions()

    mssparkutils.fs.unmount(f'/{storage_container}') 

    mssparkutils.fs.mount( 
        f'abfss://{storage_container}@{storage_account_name}.dfs.core.windows.net', 
        f'/{storage_container}', 
        {"accountKey": storage_account_key} 
    )

    jobId = mssparkutils.env.getJobId()

    input_path = f'/synfs/{jobId}/{storage_container}/{src_folder_name}'
    config_path = f'/synfs/{jobId}/{storage_container}/config/{config_file_name}'
    output_path = f'/synfs/{jobId}/{storage_container}/crop'

    logger.debug(f"input data directory {input_path}")
    logger.debug(f"output data directory {output_path}")
    logger.debug(f"config file path {config_path}")

    try:
        # parse config file
        config = utils.parse_config(config_path)
    except Exception:
        exit(1)

    # get the aoi for cropping from config file
    geom = config.get("geometry")
    bbox = config.get("bbox")

    if (geom is not None) and (bbox is not None):
        logger.error('found both "geomtry" and "bbox"')
        exit(1)
    elif (geom is None) and (bbox is None):
        logger.error('found neither geomtry" and "bbox"')
        exit(1)

    try:
        aoi = geo.asShape(geom) if bbox is None else geo.box(*bbox)
    except Exception as e:
        logger.error(f"error parsing config:{e}")
        exit(1)

    if aoi.is_empty:
        logger.error(f"empty area of interest {aoi.wkt}")
        exit(1)

    logger.debug(f"using aoi '{aoi}'")

    input_files = []

    # list all the files in the folder that will be part of the crop
    files = mssparkutils.fs.ls(f'abfss://{storage_container}@{storage_account_name}.dfs.core.windows.net/{src_folder_name}')
    for file in files:
        if not file.isDir:
            input_files.append(file)

    # crop the raster file
    utils.crop_images(input_files, f'abfss://{storage_container}@{storage_account_name}.dfs.core.windows.net/{src_folder_name}', input_path, output_path, aoi)

    for file in input_files:
        # this is the newly created cropped file path in local host
        temp_src_path = file.path.replace(f'/{src_folder_name}', '/')

        # this is the destination path (storage account) where the newly
        # created cropped file will be moved to
        perm_src_path = file.path.replace(f'/{src_folder_name}/', '/crop/').replace(os.path.basename(file.path), 'output.tif')

        mssparkutils.fs.mv(
            temp_src_path,
            perm_src_path,
            True
        )

if __name__ == "__main__":

    print("Starting Tiling Process")

    crop(args.storage_account_name, 
        args.storage_account_key, 
        args.storage_container, 
        args.src_folder_name,
        args.config_file_name)

    print("Tiling Process Completed")