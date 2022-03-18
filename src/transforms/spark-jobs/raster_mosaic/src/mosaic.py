# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# Translate format
import argparse, sys
from osgeo import gdal
import logging

from pandas import array
from notebookutils import mssparkutils 


# Collect args
parser = argparse.ArgumentParser(description='Arguements required to run tiling function')
parser.add_argument('--storage_account_name', type=str, required=True, help='Name of the storage account name where the input data resides')
parser.add_argument('--storage_account_key', required=True, help='Key to the storage account where the input data resides')
parser.add_argument('--storage_container', type=str, required=True, help='Container under which the input data resides')
parser.add_argument('--src_folder_name', default=None, required=True, help='Folder containing the source file for cropping')

#Parse Args
args = parser.parse_args()

def mosaic_tifs(input_path: str, 
    output_path: str, 
    files: any):
    print("file names are listed below")
    print(files)
    '''
        Stitches two or more GeoTiffs into one single large GeoTiff

        Inputs:
            storage_account_name - Name of the storage account name where the input data resides
            storage_account_key - Key to the storage account where the input data resides
            storage_container - Container under which the input data resides
            src_folder_name - Folder where the input data is stored
            file_names - Array of input file names (with extension)

        Output:
            Single large GeoTiff saved into the user specified storage account

    '''
    gdal.UseExceptions()

    files_to_mosaic = [ f"{input_path}/{file}" for file in files ]

    temp_output_path = output_path.replace('/mosaic', '')

    g = gdal.Warp(f'{temp_output_path}/output.tif', files_to_mosaic, format="GTiff", options=["COMPRESS=LZW", "TILED=YES"])

    # Close file and flush to disk
    g = None

if __name__ == "__main__":

    logging.basicConfig(
        level=logging.DEBUG, format="%(asctime)s:%(levelname)s:%(name)s:%(message)s"
    )
    logger = logging.getLogger("image_mosaic")

    mssparkutils.fs.unmount(f'/{args.storage_container}') 

    mssparkutils.fs.mount( 
        f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net', 
        f'/{args.storage_container}', 
        {"accountKey": args.storage_account_key} 
    )

    jobId = mssparkutils.env.getJobId()

    input_path = f'/synfs/{jobId}/{args.storage_container}/{args.src_folder_name}'
    output_path = f'/synfs/{jobId}/{args.storage_container}/mosaic'

    logger.debug(f"input data directory {input_path}")
    logger.debug(f"output data directory {output_path}")

    files = mssparkutils.fs.ls(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{args.src_folder_name}')
    input_files = []
    for file in files:
        if not file.isDir and file.name.endswith('.TIF'):
            input_files.append(file.name)

    print("Starting Mosaicing Process")

    mosaic_tifs(input_path, output_path, input_files)

    temp_output_path = output_path.replace('/mosaic', '')

    mssparkutils.fs.mv(
        f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/output.tif',
        f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/mosaic/output.tif',
        True
    )

    print("Mosaicing Process Completed")