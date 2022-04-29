# Spark Job Troubleshooting

## Invalid Area of Interest passed as parameter

Error:

raise ValueError('Input shapes do not overlap raster.')
ValueError: Input shapes do not overlap raster.

![Invalid Area of Interest passed as parameter](./images/spark-job-crop-aoi-invalid-error.png)

Cause:

You have submitted a raster file (tif) that does not have any portion of its data falling within the Area of Interest (AOI) that you passed as a parameter.

Solution:

- Verify the aoi parameter passed.
- Verify the Raster file that you have submitted.



