# Overview of Infrastructure deployment and configuration

The deployment involves the following steps outlined below:

No | Step | Duration (approx.) | Required / Optional
---|------|----------|---------------------
1 | [Preparing to execute the script](./deploy-infrastructure.md#preparing-to-execute-the-script) | 1 minute | required
2 | [Infrastructure Deployment](./deploy-infrastructure.md#infrastructure-deployment) | 10 minutes | required
3 | [Verifying infrastructure resources](./deploy-infrastructure.md#verifying-infrastructure-resources) | 5 minutes | required

Follow the [document](./deploy-infrastructure.md) to understand and execute the infrastructure deployment process.

## Executing the synapse pipeline

We have developed a sample Azure Synapse Pipeline demostrating the use of custom-vision ai-model to process a sample image.

Follow the [document](./using-pipeline.md#executing-the-pipeline) to configure and execute the pipeline.

## AI Model

This solution uses the [Custom Vision Model](/src/aimodels) as a sample AI model for demonstrating end to end Azure Synapse workflow geospatial analysis.

This sample solution uses Custom Vision model to detect pools in a given geospatial data. 

You can use any other AI model for object detection or otherwise to run against this solution with a similar [specification](/src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) or different specification as defined by AI model to integrate in your solution.

Follow the [document](./bring-your-own-ai-model.md) to understand and use a different ai-model for processing with the pipeline.
