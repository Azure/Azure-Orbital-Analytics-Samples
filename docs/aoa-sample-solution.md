## Sample solution

In the reference architecture we have seen how to run the sample code using the Notebook. In this tutorial we will show how to run similar transformation using a python code & Activities from Synapse pipeline. 

Pre-requisites:

1. Create a Synapse workspace
2. Create a Spark pool
3. Install geospatial libraries to the Spark pool
4. In the ADLS Gen2 storage account(ex: aoa), create a container ex: spark-jobs & copy all the folders from the repo under [/src/transforms/spark-jobs/](https://github.com/senthilkungumaraj/Azure-Orbital-Analytics-Samples/tree/ref-solution-delta/src/transforms/spark-jobs/) to this container.

**Exercise 1**

How to run the crop transformation on Synapse?

1. Open [Synapse workspace](https://web.azuresynapse.net/)
2. Go to the **Integrate** hub.
3. Add new resource by clicking the `+` and select **Pipeline**.
4. Under the **Activities** search for *Spark job definition* and drag the activity to the pipeline canvas.
5. Select the Spark job definition activity and give it a name under **General** Ex: Crop
6. Under **Settings**, enter the following details:
     - select `+ New` and give it a name Ex: Crop
     - **Basics**
       - Click the **Language** drop-down and select *PySpark (Python)*, as in this exercise we will be using Python codes.
       - In the **Main definition file**, enter the location of the python code under the container created in the pre-requisites in this format Ex: abfss://spark-jobs@aoa.dfs.core.windows.net/raster_crop/src/crop.py
       - In the **Reference files**, enter the `utils.py` location which is an additional file used by the **Main definition file**. The format is abfss://spark-jobs@aoa.dfs.core.windows.net/raster_crop/src/utils.py
     - **Submission details**
       - Enter the **Apache Spark pool** from the drop-down. Based on the pool selected the rest of the details will be populated. 
7. Once the changes are done, click **Publish** to save the settings. 
8. Under **Command line arguments** add the following arguments and the respective parameters & variables 
	 
	  Arguments | Parameters / Variables
     ----------|-----------|
     `--storage_account_name`      | `@pipeline().parameters.StorageAccountName`       |
     `--storage_account_key`   |`@pipeline().parameters.StorageAccountKey`        |
     `--storage_container`    | `@pipeline().parameters.Prefix` |
     `--src_folder_name`|`@variables('CropSourceFolder')`|
     `--config_file_name` | `config-aoi.json` |
   
     > **NOTE:** The above arguments are required to run the crop function and users can input the values during run time. For `--config_file_name` the input is a json file that is stored under the `config` directory of the respective transformation. Ex: /raster_crop/config/
    
9. Click `Debug` to run the Spark job definition pipeline.
     

**Exercise 2**

How to run the convert transformation on Synapse?

In this exercise, we'll show how to connect the output of a pipeline as input for a transformation on Synapse. For this exercise, we will use the output from crop transformation and feed that as input to the convert function. 

1. In the same way as Exercise 1, select the Spark job definition activity and give it a name under **General** Ex: Convert. Now you'll have 2 actvities on the pipeline canvas.
2. Under **Settings**, enter the following details:
     - select `+ New` and give it a name Ex: Convert
     - **Basics**
       - Click the **Language** drop-down and select *PySpark (Python)*, as in this exercise we will be using Python codes.
       - In the **Main definition file**, enter the location of the python code under the container created in the pre-requisites in this format Ex: abfss://spark-jobs@aoa.dfs.core.windows.net/raster_convert/src/convert.py
     - **Submission details**
       - Enter the **Apache Spark pool** from the drop-down. Based on the pool selected the rest of the details will be populated.
       
3. Once the changes are done, click **Publish** to save the settings.
4. Under **Command line arguments** add the following arguments and the respective parameters & variables 
	 
	  Arguments | Parameters / Variables
     ----------|-----------|
     `--storage_account_name`      | `@pipeline().parameters.StorageAccountName`       |
     `--storage_account_key`   |`@pipeline().parameters.StorageAccountKey`        |
     `--storage_container`    | `@pipeline().parameters.Prefix` |
     `--src_folder_name`|`@variables('ConvertSourceFolder')`|
     `--config_file_name` | `config-img-convert-png.json` |
   
     > **NOTE:** The above arguments are required to run the crop function and users can input the values during run time. For `--config_file_name` the input is a json file that is stored under the `config` directory of the respective transformation. Ex /raster_convert/config/ 
5. Drag the arrow from `Crop` to `Convert` Spark job definition 
    
6. Click `Debug` to run the Spark job definition pipeline.

**Exercise 3**

How to run the tiling transformation on Synapse?

1. In the same way as Exercise 1, select the Spark job definition activity and give it a name under **General** Ex: Tiling. Now you'll have 3 actvities on the pipeline canvas.
2. Under **Settings**, enter the following details:
     - select `+ New` and give it a name Ex: Tiling
     - **Basics**
       - Click the **Language** drop-down and select *PySpark (Python)*, as in this exercise we will be using Python codes.
       - In the **Main definition file**, enter the location of the python code under the container created in the pre-requisites in this format Ex: abfss://spark-jobs@aoa.dfs.core.windows.net/raster_tiling/src/tiling.py
     - **Submission details**
       - Enter the **Apache Spark pool** from the drop-down. Based on the pool selected the rest of the details will be populated.

3. Once the changes are done, click **Publish** to save the settings.
4. Under **Command line arguments** add the following arguments and the respective parameters & variables 
	 
	  Arguments | Parameters / Variables
     ----------|-----------|
     `--storage_account_name`      | `@pipeline().parameters.StorageAccountName`       |
     `--storage_account_key`   |`@pipeline().parameters.StorageAccountKey`        |
     `--storage_container`    | `@pipeline().parameters.Prefix` |
     `--src_folder_name`|`@variables('TilingSourceFolder')`|
     `--file_name`|`output.png`|
     `--tile_size` | `512` |
   
     > **NOTE:** The above arguments are required to run the crop function and users can input the values during run time. Check with Raj if hardcoding can be avoided and also to make it uniform across.

5. Drag the arrow from `Convert` to `Tiling` Spark job definition.
    
6. Click `Debug` to run the Spark job definition pipeline.
7. At this point, we have a unidirectional connection from `Crop` to `Convert` to `Tiling`. All 3 transformations are in the same pipeline, give it a name to the pipeline. Ex: Custom_Vision_Model_Transform_v2

**Exercise 4**

How to run a custom vision AI model on Synapse?

In this exercise, we use the custom vision AI model for object detection over a specific geospatial area of interest. As this exercise deals with models, we create a new pipeline.

1. Follow steps 1 to 3 from Exercise 1
2. Under the **Activities** search for *Data flow* and drag the activity to the new pipeline canvas.
3. Select the Data flow activity and give it a name under **General** Ex: Read Spec Document
4. Under **Settings**, enter the following details:
     - Select `+ New` and give it a name Ex: ReadSpecDocumentFlow
     
     - **Source settings:**
       - Select `Add Source` from the drop-down and configure the source as follows
          - Under `Source settings`, give an *Output stream name*  Ex: source
          - Click `+ New` on the **Dataset**, select `Azure Data Lake Storage Gen2` as the datastore and the data format as `JSON` and create a new linked service. Linked service can also be done beforehand and the instruction to create is documented [here](https://docs.microsoft.com/azure/synapse-analytics/data-integration/data-integration-data-lake#create-linked-services).
     
     - **Sink settings:**
           

## Troubleshoot

[Troubleshoot pipeline orchestration and triggers in Azure Data Factory](https://docs.microsoft.com/azure/data-factory/pipeline-trigger-troubleshoot-guide)

[Troubleshoot Azure Data Factory and Synapse pipelines](https://docs.microsoft.com/azure/data-factory/data-factory-troubleshoot-guide)
