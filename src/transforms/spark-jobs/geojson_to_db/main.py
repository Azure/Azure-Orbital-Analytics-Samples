# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import argparse
import json
import psycopg2
from azure.storage.blob import BlobServiceClient
from notebookutils import mssparkutils
from pyspark.sql import SparkSession

# Collect args
parser = argparse.ArgumentParser(description='Arguements required to run geojson to postgres script')
parser.add_argument('--storage_account_name', type=str, required=True, help='Name of the storage account name where the input data resides')
parser.add_argument('--container_name', type=str, required=False, help='Container that host the data file')
parser.add_argument('--folder_path', type=str, required=False, help='Path of the folder relative to the container')

parser.add_argument('--db_username', type=str, required=False, help='Username of the database for authentication')
parser.add_argument('--db_host', default=None, required=True, help='Full host name of the database server')
parser.add_argument('--db_name', default=None, required=False, help='Name of the database')

parser.add_argument('--key_vault_name', type=str, required=True, help='Name of the Key Vault that stores the secrets')
parser.add_argument('--storage_account_key_secret_name', type=str, required=True, help='Name of the secret in the Key Vault that stores storage account key')
parser.add_argument('--linked_service_name', type=str, required=True, help='Name of the Linked Service for the Key Vault')
parser.add_argument('--db_password_secret_name', type=str, required=True, help='Name of the secret in the Key Vault that stores the database password')

#Parse Args
args = parser.parse_args()

def save_blob(file_name: str,file_content):

    # Get full path to the file
    download_file_path = file_name

    # for nested blobs, create local path as well!
    # os.makedirs(os.path.dirname(download_file_path), exist_ok=True)
    with open(download_file_path, "wb") as file:
      file.write(file_content)

def download_file_from_storage_account(storage_account_name: str, storage_account_key: str, container_name: str, folder_path: str,  file_name: str):

    storage_account_url = f'https://{storage_account_name}.blob.core.windows.net'

    blob_service_client_instance = BlobServiceClient(
        account_url=storage_account_url, credential=storage_account_key)

    blob_client_instance = blob_service_client_instance.get_blob_client(
        container_name, f'{folder_path}/{file_name}', snapshot=None)

    blob_data = blob_client_instance.download_blob()
    
    data = blob_data.readall()

    save_blob(file_name, data)

if __name__ == "__main__":

    sc = SparkSession.builder.getOrCreate()
    token_library = sc._jvm.com.microsoft.azure.synapse.tokenlibrary.TokenLibrary

    storage_account_key = token_library.getSecret(args.key_vault_name, args.storage_account_key_secret_name, args.linked_service_name)
    db_password = token_library.getSecret(args.key_vault_name, args.db_password_secret_name, args.linked_service_name)

    mssparkutils.fs.mount(
        f'abfss://{args.container_name}@{args.storage_account_name}.dfs.core.windows.net', 
        f'/{args.container_name}', 
        {"accountKey": storage_account_key}
    )

    mssparkutils.fs.unmount(f'/{args.container_name}') 
    files = mssparkutils.fs.ls(f'abfss://{args.container_name}@{args.storage_account_name}.dfs.core.windows.net/{args.folder_path}')

    try:
        connection = psycopg2.connect(user=args.db_username,
                                    password=db_password,
                                    host=args.db_host,
                                    port="5432",
                                    database=args.db_name,
                                    sslmode='require',
                                    sslrootcert='/opt/src/BaltimoreCyberTrustRoot.crt.pem')
        cursor = connection.cursor()

        for file in files:
            if not file.isDir and file.name.endswith('.geojson'):

                download_file_from_storage_account(args.storage_account_name, storage_account_key, args.container_name, args.folder_path, file.name)

                # Opening JSON file
                f = open(file.name)

                # returns JSON object as a dictionary
                json_data = json.load(f)
                data = json.dumps(json_data)

                postgres_insert_query = """
                    WITH data AS (SELECT '__data_from_file__'::json AS fc)
                    INSERT INTO aioutputmodelschema.cvmodel (id, location, probability, tagid, tagname, tagtype, tile)
                    (SELECT
                    row_number() OVER () AS id,
                    ST_SetSRID(ST_AsText(ST_GeomFromGeoJSON(feat->>'geometry')), 4326) AS location,
                    (feat->'properties'->'probability')::jsonb::numeric AS probability,
                    feat->'properties'->'tag_id' AS tagid,
                    feat->'properties'->'tag_name' AS tagname,
                    feat->'properties'->'tag_type' AS tagtype,
                    feat->'properties'->'tile' AS tile
                    FROM (
                    SELECT json_array_elements(fc->'features') AS feat
                    FROM data
                    ) AS f);
                    """
                postgres_insert_query = postgres_insert_query.replace('__data_from_file__', data)

                cursor.execute(postgres_insert_query)

                connection.commit()
                count = cursor.rowcount
                print(f'{count} records from {file.name} were successfully inserted into the cvmodel table')

    except (Exception, psycopg2.Error) as error:
        print("Failed to insert record into cvmodel table", error)

    finally:
        # closing database connection.
        if connection:
            cursor.close()
            connection.close()
            print("PostgreSQL connection is closed")