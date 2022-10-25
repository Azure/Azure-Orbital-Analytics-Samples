## Using AI-Models

There are three ways to load an AI Model with this pipeline. One can use one of the three methods listed below.

### Use the publicly hosted Custom Vision Model as GitHub Packages. 

No additional steps are required for this approach. Custom Vision Model is containerized image that can be pulled from `docker pull ghcr.io/azure/azure-orbital-analytics-samples/custom_vision_offline:latest`.

The [Specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) in this repository already points to the publicly hosted GitHub Registry.

### Host public Custom Vision Model on your Container Registry

In order to use this method one would need to do one of the following methods to get the ai-model docker image
- use `registry` property to pass credentials (requires update to the pipeline) 
- Configure Batch Account pool with the ACR credentials when setting up the Batch Account pool.

Run following command to pull and push the image to your Container Registry.

```bash

docker pull ghcr.io/azure/azure-orbital-analytics-samples/custom_vision_offline:latest

docker tag ghcr.io/azure/azure-orbital-analytics-samples/custom_vision_offline:latest <container-registry-name>.azurecr.io/custom_vision_offline:latest

az acr login --name <container-registry-name>

docker push <container-registry-name>.azurecr.io/custom_vision_offline:latest

```

Update the `algImageName` value in [Specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) to point to the new image location.

### BYOM (Bring-your-own-Model) and host it on your Container Registry.

In order to use this method one would need to do one of the following methods to get the ai-model docker image
- use `registry` property to pass credentials (requires update to the pipeline) 
- Configure Batch Account pool with the ACR credentials when setting up the Batch Account pool.

If you have the image locally, run the shell cmds below to push the image to your Container Registry.

```bash

docker tag custom_vision_offline:latest <container-registry-name>.azurecr.io/custom_vision_offline:latest

az acr login --name <container-registry-name>

docker push <container-registry-name>.azurecr.io/custom_vision_offline:latest

```
Update the `algImageName` value in [Specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) to point to the new image location.

## Using Private Container Registry

When using a private Container Registry, update `containerSettings` property in your [Custom Vision Object Detection](/src/workflow/pipeline/Custom%20Vision%20Object%20Detection.json) pipeline and add the following sub-property in order to authenticate to Container Registry :
```json
"registry": {
        "registryServer": "",
        "username": "",
        "password": ""
    }
```

The above change will need to be made to the `Custom Vision Model Transform` pipeline. Look for activity named `Custom Vision` of type Web activity and update the body property (under Settings tab) for that activity.

[Specification document](../src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) and [Configuration file](../src/aimodels/custom_vision_object_detection_offline/config/config.json) required to run the Custom Vision Model.

- Specification document - This solution has a framework defined to standardized way of running AI Models as containerized solutions. A Specification document works as a contract definition document to run an AI Model.

- Configuration file - Each AI Model may require one or more parameters to run the model. This parameters driven by the end users are passed to the AI Model in the form of a configuration file. The schema of these configuration file is specific to the AI Model and hence we provide a template for the end user to plug-in their values.