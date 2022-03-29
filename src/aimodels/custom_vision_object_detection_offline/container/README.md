# Custom Vision - Prediction

### Overview
This container allows users to pass images through General (Compact) Domain Azure Custom Vision Object Detection model and retrieve the predictions from that model. Users can Train the Model using Custom Vision and then export the trained model as a container from Custom Vision Portal and place the contents of app folder inside src folder.

This containers runs in an offline manner and does not require communication with custom vision service. Inference is done within the container and specifically, two outputs are returned to user :


* JSON - One JSON is returned for every image passed through the Custom Vision model. This JSON contains <b>all</b> model detections for the given image. For example, an image passed through a pool detection Custom Vision model will return the following JSON with one detection:
    
    {"id": "e8526e8a-6e9a-433f-9ff2-0820f18ffc9a", 
     "project": "c3c8d02c-e05c-49ea-9a87-fb85975233a9", 
     "iteration": "cb0011d3-9e9b-4d1e-abf2-4fe51b588520", 
     "created": "2021-03-19T01:39:39.675Z", 
     "predictions": 
         [
             {"probability": 0.9973912, 
              "tagId": "00005547-553e-4058-a5a2-cafe7e5c822d", 
              "tagName": "pool", 
              "boundingBox": {
                   "left": 0.9580524, 
                   "top": 0.7763942, 
                   "width": 0.02493298, 
                   "height": 0.035517573
                   }
              }
         ]
    }

* Image - A new image is also stored in a directory with all detections (that are above a user specified probability threshold) highlighted as in this example:

![Pool Detect Example](./examples/out/img/test2.png "Pool Detection Example")

### Model Configuration
Model selection and specifications are defined in the`/app/data/config.json` file. Within this file users can define:

* prob_cutoff - The threshold a detection must meet in order for its bounding box to be drawn on the output image (note all detections will still be included in the JSON regardless of their probability).
* tag_type - The type of tag (given that custom vision models can be trained on multiple tags) that should be highlighted in the output image. This should be one of the entries found in `labels.txt` under `src` folder.
* bbox_color - The color of the bounding boxes around detections in the output image (default is red)
* bbox_width - The width of the bounding boxes around detections in the output image (default is 1)


### Docker Build & Run
In order to build and run the container use the included `build.sh` and `run.sh` files. Within the run.sh:

- Input files are provided at container runtime by mounting the local folder with images in the container’s `/app/data/in` directory.
- The user's local config file is mounted in the container at `/app/data/config.json`
- Output files are written to the container's `/app/data/out` which can be mounted to a local output folder