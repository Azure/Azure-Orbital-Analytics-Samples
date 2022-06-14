# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import argparse
import json
import os

parser = argparse.ArgumentParser(description='Arguments required to find dependencies')
parser.add_argument('--file_name', type=str, required=True, help='Filename to find references')
parser.add_argument('--resource_group_name', type=str, required=True, help='Resource group to find references')
parser.add_argument('--workspace_name', type=str, required=True, help='Synapse workspace name')
args = parser.parse_args()

def add_element_to_dictionary_list(found_value, found_list):
    for element_in_list in found_list:
        if found_value['name'] == element_in_list['name'] and found_value['type'] == element_in_list['type']:
            return
    found_list.append(found_value)

def check_dictionary(my_dict, find_key, found_list):
    if not (type(my_dict) is dict or type(my_dict) is list):
        return
    for key,value in my_dict.items():
        if key == find_key:
            if my_dict['type'] != "IntegrationRuntimeReference":
                found_value={}
                found_value['name']=value
                found_value['type']=my_dict['type'][:-9]
                add_element_to_dictionary_list(found_value, found_list)
        if type(value) is dict:
            check_dictionary(value, find_key, found_list)
        if type(value) is list and len(value)>0:
            values = []
            for item in value:
                check_dictionary(item, find_key, found_list)

def check_component_exists(workspace_name, component_name, component_type, resource_group_name):
    command = ""
    component_type = component_type.lower()
    if component_type == "dataflow":
        command =  "az synapse data-flow show --name \""+ component_name + "\" --workspace-name " + workspace_name
    elif component_type == "dataset":
        command =  "az synapse dataset show --name \""+ component_name + "\" --workspace-name " + workspace_name
    elif component_type == "bigdatapool":
        command = "az synapse spark pool show --name \""+ component_name + "\" --workspace-name " + workspace_name + " --resource-group " + resource_group_name
    elif component_type == "sparkjobdefinition":
        command = "az synapse spark-job-definition show --name \""+ component_name + "\" --workspace-name " + workspace_name
    elif component_type == "LinkedService":
        command = "az synapse linked-service show --name \""+ component_name +"\" --workspace-name "+ workspace_name
    elif component_type == "pipeline":
        command = "az synapse pipeline show --name \""+ component_name +"\" --workspace-name " +workspace_name
    return command        


def list_dirs(dir_name):
    onlydirs = [f for f in os.listdir(dir_name) if not os.path.isfile(os.path.join(dir_name, f))]
    return onlydirs

def list_files(dir_name):
    onlyfiles = [f for f in os.listdir(dir_name) if os.path.isfile(os.path.join(dir_name, f))]
    return onlyfiles

def check_name_attribute(file_name, check_name):
    if os.path.splitext(file_name)[1] != '.json':
        return False
    with open(file_name, 'r') as freader:
        my_dict = json.load(fp=freader)
        if 'name' in my_dict.keys():
            if my_dict['name'] == check_name:
                return True
    return False

def get_component_file(component_name, directory_name):
    for dir_name in list_dirs(directory_name):
        if not dir_name.startswith('.'):
            files_list = list_files(os.path.join(directory_name, dir_name))
            for file_name in files_list:
                actual_file_name = os.path.join(directory_name, dir_name, file_name)
                if check_name_attribute(actual_file_name, component_name):
                    return actual_file_name
    return ""

def get_component_dependency_files(component_file_name):
    with open(component_file_name, 'r') as freader:
        my_dict = json.load(fp=freader)
    result_list = []
    file_names = []
    check_dictionary(my_dict, "referenceName", result_list )
    base_dir_name=os.path.dirname(os.path.dirname(args.file_name))
    for items in result_list:
        file_names.append(get_component_file(items['name'], base_dir_name))
    return file_names

def install_dependent_component(workspace_name, component_name, component_type, resource_group_name, file_name):
    command = ""
    component_type = component_type.lower()
    if component_type == "dataflow":
        command =  "az synapse data-flow create --name \""+ component_name + "\" --workspace-name " + workspace_name + " --file @\"" + file_name + "\""
    elif component_type == "dataset":
        command =  "az synapse dataset create --name \""+ component_name + "\" --workspace-name " + workspace_name + " --file @\"" + file_name + "\""
    elif component_type == "bigdatapool":
        command = ""
    elif component_type == "sparkjobdefinition":
        tmp_job_definition_file_name = "/tmp/spark-job-"+component_name+".json"
        create_job_definition_file_command = "jq '.properties' \"" + file_name + "\" > \"" + tmp_job_definition_file_name + "\""
        command =  create_job_definition_file_command + "; az synapse spark-job-definition create --name \""+ component_name + "\" --workspace-name " + workspace_name + " --file @\"" + tmp_job_definition_file_name + "\""
    elif component_type == "linkedservice":
        command = "az synapse linked-service create --name \""+ component_name +"\" --workspace-name "+ workspace_name + " --file @\"" + file_name + "\""
    elif component_type == "pipeline":
        command = "az synapse pipeline create --name \""+ component_name +"\" --workspace-name " +workspace_name + " --file @\"" + file_name + "\""
    elif component_type == "notebook":
        tmp_notebook_file_name = "/tmp/spark-notebook-"+component_name+".json"
        create_notebook_file_command = "jq '.properties' \"" + file_name + "\" > \"" + tmp_notebook_file_name + "\""
        command =  create_notebook_file_command + "; az synapse notebook create --name \""+ component_name + "\" --workspace-name " + workspace_name + " --file @\"" + tmp_notebook_file_name + "\""
    return command  

def find_missing_components(component_dictionary_list, component_file_name):
    if len(component_dictionary_list) == 0:
        with open(component_file_name, 'r') as freader:
            my_dict = json.load(fp=freader)
        check_dictionary(my_dict, "referenceName", component_dictionary_list)

    if len(component_dictionary_list) > 0:
        base_dir_name=os.path.dirname(os.path.dirname(component_file_name))
        dependent_item_count = 0
        for dependent_component in component_dictionary_list:
            dependent_component_filename = get_component_file(dependent_component['name'], base_dir_name)
            dependent_component_dictionary_list = []
            find_missing_components(dependent_component_dictionary_list, dependent_component_filename)
            for dependent_component in dependent_component_dictionary_list:
                add_element_to_dictionary_list(dependent_component, component_dictionary_list)
            dependent_item_count = dependent_item_count + 1
    return

def sort_dependency_list(component_dictionary_list, component_file_name, list_updated):
    if list_updated and list_updated == "no":
        return component_dictionary_list
    if component_dictionary_list == []:
        find_missing_components(component_dictionary_list, component_file_name)
    base_dir_name=os.path.dirname(os.path.dirname(component_file_name))
    dependent_component_indices_list = []
    dependent_component_index = 0
    for dependent_component in component_dictionary_list:
        dependent_component_filename = get_component_file(dependent_component['name'], base_dir_name)
        dependent_component_dictionary_list = []
        with open(dependent_component_filename, 'r') as freader:
            my_dict = json.load(fp=freader)
        check_dictionary(my_dict, "referenceName", dependent_component_dictionary_list)
        if len(dependent_component_dictionary_list) > 0:
            dependent_component_indices_list.append(dependent_component_index)
        dependent_component_index = dependent_component_index + 1
    lets_create_new_list = []
    for dependent_index in range(len(component_dictionary_list)):
        if dependent_index not in dependent_component_indices_list:
            lets_create_new_list.append(component_dictionary_list[dependent_index])
    for dependent_index in dependent_component_indices_list:
        lets_create_new_list.append(component_dictionary_list[dependent_index])
    if lets_create_new_list == component_dictionary_list:
        return sort_dependency_list(lets_create_new_list, component_file_name, "no")
    return sort_dependency_list(lets_create_new_list, component_file_name, "yes")

def get_ordered_dependency_list(component_file_name):
    component_dictionary_list = []
    sorted_list = sort_dependency_list(component_dictionary_list, component_file_name, "new")
    base_dir_name = os.path.dirname(os.path.dirname(component_file_name))
    ordered_dependency_list = []
    dependent_dependency_list = []
    for dependent_component in sorted_list:
        dependent_component_filename = get_component_file(dependent_component['name'], base_dir_name)
        dependent_component_dictionary_list = []
        with open(dependent_component_filename, 'r') as freader:
            my_dict = json.load(fp=freader)
        check_dictionary(my_dict, "referenceName", dependent_component_dictionary_list)
        if len(dependent_component_dictionary_list) == 0:
            ordered_dependency_list.append(dependent_component)
        if len(dependent_component_dictionary_list) > 0:
            dependent_component['dependency_list'] = dependent_component_dictionary_list
            dependent_dependency_list.append(dependent_component)
    get_fixed_dependency_list(dependent_dependency_list, ordered_dependency_list)
    return ordered_dependency_list

def get_fixed_dependency_list(dependent_list, ordered_list):
    i = 0
    found_dependency_indices = []
    check_new_list = []
    for new_component in dependent_list:
        dependency_met = True
        for dependent_component in new_component['dependency_list']:
            partial_dependency_met = False
            for check_component in ordered_list:
                if dependent_component['name'] == check_component['name']:
                    partial_dependency_met = True
                    break
            if not partial_dependency_met:
                dependency_met = False
                continue
        if dependency_met:
            ordered_list.append({'name': new_component['name'], 'type': new_component['type']})
            found_dependency_indices.append(i)
        i = i + 1
    for x in range(len(dependent_list)):
        if x not in found_dependency_indices:
            check_new_list.append(dependent_list[x])
    if check_new_list == []:
        return
    get_fixed_dependency_list(check_new_list, ordered_list)

def find_name_and_type_of_component_file(component_file_name):
    component_name = ""
    component_type = ""
    with open(args.file_name, 'r') as freader:
        my_dict = json.load(fp=freader)
    if 'name' in my_dict:
        component_name = my_dict['name']
    if 'type' in my_dict:
        component_type = my_dict['type'].split("/")[-1][:-1]
    return component_name, component_type

if __name__ == "__main__":
    args_component_name, args_component_type = find_name_and_type_of_component_file(args.file_name)
    # This is done for all the dependencies
    final_fixed_list = get_ordered_dependency_list(args.file_name)
    base_dir_name=os.path.dirname(os.path.dirname(args.file_name))
    install_dependency_commands_list = []
    for items in final_fixed_list:
        install_command = install_dependent_component(args.workspace_name, items['name'], items['type'], args.resource_group_name, get_component_file(items['name'], base_dir_name))
        if install_command != "":
            install_dependency_commands_list.append(install_command)
    if args_component_type != "":
        install_dependency_commands_list.append(install_dependent_component(args.workspace_name, args_component_name, args_component_type, args.resource_group_name, get_component_file(args_component_name, base_dir_name)))

    for install_command in install_dependency_commands_list:
        print(install_command)
