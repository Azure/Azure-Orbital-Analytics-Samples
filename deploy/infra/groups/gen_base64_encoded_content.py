# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import azure.functions as func
import base64
from zipfile import ZipFile
import json

test_data = '''
{
    "apiVersion": "batch/v1",
    "kind": "Job",
    "metadata": {
      "name": "aoi-cv-task",
      "namespace": "vision",
      "labels": {
        "app": "busybox"
      }
    },
    "spec": {
      "ttlSecondsAfterFinished": 10,
      "template": {
        "spec": {
          "containers": [
            {
              "name": "busybox",
              "image": "busybox",
              "args": [
                "bin/sh",
                "-c",
                "echo test;sleep 30; exit 0"
              ]
            }
          ],
          "restartPolicy": "Never"
        }
      }
    }
}
'''

def create_job_file(content='', output_file_name='run.json'):
    with open(output_file_name, 'w') as output:
        output.write(content)

def create_zip_job_file(zip_file_name='run.zip', lst_files=['run.json']):
    with ZipFile(zip_file_name, 'w') as zipObj:
        for file in lst_files:
            zipObj.write(file)

def gen_base64_encoded_content(zip_file_name='run.zip'):
    with open(zip_file_name, 'rb') as input_zip_file:
        base64content = base64.b64encode(input_zip_file.read()).decode('ascii')
    return base64content

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    json_body = req.get_json()
    body_in_str = json.dumps(json_body)
    filename = 'run.json'
    if (json_body.get("metadata") is not None) and (json_body.get("metadata").get("name") is not None):
        filename = json_body["metadata"]["name"] + '.json'
        logging.info("filename set to {filename}")
    create_job_file(body_in_str, filename)
    create_zip_job_file('run.zip', [filename])
    base64_encoded_content = gen_base64_encoded_content()
    return func.HttpResponse(f"{base64_encoded_content}")
