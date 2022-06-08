# CI/CD for infrastructure deployment & synapse pipelines

These tests would deploy the Azure infrastructure using bicep templates and runs the synapse pipeline to perform test on the checked-in code.

We are also making use of a pre-provisioned batch account and we deploy a batch-account pool and job on batch-account to override some quota challenges faced in our Azure subscription.

## Github secrets and credentials

We make use of github secrets to provide credentials and other secret information to run the pipeline.

Following is the list of secrets we are currently using:

- AZURE_CREDENTIALS:
    These are the credentials used accessing azure cloud. Follow the instructions on the [documentation](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Clinux#use-the-azure-login-action-with-a-service-principal-secret) to create and use the credentials.

- CI_BATCH_ACCOUNT_NAME:
    This is the pre-provisioned batch account name.

- CI_STORAGE_ACCOUNT:
    This is the storage account where we have stored the configuration files and the input file.
    Following is the list of configuration files stored on storage account:
    - `custom-vision-model-v2\config\config.json`:  Config file
    - `custom-vision-model-v2\config\custom_vision_object_detection.json`: Config file
    - `custom-vision-model-v2\raw/sample_4326.tif`: Input file

    For more information on which files need to be in storage account take a look at [README](../deploy/README.md#running-the-pipeline-custom-vision-model-v2)

- AAD_GROUP_PRINCIPAL_ID:
    This is the principal id for team group on azure to be granted `Synapse Administrator` role.
    Keep it blank if it is of no use to you, and scripts will skip it.

## Github secrets and fork repositories

Follow the [link](https://docs.github.com/en/actions/security-guides/encrypted-secrets) to learn more about the github secrets.

However, with the exception of GITHUB_TOKEN, secrets are not passed to the runner when a workflow is triggered from a forked repository.

When contributing to the respository and creating the PRs via fork repositories users are suggested to create above listed secrets with appropriate credentials.

## Creating github secrets

1. On GitHub, navigate to the main page of the repository.
2. Under your repository name, click on the "Settings" tab.
3. In the left sidebar, click Secrets, then click Actions.
4. On the right bar, click on "New repository secret".
5. Type a name for your secret in the "Name" input box.
6. Type the value for your secret in the "Value" input box.
7. Click Add secret. 
