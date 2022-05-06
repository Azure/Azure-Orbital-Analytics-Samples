# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import geopandas as gpd
import json
import logging
import math
import os
import glob
import rasterio as rio
import shapely as shp
import argparse, sys
import xml.etree.ElementTree as ET
from pyspark.sql import SparkSession

from numpy import asarray
from pathlib import Path
from pyproj import Transformer
from rasterio.crs import CRS

sys.path.append(os.getcwd())

from utils import parse_config, init_logger
from notebookutils import mssparkutils

DEFAULT_CONFIG = {"probability_cutoff": 0.5, "width": 512.1, "height": 512, "tag_name": "pool"}

PKG_PATH = Path(__file__).parent
PKG_NAME = PKG_PATH.name

dst_folder_name = 'pool-geolocation'

# collect args
parser = argparse.ArgumentParser(description='Arguments required to run pool geolocation function')
parser.add_argument('--storage_account_name', type=str, required=True, help='Name of the storage account name where the input data resides')

parser.add_argument('--storage_container', type=str, required=True, help='Container under which the input data resides')
parser.add_argument('--src_folder_name', default=None, required=True, help='Folder containing the source file for cropping')
parser.add_argument('--config_file_name', required=False, help='Config file name')

parser.add_argument('--key_vault_name', type=str, required=True, help='Name of the Key Vault that stores the secrets')
parser.add_argument('--storage_account_key_secret_name', type=str, required=True, help='Name of the secret in the Key Vault that stores storage account key')
parser.add_argument('--linked_service_name', type=str, required=True, help='Name of the Linekd Service for the Key Vault')

# parse Args
args = parser.parse_args()

def get_pool_gelocations(input_path: str,
    output_path: str,
    config_path: str):
  
    if config_path is not None:
        config = parse_config(config_path, DEFAULT_CONFIG)
    else:
        config = DEFAULT_CONFIG

    height = int(config["height"])
    width = int(config["width"])
    prob_cutoff = min(max(config["probability_cutoff"], 0), 1)
    dst_crs = CRS.from_epsg(4326)

    logger.debug(f"looking for PAM file using `{input_path}/*.aux.xml`")

    # find all files that contain the geocoordinate references    
    for pam_file in glob.glob(f'{input_path}/*.aux.xml'):
        pam_base_filename = os.path.basename(pam_file)
        logger.info(f"found PAM file {str(pam_base_filename)}")

        img_name = pam_base_filename.replace(".png.aux.xml", "")
        logger.info(f"using image name {img_name}")

        pam_tree = ET.parse(pam_file)
        pam_root = pam_tree.getroot()

        srs = pam_root.find("SRS")
        wkt = pam_root.find("WKT")

        if not srs is None:
            crs = CRS.from_string(srs.text)
        elif not wkt is None:
            crs = CRS.from_string(wkt.text)
        else:
            crs = CRS.from_epsg(4326)
            logger.warning(
                f"neither node 'SRS' or 'WKT' found in file {pam_file}, using epsg:4326"
            )
        logger.info(f"parsed crs {crs}")

        tfmr = Transformer.from_crs(crs, dst_crs, always_xy=True)

        tfm_xml = pam_root.find("GeoTransform")
        if tfm_xml is None:
            logger.error(f"could not find node 'GeoTransform' in file {pam_file} - quiting")
            exit(1)

        tfm_raw = [float(x) for x in tfm_xml.text.split(",")]
        
        if rio.transform.tastes_like_gdal(tfm_raw):
            tfm = rio.transform.Affine.from_gdal(*tfm_raw)
        else:
            tfm = rio.transform.Affine(*tfm_raw)
        logger.info(f"parsed transform {tfm.to_gdal()}")

        logger.info(f"using width: {width}, height: {height}, probability cut-off: {prob_cutoff}")
        logger.debug(f"looking for custom vision JSON files using `{input_path}/{img_name}*.json`")

        # find all json files to process
        all_predictions = []
        for json_path in glob.glob(f'{input_path}/{img_name}*.json'):
            
            logger.debug(f"reading {json_path}")
            logger.debug(f"file name is {json_path}")
            predictions = json.load(Path(json_path).open())
            col, row = json_path.split(".")[-3:-1]
            col, row = int(col), int(row)

            tag_name = config["tag_name"]

            logger.debug(f"found {len(predictions)} predictions total")
            predictions = [pred for pred in predictions["predictions"] if pred["probability"] >= prob_cutoff and pred["tagName"] == tag_name]
            logger.debug(f"only {len(predictions)} preditions meet criteria")

            # iterate through all predictions and process
            for pred in predictions:
                box = pred["boundingBox"]

                left = (col + box["left"]) * width
                right = (col + box["left"] + box["width"]) * width
                top = (row + box["top"]) * height
                bottom = (row + box["top"] + box["height"]) * height

                img_bbox = shp.geometry.box(left, bottom, right, top)
                bbox = shp.geometry.Polygon(zip(*tfmr.transform(*rio.transform.xy(tfm, *reversed(img_bbox.boundary.xy), offset="ul"))))
                pred["boundingBox"] = bbox
                pred["tile"] = os.path.basename(json_path)

            all_predictions.extend(predictions)

        logger.info(f"found {len(all_predictions)} total predictions")
        if len(all_predictions) > 0:
            pools_geo = gpd.GeoDataFrame(all_predictions, geometry="boundingBox", crs=dst_crs)
            pools_geo["center"] = pools_geo.apply(lambda r: str(asarray(r["boundingBox"].centroid).tolist()), axis=1)
            output_file = f"{output_path}/{img_name}.geojson"
            pools_geo.to_file(output_file, driver='GeoJSON')
            logger.info(f"saved locations to {output_file}")


if __name__ == "__main__":

    # enable logging
    logging.basicConfig(
        level=logging.DEBUG, format="%(asctime)s:%(levelname)s:%(name)s:%(message)s"
    )

    logger = logging.getLogger("pool_geolocation")

    logger.info("starting pool geolocation, running ...")

    sc = SparkSession.builder.getOrCreate()
    token_library = sc._jvm.com.microsoft.azure.synapse.tokenlibrary.TokenLibrary
    storage_account_key = token_library.getSecret(args.key_vault_name, args.storage_account_key_secret_name, args.linked_service_name)

    # if a mount to the same path is already present, then unmount it
    mssparkutils.fs.unmount(f'/{args.storage_container}') 

    # mount the container
    mssparkutils.fs.mount( 
        f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net', 
        f'/{args.storage_container}', 
        {"accountKey": storage_account_key} 
    )

    jobId = mssparkutils.env.getJobId()

    # deriving the input, output and config path
    input_path = f'/synfs/{jobId}/{args.storage_container}/{args.src_folder_name}'
    if args.config_file_name != None:
        config_path = f'/synfs/{jobId}/{args.storage_container}/config/{args.config_file_name}'
        logger.debug(f"config file path {config_path}")
    else:
        config_path = None
        
    output_path = f'/synfs/{jobId}/{args.storage_container}/{dst_folder_name}'

    # debug purposes only
    logger.debug(f"input data directory {input_path}")
    logger.debug(f"output data directory {output_path}")

    # start by creating a placeholder file. we need this because creating files under a folder
    # that does not already existis fails without this.
    mssparkutils.fs.put(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{dst_folder_name}/__processing__.txt', 'started tiling ...', True)

    try:

        # invoke the main logic
        get_pool_gelocations(input_path, output_path, config_path)

        # remove the placeholder file upon successful run
        mssparkutils.fs.rm(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{dst_folder_name}/__processing__.txt', True)
    except:
        # remove the placefolder file upon failed run
        mssparkutils.fs.append(f'abfss://{args.storage_container}@{args.storage_account_name}.dfs.core.windows.net/{dst_folder_name}/__processing__.txt', 'tiling  errored out', True)
        raise

    # final logging for this transform
    logger.info("finished running pool geolocation")