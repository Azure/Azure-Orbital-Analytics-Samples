# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os
import re
import argparse
import shutil


# Collect args
parser = argparse.ArgumentParser(description='Arguements required to run tiling function')
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

    # use the offset of each string into the sorted list of strings as the 'id'
    # build a dict to make this lookup cheap
    # id_lookup = dict([(y,x) for x,y in enumerate(sorted(strings))])
    # capture the following types of groups
    # [\w\'\-] : match one or more word character (+ some things typically found in words)
    # or \s+ : any whitespace
    # or .? : anything else
    tokenizer = re.compile("([\w\'\-]+|\s+|.?)")
    # if the token is found in the string -> id mapping, return a python format string
    # w/ it's offset ('id').  otherwise leave the input alone (eg return it)
    swap = lambda x: '{0}'.format(tokens_map.get(x)) if x in tokens_map else x
    # reassemble the original text from tokens w/ replacements where a token is found
    # in the set of strings
    result = ''.join(swap(st) for st in tokenizer.findall(body))
    
    return result

def package(tokens_map: dict):

    src_folder_path = os.path.join(os.getcwd(), '..', 'src', 'workflow')
    package_folder_path= os.path.join(os.getcwd(), 'package')

    # mode
    mode = 0o766

    if os.path.exists(package_folder_path):
        shutil.rmtree(package_folder_path)

    # os.mkdir(package_folder_path, mode)
    shutil.copytree(src_folder_path, package_folder_path)


    for folder in ['linkedService', 'sparkJobDefinition', 'pipeline', 'bigDataPool']:

        # iterate through all file
        for file in os.listdir(f'{package_folder_path}/{folder}'):

            # Check whether file is in text format or not
            if file.endswith(".json"):

                file_path = os.path.join(package_folder_path, folder ,file)
    
                with open(file_path, 'r') as f:

                    token_replaced_file_content = replace(tokens_map, f.read())

                    with open(file_path, 'w') as file_write:

                        if token_replaced_file_content is not None:

                            file_write.write(token_replaced_file_content)

    shutil.make_archive('package', 'zip', package_folder_path)

    if os.path.exists(package_folder_path):
        shutil.rmtree(package_folder_path)
    
if __name__ == "__main__":

    tokens_map = {
        '__raw_data_storage_account__': args.raw_storage_account_name,
        '__batch_storage_account__': args.batch_storage_account_name,
        '__batch_account__': args.batch_account,
        '__linked_key_vault__': args.linked_key_vault,
        '__synapse_storage_account__': args.synapse_storage_account_name,
        '__synapse_pool_name__': args.synapse_pool_name,
        '__location__': args.location
    }

    package(tokens_map)