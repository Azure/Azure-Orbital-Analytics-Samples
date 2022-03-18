# Custom Vision Model

This document will cover the implementation details for Custom Vision model specifically, the pool detection using this AI Model. The scope of this documentation is limited to running the model inside a Synapse pipeline.

## What does this model do?

This model detects swimming pools in a given Area of Interest. 

## What are the inputs and outputs?

A number of small images in PNG format of size 512 x 512 (or 1024 x 1024) can be passed to the model as input. The input CRS is WGS84 with data from moderate to high resolution image source.

The output contains a number of files that are stored in sub-folders of three file types:

* Images in PNG format, the same as the input file unmodified by the AI Model.
* GeoJson files that contain the image coordinates for a specific PNG tile (512 x 512 or 1024 x 1024 image).
* XML file that holds the geolocation / reference information in latitude & longitude.

## Are additional transformations / processing of output required?

Yes. The output contains the pool location in the image coordinates that needs to be converted into a geolocation. A transformation named `pool-geolocation` is used to perform the final conversion from image coordinates to geolocation.

## Transforms 

The following transforms are required for the Custom Vision model. Some of these transformations are AI model specific and some are data source specific. 

* Mosaic - stitch multiple geotiff files into one single geotiff file.
* Crop - crop the geotiff to the Area of Interest represented as polygon.
* Convert to PNG - convert the geotiff to PNG file format.
* Chipping - cuts the large PNG file into multiple smaller PNG files (512 x 512 or 1024 x 1024).