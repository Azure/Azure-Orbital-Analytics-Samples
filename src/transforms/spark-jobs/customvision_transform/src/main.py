# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import sys, os, argparse, math
import json
import logging
import logging.config
import pyproj
import glob
import rasterio as rio
import rasterio.mask
import shapely as shp
import shapely.geometry as geo
from shapely.ops import transform
from osgeo import gdal
from pandas import array
from notebookutils import mssparkutils 
from pyspark.sql import SparkSession

from pathlib import Path
from PIL import Image, UnidentifiedImageError
import shutil
from notebookutils import mssparkutils

# collect args
parser = argparse.ArgumentParser(description='Arguments required to run mosaic function')
parser.add_argument('--storage_account_name', type=str, required=True, help='Name of the storage account name where the input data resides')
parser.add_argument('--storage_container', type=str, required=True, help='Container under which the input data resides')
parser.add_argument('--key_vault_name', type=str, required=True, help='Name of the Key Vault that stores the secrets')
parser.add_argument('--storage_account_key_secret_name', type=str, required=True, help='Name of the secret in the Key Vault that stores storage account key')
parser.add_argument('--linked_service_name', type=str, required=True, help='Name of the Linekd Service for the Key Vault')

parser.add_argument('--aoi', nargs=4, type=float, default=None, help='Coordinates for Area of Interest')

# parse Args
args = parser.parse_args()

def area_sq_km(area: shp.geometry.base.BaseGeometry, src_crs) -> float:
    tfmr = pyproj.Transformer.from_crs(src_crs, {'proj':'cea'}, always_xy=True)
    return transform(tfmr.transform, area).area / 1e6

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
    logger.info("Tiling: getting tile size")
    tile_size = int(tile_size)
    logger.info(f"Tiling: tile size retrieved - {tile_size}")
    
    try:
        logger.info("Tiling: getting image")
        Image.MAX_IMAGE_PIXELS = None
        img = Image.open(str(Path(input_path) / file_name))
        logger.info("Tiling: image Retrieved")

        logger.info("Tiling: determining Tile width")
        n_tile_width = list(range(0,math.floor(img.size[0]/tile_size)))
        logger.info(f"Tiling: tile width {n_tile_width}")
        logger.info("Tiling: determining Tile height")
        n_tile_height = list(range(0,math.floor(img.size[1]/tile_size)))
        logger.info(f"Tiling: tile height {n_tile_height}")
        tile_combinations = [(a,b) for a in n_tile_width for b in n_tile_height]
        
        logger.info("Tiling: processing tiles")
        for tile_touple in tile_combinations:
            logger.info("Tiling: getting starting coordinates")
            x_start_point = tile_touple[0]*tile_size
            y_start_point = tile_touple[1]*tile_size
            logger.info(f"Tiling: got Starting Coordinates - {x_start_point},{y_start_point}")
            
            logger.info("Tiling: cropping Tile")
            crop_box = (x_start_point, y_start_point, x_start_point+tile_size, y_start_point+tile_size)
            tile_crop = img.crop(crop_box)
            logger.info("Tiling: tile Cropped")
            
            logger.info("Tiling: getting tile name")
            img_name = os.path.basename(file_name)
            tile_name = img_name.rsplit('.',1)
            tile_name = '.'.join([tile_name[0],'tile',str(tile_touple[0]),str(tile_touple[1]),tile_name[1]])
            logger.info(f"Tiling: retreived Tile name - {tile_name}")
            
            logger.info(f"Tiling: saving Tile - {tile_name}")
            tile_crop.save(str(Path(output_path) / tile_name))
            logger.info(f"Tiling: saved Tile - {tile_name}")
    except UnidentifiedImageError:
        logger.info("Tiling: file is not an image, copying to destination directory")
        sourcePath = str(Path(input_path) / img_name)
        destinationPath = str(Path(output_path) / img_name)

        logger.info(f"Tiling: copying file from {sourcePath} to {destinationPath}")
        shutil.copyfile(sourcePath,destinationPath)
        logger.info(f"Tiling: copied file from {sourcePath} to {destinationPath}")

def convert_directory(
    input_path,
    output_path,
    default_options={"format": "png", "metadata": True}
):
    # todo: redundant call to this needs to be removed
    gdal.UseExceptions()
    translate_options_dict = default_options
    logger.debug("Convert: default config options: %s", translate_options_dict)

    logger.info("Convert: using config options: %s", translate_options_dict)

    keep_metadata = translate_options_dict.pop("metadata")

    opt = gdal.TranslateOptions(**translate_options_dict)

    logger.debug("Convert: looking for input files in %s", input_path)

    for in_file in os.scandir(input_path):
        in_name = in_file.name
        logger.info("Convert: ingesting file %s", in_file.path)
        # ! this is a landmine; will error for files w/o extension but with '.', and for formats with spaces
        out_name = os.path.splitext(in_name)[0] + "." + translate_options_dict["format"]
        out_path = os.path.join(output_path, out_name)
        try:
            # call gdal to convert the file format
            gdal.Translate(out_path, in_file.path, options=opt)
        except Exception as e:
            logger.error("Convert: gdal error: %s", e)
            sys.exit(1)
        else:
            logger.info("Convert: successfully translated %s", out_path)

    # check to see if we need to carry over the geo-coordinates / metadata file?
    if not keep_metadata:
        xml_glob = os.path.join(output_path, "*.aux.xml")
        logger.debug(f"Convert: deleting metadata files that match {xml_glob}")
        for xml_file in glob.glob(xml_glob):
            logger.debug(f"Convert: deleting metadata file f{xml_file}")
            os.remove(xml_file)

def crop(image_paths: array, 
    output_path: str,
    bbox: [float]):
    '''
    Crops the GeoTiff to the Area of Interest (AOI)

    Output:
        Cropped GeeTiff saved into the user specified directory
    '''
    gdal.UseExceptions()

    geom = None

    if (geom is not None) and (bbox is not None):
        logger.error('Crop: found both "geomtry" and "bbox"')
        exit(1)
    elif (geom is None) and (bbox is None):
        logger.error('Crop: found neither geomtry" and "bbox"')
        exit(1)

    try:
        aoi = geo.asShape(geom) if bbox is None else geo.box(*bbox)
    except Exception as e:
        logger.error(f"Crop: error parsing config:{e}")
        exit(1)

    if aoi.is_empty:
        logger.error(f"Crop: empty area of interest {aoi.wkt}")
        exit(1)

    logger.debug(f"Crop: using aoi '{aoi}'")

    # crop the raster file
    for image_path in image_paths:

        logger.info(f'Crop: opening file from path {image_path}')

        with rio.open(image_path, "r") as img_src:
            dst_meta = img_src.meta

            crs_src = img_src.crs
            src_shape = img_src.shape
            src_area = area_sq_km(shp.geometry.box(*img_src.bounds), crs_src)

            # convert the aoi boundary to the images native CRS
            # shapely is (x,y) coord order, but its (lat, long) for WGS84
            #  so force consistency with always_xy
            tfmr = pyproj.Transformer.from_crs("epsg:4326", crs_src, always_xy=True)
            aoi_src = transform(tfmr.transform, aoi)

            # possible changes - better decision making on nodata choices here
            #! and use better choice than 0 for floats and signed ints
            data_dst, tfm_dst = rio.mask.mask(
                img_src, [aoi_src], crop=True, nodata=0
            )

            dst_meta.update(
                {
                    "driver": "gtiff",
                    "height": data_dst.shape[1],
                    "width": data_dst.shape[2],
                    "alpha": "unspecified",
                    "nodata": 0,
                    "transform": tfm_dst,
                }
            )

        out_meta_str = str(dst_meta).replace("\n", "")

        output_file_name = os.path.basename(image_path)
        dst_path = f'{output_path}/{output_file_name}'

        with rio.open(dst_path, "w", **dst_meta) as img_dst:
            img_dst.write(data_dst)

            dst_area = area_sq_km(shp.geometry.box(*img_dst.bounds), crs_src)
            dst_shape = img_dst.shape

def mosaic_tifs(input_path: str, 
    output_path: str, 
    files: any):
    '''
        Stitches two or more GeoTiffs into one single large GeoTiff

        Output:
            Single large GeoTiff saved into the user specified storage account

    '''
    gdal.UseExceptions()

    # two or more files to be mosaic'ed are passed as comma separated values
    files_to_mosaic = [ f"{input_path}/{file}" for file in files ]

    # gdal library's wrap method is called to perform the mosaic'ing
    g = gdal.Warp(f'{output_path}/output.tif', files_to_mosaic, format="GTiff", options=["COMPRESS=LZW", "TILED=YES"])

    # close file and flush to disk
    g = None

if __name__ == "__main__":

    # enable logging
    logging.basicConfig(
        level=logging.DEBUG, format="%(asctime)s:%(levelname)s:%(name)s:%(message)s"
    )

    logger = logging.getLogger("custom_vision_transform")

    sc = SparkSession.builder.getOrCreate()
    token_library = sc._jvm.com.microsoft.azure.synapse.tokenlibrary.TokenLibrary
    storage_account_key = token_library.getSecret(args.key_vault_name, args.storage_account_key_secret_name, args.linked_service_name)
    
    # mount storage account container
    mssparkutils.fs.unmount(f'/{args.storage_container}') 
    mssparkutils.fs.mount( 
        f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net', 
        f'/{args.storage_container}', 
        {"accountKey": storage_account_key} 
    )

    jobId = mssparkutils.env.getJobId()

    mosaic_src_folder = "raw"

    crop_config_path = f'/synfs/{jobId}/{args.storage_container}/config/config-aoi.json'

    # list the files in the source folder path under the storage account's container
    images_to_mosaic = mssparkutils.fs.ls(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{mosaic_src_folder}')
    
    input_files = []
    for file in images_to_mosaic:
        if not file.isDir and file.name.endswith('.TIF'):
            input_files.append(file.name)

    # list all the files in the folder that will be part of the crop
    if len(input_files) > 1:
        crop_src_folder = 'mosaic'
    else:
        crop_src_folder = 'raw'

    input_path = f'/synfs/{jobId}/{args.storage_container}/{mosaic_src_folder}'
    output_path = f'/synfs/{jobId}/{args.storage_container}/{crop_src_folder}'

    # only if there is more than one tif file, 
    # then call mosaic
    if len(input_files) > 1:

        mssparkutils.fs.mkdirs(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{crop_src_folder}')

        logger.info("Main: starting Mosaicing Process")

        # mosaic method is called
        mosaic_tifs(input_path, output_path, input_files)

        logger.info("Main: mosaicing Process Completed")

    logger.info("Main: starting Cropping Process")

    convert_src_folder = 'crop'

    input_path = f'/synfs/{jobId}/{args.storage_container}/{crop_src_folder}'
    output_path = f'/synfs/{jobId}/{args.storage_container}/{convert_src_folder}'

    images_to_crop = mssparkutils.fs.ls(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{crop_src_folder}')

    mssparkutils.fs.mkdirs(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{convert_src_folder}')

    input_files = []
    for file in images_to_crop:
        logger.info(f'iterating file in loop with path {file.path}')
        if not file.isDir:
            input_files.append(
                file.path.replace(
                    f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{crop_src_folder}', 
                    f'/synfs/{jobId}/{args.storage_container}/{crop_src_folder}'))

    crop(input_files, output_path, args.aoi)

    logger.info("Main: cropping Process Completed")

    logger.info("Main: starting Convert Process")

    tiles_src_folder = 'convert'

    input_path = f'/synfs/{jobId}/{args.storage_container}/{convert_src_folder}'
    output_path = f'/synfs/{jobId}/{args.storage_container}/{tiles_src_folder}'
    convert_config_path = f'/synfs/{jobId}/{args.storage_container}/config/config-img-convert-png.json'

    mssparkutils.fs.mkdirs(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{tiles_src_folder}')

    convert_directory(input_path, output_path)

    logger.info("Main: convert Process Completed")

    logger.info("Main: starting Tiling Process")

    tiles_dst_folder = 'tiles'

    input_path = f'/synfs/{jobId}/{args.storage_container}/{tiles_src_folder}'
    output_path = f'/synfs/{jobId}/{args.storage_container}/{tiles_dst_folder}'

    mssparkutils.fs.mkdirs(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{tiles_dst_folder}')

    tile_img(input_path, output_path, "output.png", "512")

    logger.info("Main: tiling Process Completed")