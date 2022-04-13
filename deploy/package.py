# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os
import re
import argparse
import shutil


# Collect args
parser = argparse.ArgumentParser(description='Arguments required to run packaging function')
parser.add_argument('--raw_storage_account_name', type=str, required=True, help='Name of the Raw data hosting Storage Account')
parser.add_argument('--synapse_storage_account_name', type=str, required=True, help='Name of the Raw data hosting Storage Account')
parser.add_argument('--synapse_pool_name', type=str, required=True, help='Name of the Synapse pool in the Synapse workspace to use as default')
parser.add_argument('--batch_storage_account_name', type=str, required=True, help='Name of the Batch Storage Account')
parser.add_argument('--batch_account', type=str, required=True, help="Batch Account name")
parser.add_argument('--linked_key_vault', type=str, required=True, help="Key Vault to be added as Linked Service")
parser.add_argument('--location', type=str, required=True, help="Batch Account Location")

#Parse Args
args = parser.parse_args()

def replace(tokens_map: dict, body: str):

    # use regex to identify tokens in the files. Token are in the format __token_name__
    # same token can occur multiple times in the same file
    tokenizer = re.compile("([\w\'\-]+|\s+|.?)")
    
    # replace tokens with actual values
    swap = lambda x: '{0}'.format(tokens_map.get(x)) if x in tokens_map else x
    
    # find all and replace
    result = ''.join(swap(st) for st in tokenizer.findall(body))
    
    return result

def package(tokens_map: dict):

    script_dirname = os.path.dirname(__file__)
    src_folder_path = os.path.join(script_dirname, '..', 'src', 'workflow')
    package_folder_path= os.path.join(os.getcwd(), 'package')

    # mode
    mode = 0o766

    # if package folder already exists, delete it before starting a new iteration
    if os.path.exists(package_folder_path):
        shutil.rmtree(package_folder_path)

    # copy the folder structure from src/workflow folder before replacing the 
    # tokens with values
    shutil.copytree(src_folder_path, package_folder_path)

    # set of folder names are fixed for synapse pipelines and hence hardcoding them
    for folder in ['linkedService', 'sparkJobDefinition', 'pipeline', 'bigDataPool']:

        # iterate through all file
        for file in os.listdir(f'{package_folder_path}/{folder}'):

            # check whether file is in json format or not
            if file.endswith(".json"):

                file_path = os.path.join(package_folder_path, folder ,file)
    
                with open(file_path, 'r') as f:
                    
                    # replaced token string in memory
                    token_replaced_file_content = replace(tokens_map, f.read())

                    with open(file_path, 'w') as file_write:

                        if token_replaced_file_content is not None:

                            # write back the token replaced string to file
                            file_write.write(token_replaced_file_content)

    # zip the folder contents to package.zip
    shutil.make_archive('package', 'zip', package_folder_path)

    # finally clean up the package folder
    if os.path.exists(package_folder_path):
        shutil.rmtree(package_folder_path)
    
if __name__ == "__main__":

    # list of tokens and their values to be replaced
    tokens_map = {
        '__raw_data_storage_account__': args.raw_storage_account_name,
        '__batch_storage_account__': args.batch_storage_account_name,
        '__batch_account__': args.batch_account,
        '__linked_key_vault__': args.linked_key_vault,
        '__synapse_storage_account__': args.synapse_storage_account_name,
        '__synapse_pool_name__': args.synapse_pool_name,
        '__location__': args.location
    }

    # invoke package method
    package(tokens_map)
