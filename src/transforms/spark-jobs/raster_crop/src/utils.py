# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import json
import logging
import logging.config
import pyproj
import rasterio as rio
import rasterio.mask
import shapely as shp
import shapely.geometry
from notebookutils import mssparkutils

from pathlib import Path
from shapely.ops import transform

def parse_config(config_path: str):
    LOGGER.info(f"reading config file {config_path}")
    try:
        with open(config_path, "r") as file:
            config = json.load(file)
            LOGGER.info(f"using configuration {config}")
    except Exception as e:
        LOGGER.error(f"error reading config file:{e}")
        raise

    return config

def area_sq_km(area: shp.geometry.base.BaseGeometry, src_crs) -> float:
    tfmr = pyproj.Transformer.from_crs(src_crs, {'proj':'cea'}, always_xy=True)
    return transform(tfmr.transform, area).area / 1e6

def crop_images(
    images: any,
    input_path: Path,
    local_input_path: str,
    output_path: Path,
    aoi: shp.geometry.base.BaseGeometry,
):
    for image in images:
        LOGGER.info(f"starting on file {image}")
        print(input_path)
        print(local_input_path)
        image_path = image.path.replace(input_path, local_input_path)

        print(image_path)

        with rio.open(image_path, "r") as img_src:
            LOGGER.debug(f"opening file {image.name}")
            dst_meta = img_src.meta

            crs_src = img_src.crs
            src_shape = img_src.shape
            src_area = area_sq_km(shp.geometry.box(*img_src.bounds), crs_src)

            # convert the aoi boundary to the images native CRS
            # shapely is (x,y) coord order, but its (lat, long) for WGS84
            #  so force consistency with always_xy
            tfmr = pyproj.Transformer.from_crs("epsg:4326", crs_src, always_xy=True)
            aoi_src = transform(tfmr.transform, aoi)

            # TODO: better decision making on nodata choices here
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
        LOGGER.debug(f"using options for destination image {out_meta_str}")
        local_output_path = output_path.replace('/crop', '')
        rel_local_path = image_path.replace(local_input_path, '')
        dst_path = f'{local_output_path}/{rel_local_path}'

        with rio.open(dst_path, "w", **dst_meta) as img_dst:
            img_dst.write(data_dst)

            dst_area = area_sq_km(shp.geometry.box(*img_dst.bounds), crs_src)
            dst_shape = img_dst.shape


        LOGGER.debug(f"source dimensions {src_shape} and area (sq km) {src_area}")
        LOGGER.debug(f"destination dimensions {dst_shape} and area (sq km) {dst_area}")

        LOGGER.info(f"saved cropped image to {dst_path}")


##########################################################################################
# logging
##########################################################################################


LOGGER = None


def init_logger(name: str = __name__, level: int = logging.DEBUG) -> logging.Logger:
    config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "standard": {"format": "%(asctime)s:[%(levelname)s]:%(name)s:%(message)s"},
        },
        "handlers": {
            f"{name}_hdl": {
                "level": level,
                "formatter": "standard",
                "class": "logging.StreamHandler",
                # 'stream': 'ext://sys.stdout',  # Default is stderr
            },
        },
        "loggers": {
            name: {"propagate": False, "handlers": [f"{name}_hdl"], "level": level,},
        },
    }
    logging.config.dictConfig(config)
    global LOGGER
    LOGGER = logging.getLogger(name)
    return LOGGER


def default_logger():
    if LOGGER is None:
        init_logger()
    return LOGGER
