# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# Translate format
import shutil
import sys
import geopandas
from osgeo import gdal
from notebookutils import mssparkutils

# Collect args
parser = argparse.ArgumentParser(description='Arguements required to run tiling function')
parser.add_argument('--storage_account_name', type=str, required=True, help='Name of the storage account name where the input data resides')
parser.add_argument('--storage_account_key', default=None, required=True, help='Key to the storage account where the input data resides')
parser.add_argument('--storage_account_src_container', type=str, required=True, help='Container under which the input data resides')
parser.add_argument('--storage_account_dst_container', default=None, required=True, help='Container where the output data will be saved')
parser.add_argument('--file_name', type=str, required=True, help='Input file name to be tiled (with extension)')

#Parse Args
args = parser.parse_args()

def extract_features_from_gpkg(storage_account_name: str, storage_account_key: str, storage_account_src_container: str, src_storage_folder: str, storage_account_dst_container: str, dst_storage_folder: str, file_name: str):

    gdal.UseExceptions()

    mssparkutils.fs.unmount("/aoi") 

    print(f"abfss://{storage_account_dst_container}@{storage_account_name}.dfs.core.windows.net")

    mssparkutils.fs.mount( 
        f"abfss://{storage_account_dst_container}@{storage_account_name}.dfs.core.windows.net", 
        "/aoi", 
        {"accountKey": storage_account_key} 
    ) 

    # Set Storage Account Information for source TIF data
    gdal.SetConfigOption('AZURE_STORAGE_ACCOUNT', storage_account_name)
    gdal.SetConfigOption('AZURE_STORAGE_ACCESS_KEY', storage_account_key)

    # Specify options and run Warp
    # gdalwarp -s_srs "+proj=longlat +datum=WGS84 +no_defs" -t_srs "+proj=lcc +datum=WGS84 +lat_1=25 +lat_2=60 +lat_0=42.5 +lon_0=-100 +x_0=0 +y_0=0 +units=m +no_defs" output_warp.tif output_warp.tif
    kwargs = {'format': 'GTiff', 'dstSRS': '+proj=lcc +datum=WGS84 +lat_1=25 +lat_2=60 +lat_0=42.5 +lon_0=-100 +x_0=0 +y_0=0 +units=m +no_defs', 'srcSRS': '+proj=longlat +datum=WGS84 +no_defs'}
    ds = gdal.Warp('output_warp.tif', f'/vsiadls/{storage_account_src_container}/{src_storage_folder}/{file_name}', **kwargs)

    # Close file and flush to disk
    ds = None

    jobId = mssparkutils.env.getJobId() 
    shutil.copy("output_warp.tif", f"/synfs/{jobId}/aoi/output_warp.tif")

if __name__ == "__main__":

    extract_features_from_gpkg(args)