# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os
import argparse
import shutil
from pathlib import Path

from notebookutils import mssparkutils

PKG_PATH = Path(__file__).parent
PKG_NAME = PKG_PATH.name

# collect args
parser = argparse.ArgumentParser(description='Arguments required to run copy noop function')
parser.add_argument('--storage_account_name', type=str, required=True, help='Name of the storage account name where the input data resides')
parser.add_argument('--storage_account_key', required=True, help='Key to the storage account where the input data resides')

parser.add_argument('--src_container', type=str, required=False, help='Source container in Azure Storage')
parser.add_argument('--src_fileshare', type=str, required=False, help='Source File share in Azure Storage')
parser.add_argument('--src_folder', default=None, required=True, help='Source folder path in Azure Storage Container or File Share')

parser.add_argument('--dst_container', type=str, required=False, help='Destination container in Azure Storage')
parser.add_argument('--dst_fileshare', type=str, required=False, help='Destination File share in Azure Storage')
parser.add_argument('--dst_folder', default=None, required=True, help='Destination folder path in Azure Storage Container or File Share')

parser.add_argument('--folders_to_create', action='append', required=False, help='Folders to create in container or file share')


# parse Args
args = parser.parse_args()


def copy(src_mounted_path: str,
    src_unmounted_path: str,
    dst_mounted_path: str,
    dst_unmounted_path: str,
    dst_folder: str,
    folders: any):

    # create only if it does not already exists
    if not os.path.isdir(f'{dst_unmounted_path}') and dst_unmounted_path.startswith('https'):
        mssparkutils.fs.mkdirs(dst_unmounted_path)

    dst_path = dst_mounted_path.replace(f'/{dst_folder}', '')

    # folders are not required, so do not try to iterate
    # it if it is empty
    if folders is not None:
        for folder in folders:
            logger.info(f"creating folder path {dst_path}/{folder}")
            
            # create only if it does not already exists
            if not os.path.isdir(f'{dst_path}/{folder}'):
                os.makedirs(f'{dst_path}/{folder}')
            
    # mssparkutils.fs.cp works with source and destination 
    # that are of the same type storage container to storage
    # container
    logger.info(f"copying from {src_mounted_path} to {dst_mounted_path}")
    
    # using shutil to copy directory or individual files as needed
    if os.path.isdir(src_mounted_path):
        shutil.copytree(src_mounted_path, dst_mounted_path, dirs_exist_ok=True)
    else:
        shutil.copy(src_mounted_path, dst_mounted_path)

    logger.info("finished copying")

def map_source(storage_account_name: str,
    storage_account_key: str,
    container_name: str,
    fileshare_name: str,
    folder_path: str):

    # unmounted path refer to the storage account path that is not mounted to /synfs/{job_id}/{file_share_name} path
    unmounted_path = ''

    jobId = mssparkutils.env.getJobId()
    
    # if container name is specified, then the mapping / mount is for a container in azure storage account
    if container_name:
        
        unmounted_path = f'abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/{folder_path}'

        mssparkutils.fs.unmount(f'/{container_name}') 

        mssparkutils.fs.mount(  
            f'abfss://{container_name}@{storage_account_name}.dfs.core.windows.net',  
            f'/{container_name}',  
            {"accountKey": storage_account_key}  
        ) 

        mounted_path = f'/synfs/{jobId}/{container_name}/{folder_path}'

    # if file share is specified, then the mapping / mount is for a file share in azure storage account
    elif fileshare_name:

        unmounted_path = f'https://{fileshare_name}@{storage_account_name}.file.core.windows.net/{folder_path}'

        mssparkutils.fs.unmount(f'/{fileshare_name}') 

        mssparkutils.fs.mount(  
            f'https://{fileshare_name}@{storage_account_name}.file.core.windows.net/{folder_path}',  
            f'/{fileshare_name}',  
            {"accountKey": storage_account_key}  
        ) 

        mounted_path = f'/synfs/{jobId}/{fileshare_name}/{folder_path}'

    return mounted_path, unmounted_path

if __name__ == "__main__":

    # enable logging
    logging.basicConfig(
        level=logging.DEBUG, format="%(asctime)s:%(levelname)s:%(name)s:%(message)s"
    )

    logger = logging.getLogger("copy_noop")

    # map / mount the source container / file share in azure storage account
    src_mounted_path, src_unmounted_path = map_source(args.storage_account_name,
        args.storage_account_key,
        args.src_container,
        args.src_fileshare,
        args.src_folder)

    # map / mount the destination container / file share in azure storage account
    dst_mounted_path, dst_unmounted_path = map_source(args.storage_account_name,
        args.storage_account_key,
        args.dst_container,
        args.dst_fileshare,
        args.dst_folder)

    # copy method allows the three scenarios:
    # 1. source container to destination container
    # 2. source container to destination file share
    # 3. source file share to destination file share
    # source file share to destination container is not supported at this time
    copy(src_mounted_path, src_unmounted_path, dst_mounted_path, dst_unmounted_path, args.dst_folder, args.folders_to_create)
