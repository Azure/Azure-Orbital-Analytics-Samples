# Project

This repository contains sample solution that demonstrates how to deploy and execute [Geospatial Analysis with Azure Synapse Analytics]
(https://aka.ms/synapse-geospatial-analytics) workload on your Azure tenant. We recommend that you read the document on "Geospatial Analysis with Azure Synapse Analytics" before deploying this solution.

Disclaimer: The solution and samples provided in this repository is for learning purpose only. They're intended to explore the possibilites of the Azure Services and are a starting point to developing your own solution. We recommend that you follow the security best practices as per the Microsoft documentation for individual services.

# Getting Started

Start by following the steps in the `deploy` folder to setup the Azure resources required to build your pipeline.

Import the pipeline under the `workflow` folder to your Azure Synapse Analytics instance's workspace. Alternatively, you can copy the files to your repository (git or Azure DevOps) and link the repository to your Azure Synapse Analytics workspace. 

Sample pipelines are provided that include the following AI Model:

### a. AI model

This solution uses the Custom Vision Model as a sample AI model for demonstrating end to end Azure Synapse workflow geospatial analysis. This sample solution uses Custom Vision model to detect pools in a given geospatial data. 
You can use any other AI model for object detection or otherwise to run against this solution with a similar [specification](/src/aimodels/custom_vision_object_detection_offline/specs/custom_vision_object_detection.json) or different specification as defined by AI model to integrate in your solution.  

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
