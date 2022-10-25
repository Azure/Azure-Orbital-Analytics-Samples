# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os
import re
import argparse
import shutil
import json
from pathlib import Path

# Collect args
parser = argparse.ArgumentParser(description='Arguments required to run packaging function')
parser.add_argument('--modes',
    type=str, required=True, default='batch-account',
    help='Type of model run host either batch-account or aks')
parser.add_argument('--raw_storage_account_name', type=str, required=True, help='Name of the Raw data hosting Storage Account')
parser.add_argument('--synapse_storage_account_name', type=str, required=True, help='Name of the Raw data hosting Storage Account')
parser.add_argument('--synapse_pool_name', type=str, required=True, help='Name of the Synapse pool in the Synapse workspace to use as default')
parser.add_argument('--synapse_workspace_id', type=str, required=True, help='Id for the Synapse workspace')
parser.add_argument('--synapse_workspace', type=str, required=True, help='Synapse pool name')
parser.add_argument('--batch_storage_account_name', type=str, required=False, help='Name of the Batch Storage Account')
parser.add_argument('--batch_account', type=str, required=False, help="Batch Account name")
parser.add_argument('--batch_pool_name', type=str, required=False, help="Batch Pool name")
parser.add_argument('--linked_key_vault', type=str, required=True, help="Key Vault to be added as Linked Service")
parser.add_argument('--location', type=str, required=False, help="Batch Account Location")
parser.add_argument('--pipeline_name', type=str, required=True, help="Name of the pipeline to package")
parser.add_argument('--pg_db_username', type=str, required=False, help="Username to login to postgres db")
parser.add_argument('--pg_db_server_name', type=str, required=False, help="Server name to login to postgres db")
parser.add_argument('--persistent_volume_claim',
    type=str, required=False,
    default='__env_code__-vision-fileshare',
    help="persistent volume claim object name set up in AKS")
parser.add_argument('--aks_management_rest_url',
    type=str, required=False,
    default='https://management.azure.com/subscriptions/__subscription__/resourceGroups/__env_code__-orc-rg/providers/Microsoft.ContainerService/managedClusters/__env_code__-aks2/runCommand?api-version=2022-02-01',
    help="AKS management rest URL")
parser.add_argument('--base64encodedzipcontent_functionapp_url',
    type=str, required=False,
    help="functionapp url for base64encodedzipcontent"
)

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

def package(pipeline_name: str, tokens_map: dict, modes='batch-account'):

    script_dirname = os.path.dirname(__file__)
    src_folder_path = os.path.join(script_dirname, '../..', 'src', 'workflow', pipeline_name)
    package_folder_path= os.path.join(os.getcwd(), pipeline_name)

    # mode
    mode = 0o766

    # if package folder already exists, delete it before starting a new iteration
    if os.path.exists(package_folder_path):
        shutil.rmtree(package_folder_path)

    # copy the folder structure from src/workflow folder before replacing the 
    # tokens with values
    shutil.copytree(src_folder_path, package_folder_path)

    # read workflow package manifest file and execute manifest
    if os.path.exists(package_folder_path + "/.package"):
        package_manifest_folder = os.path.join(package_folder_path, ".package")
        with open(os.path.join(package_manifest_folder, "manifest.json"), 'r') as jf:
            package_manifest = json.load(jf)
            manifest = package_manifest['modes']
            for mode in modes.split(","):
                package_manifest = manifest.get(mode)
                if package_manifest is not None:
                    for instruction in package_manifest:
                        if instruction == 'exclude':
                            for drop in package_manifest['exclude']:
                                drop_path = os.path.join(package_manifest_folder, drop)
                                if os.path.exists(drop_path):
                                    os.remove(drop_path)
                        if instruction == 'rename':
                            for src, dest in package_manifest['rename'].items():
                                shutil.move(
                                    os.path.join(package_manifest_folder, src),
                                    os.path.join(package_manifest_folder, dest))
                                modified_jdata = {}
                                with open(os.path.join(package_manifest_folder, dest), 'r') as fp:
                                    modified_jdata = json.load(fp)
                                    if modified_jdata.get('name') is not None:
                                        path_splitted = dest.split('/')
                                        name_only_with_extension = path_splitted[-1].split('.')[0]
                                        modified_jdata['name'] = name_only_with_extension
                                with open(os.path.join(package_manifest_folder, dest), 'w') as fp:
                                    json.dump(modified_jdata, fp, indent=4)
                        if instruction == 'removePropertyAtPath':
                            for fileToModify in package_manifest['removePropertyAtPath']:
                                
                                if os.path.exists(os.path.join(os.getcwd(), pipeline_name, fileToModify['file'])):
                                    file = open(os.path.join(os.getcwd(), pipeline_name, fileToModify['file']), 'r')
                                    data = json.load(file)
                                    paths = fileToModify['property']
                                    propertyPath = ''

                                    for path in paths.split('.'):
                                        try:
                                            path = int(path)
                                        except Exception as ex:
                                            pass
                                        if type(path) == int:
                                            propertyPath = f'%s[%s]' % (propertyPath,path)    
                                        else:
                                            propertyPath = f'%s[\'%s\']' % (propertyPath,path)
                                
                                    exec('del data%s' % propertyPath)
                                    file = open(os.path.join(os.getcwd(), pipeline_name, fileToModify['file']), 'w')
                                    json.dump(data, file, indent=10)

        # finally clean up .package folder before zipping it
        shutil.rmtree(package_folder_path + "/.package")
    
    # set of folder names are fixed for synapse pipelines and hence hardcoding them
    for folder in ['linkedService', 'sparkJobDefinition', 'pipeline', 'bigDataPool', 'notebook']:

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
    shutil.make_archive(pipeline_name, 'zip', package_folder_path)

    # finally clean up the package folder
    if os.path.exists(package_folder_path):
        shutil.rmtree(package_folder_path)
    
if __name__ == "__main__":

    if args.modes.find('batch-account') > -1:
        # list of tokens and their values to be replaced
        tokens_map = {
            '__raw_data_storage_account__': args.raw_storage_account_name,
            '__batch_storage_account__': args.batch_storage_account_name,
            '__batch_account__': args.batch_account,
            '__batch_pool_name__': args.batch_pool_name,
            '__linked_key_vault__': args.linked_key_vault,
            '__synapse_storage_account__': args.synapse_storage_account_name,
            '__synapse_pool_name__': args.synapse_pool_name,
            '__synapse_workspace_id__':args.synapse_workspace_id,
            '__synapse_workspace__':args.synapse_workspace,
            '__location__': args.location,
            '__pg_db_username__': args.pg_db_username,
            '__pg_db_server_name__': args.pg_db_server_name
        }
    elif args.modes.find('aks') > -1: 
        # list of tokens and their values to be replaced for aks based pipeline
        tokens_map = {
            '__raw_data_storage_account__': args.raw_storage_account_name,
            '__persistent_volume_claim__': args.persistent_volume_claim,
            '__aks_management_rest_url__': args.aks_management_rest_url,
            '__base64encodedzipcontent_functionapp_url__': args.base64encodedzipcontent_functionapp_url,
            '__linked_key_vault__': args.linked_key_vault,
            '__synapse_storage_account__': args.synapse_storage_account_name,
            '__synapse_pool_name__': args.synapse_pool_name,
            '__synapse_workspace_id__':args.synapse_workspace_id,
            '__synapse_workspace__':args.synapse_workspace,
            '__pg_db_username__': args.pg_db_username,
            '__pg_db_server_name__': args.pg_db_server_name
        }
    else:
        raise ValueError('args.modes should include at least either batch-account or aks.')
    # invoke package method
    package(args.pipeline_name, tokens_map, args.modes)
