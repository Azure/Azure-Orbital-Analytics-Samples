# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os, math, argparse
from pathlib import Path
from PIL import Image, UnidentifiedImageError
import shutil
import logging
from osgeo import gdal
from notebookutils import mssparkutils

Image.MAX_IMAGE_PIXELS = None

# Collect args
parser = argparse.ArgumentParser(description='Arguements required to run tiling function')
parser.add_argument('--storage_account_name', type=str, required=True, help='Name of the storage account name where the input data resides')
parser.add_argument('--storage_account_key', required=True, help='Key to the storage account where the input data resides')
parser.add_argument('--storage_container', type=str, required=True, help='Container under which the input data resides')
parser.add_argument('--src_folder_name', default=None, required=True, help='Folder where the input data is stored')
parser.add_argument('--file_name', type=str, required=True, help='Input file name to be tiled (with extension)')
parser.add_argument('--tile_size', type=str, required=True, help='Tile size')

#Parse Args
args = parser.parse_args()

# Define functions
def tile_img(input_path: str, 
    output_path: str, 
    file_name: str,
    tile_size):
    '''
    Tiles/chips images into a user defined size using the tile_size parameter
    
    Inputs:
        input_path - Name of the storage account name where the input data resides
        output_path - Key to the storage account where the input data resides
        file_name - Input file name to be tiled (with extension)
        tile_size - Tile size

    Output:
        All image chips saved into the user specified directory
    
    '''

    gdal.UseExceptions()

    print("Getting tile size")

    tile_size = int(tile_size)

    print(f"Tile size retrieved - {tile_size}")
    
    try:
        print("Getting image")
        img = Image.open(str(Path(input_path) / file_name))
        print("Image Retrieved")

        print("Determining Tile width")
        n_tile_width = list(range(0,math.floor(img.size[0]/tile_size)))
        print(f"Tile width {n_tile_width}")
        print("Determining Tile height")
        n_tile_height = list(range(0,math.floor(img.size[1]/tile_size)))
        print(f"Tile height {n_tile_height}")
        tile_combinations = [(a,b) for a in n_tile_width for b in n_tile_height]
        
        print("Processing tiles")
        for tile_touple in tile_combinations:
            print("Getting starting coordinates")
            x_start_point = tile_touple[0]*tile_size
            y_start_point = tile_touple[1]*tile_size
            print(f"Got Starting Coordinates - {x_start_point},{y_start_point}")
            
            print("Cropping Tile")
            crop_box = (x_start_point, y_start_point, x_start_point+tile_size, y_start_point+tile_size)
            tile_crop = img.crop(crop_box)
            print("Tile Cropped")
            
            print("Getting tile name")
            img_name = os.path.basename(file_name)
            tile_name = img_name.rsplit('.',1)
            tile_name = '.'.join([tile_name[0],'tile',str(tile_touple[0]),str(tile_touple[1]),tile_name[1]])
            print(f"Retreived Tile name - {tile_name}")
            
            print(f"Saving Tile - {tile_name}")
            tile_crop.save(str(Path(output_path) / tile_name))
            print(f"Saved Tile - {tile_name}")
    except UnidentifiedImageError:
        print("File is not an image, copying to destination directory")
        sourcePath = str(Path(input_path) / img_name)
        destinationPath = str(Path(output_path) / img_name)

        print(f"Copying file from {sourcePath} to {destinationPath}")
        shutil.copyfile(sourcePath,destinationPath)
        print(f"Copied file from {sourcePath} to {destinationPath}")


def process_img_folder(args):
    '''
    Function to process all the images in a given source directory 
    
    Input:
        args - command line arguements passed to the file
    
    Output:
        Nothing returned. Processed images placed in the output directory
    
    '''
    for img_name in os.listdir(args.path_to_input_img):

        print('Processing',str(img_name))

        tile_img(args.path_to_input_img, args.path_to_output, img_name, args.tile_size)

        print(f"{img_name} finished processing")
        

if __name__ == "__main__":

    logging.basicConfig(
        level=logging.DEBUG, format="%(asctime)s:%(levelname)s:%(name)s:%(message)s"
    )
    logger = logging.getLogger("image_convert")

    mssparkutils.fs.unmount(f'/{args.storage_container}') 

    mssparkutils.fs.mount( 
        f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net', 
        f'/{args.storage_container}', 
        {"accountKey": args.storage_account_key} 
    )

    jobId = mssparkutils.env.getJobId()

    input_path = f'/synfs/{jobId}/{args.storage_container}/{args.src_folder_name}'
    output_path = f'/synfs/{jobId}/{args.storage_container}/tiles'

    logger.debug(f"input data directory {input_path}")
    logger.debug(f"output data directory {output_path}")

    print("Starting Tiling Process")

    mssparkutils.fs.put(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/tiles/__processing__.txt', 'started tiling ...', True)

    try:
        tile_img(input_path, output_path, args.file_name, args.tile_size)
        mssparkutils.fs.rm(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/tiles/__processing__.txt', True)
    except:
        mssparkutils.fs.append(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/tiles/__processing__.txt', 'tiling  errored out', True)
        raise
        
    print("Tiling Process Completed")