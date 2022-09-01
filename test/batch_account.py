#!/usr/bin/python3

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import argparse
import json
import subprocess

parser = argparse.ArgumentParser(description='Arguments required to run granting access to batch account')
parser.add_argument('--env_code', type=str, required=True, help='Environment code for the setup deployed')
parser.add_argument('--target_batch_account_name', type=str, required=True, help='Name of pre-provisioned Batch Account')
parser.add_argument('--target_batch_account_resource_group_name', type=str, required=True, help='Resource group name of pre-provisioned Batch Account')
parser.add_argument('--batch_account_role', type=str, required=False, default='Contributor', help='Role to be granted on batch account')
parser.add_argument('--source_synapse_workspace_name', type=str, required=True, help='Source Synapse workspace Name')
args = parser.parse_args()

def execute_azure_cli_command(az_cli_command):
    az_cli = subprocess.run(az_cli_command, shell = True, stdout=subprocess.PIPE, stderr = subprocess.PIPE)
    return az_cli.stdout.decode("utf-8"), az_cli.stderr.decode("utf-8")

def assign_role_to_principal_id(principal_id, role, scope_resource_id):
    az_role_assignment_command = "az role assignment create --assignee " + principal_id + " --role " + role +" --scope " + scope_resource_id
    return execute_azure_cli_command(az_role_assignment_command)

def assign_access_for_batch_account_to_principal_id(principal_id, batch_account_name, batch_account_resource_group_name, role):
    az_batch_account_id_query_command = "az batch account show  --name " + batch_account_name + " --resource-group " + batch_account_resource_group_name
    az_batch_account_id_query_output, az_batch_account_id_query_error = execute_azure_cli_command(az_batch_account_id_query_command)
    batch_account_id = json.loads(az_batch_account_id_query_output)['id']
    if batch_account_id == "":
        return az_batch_account_id_query_error
    _, role_assignment_error = assign_role_to_principal_id(principal_id, role, batch_account_id)
    if role_assignment_error and role_assignment_error.find('WARNING') == -1:
        return role_assignment_error

if __name__ == "__main__":
    source_synapse_workspace_name = args.source_synapse_workspace_name
    source_synapse_workspace_resource_group_name = args.env_code + "-pipeline-rg"

    synapse_managed_identity_query_command = "az synapse workspace show --name " + source_synapse_workspace_name +" --resource-group " + source_synapse_workspace_resource_group_name
    synapse_managed_identity_query_output, synapse_managed_identity_query_error = execute_azure_cli_command(synapse_managed_identity_query_command)
    managedIdentityPrincipalId = json.loads(synapse_managed_identity_query_output)['identity']['principalId']
    if managedIdentityPrincipalId == "":
        print("\nError while querying synapse managed identity command\n")
        print(synapse_managed_identity_query_error)
        exit(1)

    print("\nAssigning " + args.batch_account_role + " role to principal-id \"" + managedIdentityPrincipalId + "\" for synapse workspace on batch account \"" + args.target_batch_account_name + "\"")
    assign_access_to_synapse_mi_error = assign_access_for_batch_account_to_principal_id(managedIdentityPrincipalId, args.target_batch_account_name, args.target_batch_account_resource_group_name, args.batch_account_role)
    if assign_access_to_synapse_mi_error:
        print("\nError\n")
        print(assign_access_to_synapse_mi_error)
        exit(1)

    source_batch_account_query_umi_name = args.env_code + "-orc-umi"
    source_batch_account_query_umi_resource_group_name = args.env_code + "-orc-rg"
    umi_principal_id_query_command = "az identity show --name " + source_batch_account_query_umi_name + " --resource-group " + source_batch_account_query_umi_resource_group_name
    umi_principal_id_output, umi_principal_id_error = execute_azure_cli_command(umi_principal_id_query_command)
    umi_principal_id = json.loads(umi_principal_id_output)['principalId']
    if umi_principal_id == "":
        print("\nError while querying user managed identity command\n")
        print(umi_principal_id_error)
        exit(1)

    print("\nAssigning " + args.batch_account_role + " role to principal-id \"" + umi_principal_id + "\" for deployment umi on batch account \"" + args.target_batch_account_name + "\"")
    assign_access_umi_error = assign_access_for_batch_account_to_principal_id(umi_principal_id, args.target_batch_account_name, args.target_batch_account_resource_group_name, args.batch_account_role)
    if assign_access_umi_error and assign_access_umi_error.find('WARNING') == -1:
        print("\nError\n")
        print(assign_access_umi_error)
        exit(1)
