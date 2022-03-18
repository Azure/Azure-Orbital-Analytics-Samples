# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# Import the required packages
from time import process_time
from time import time
import os, json
from PIL import Image, ImageDraw
import time
import pathlib
import logging
import shutil
import random
from predict import initialize, predict_image

logger = logging.getLogger("pool-detector")

# Defining the required functions
def pred_bbox_coord(pred, img_width, img_height):

    # Return top left bbox coordinate
    top_left = (round(pred['boundingBox']['left']*img_width),round(pred['boundingBox']['top']*img_height))

     # Return bottom right bbox coordinate
    lower_right = (round(top_left[0]+(pred['boundingBox']['width']*img_width)),round(top_left[1]+(pred['boundingBox']['height']*img_height)))

    return((top_left, lower_right))

def img_with_preds(raw_img, results_dict, prob_cutoff, tag_type, bbox_color='red', bbox_width=1):

    # Extract the image size
    img_width = raw_img.size[0]
    img_height = raw_img.size[1]

    # Create a new version of the image to draw on
    draw = ImageDraw.Draw(raw_img)

    # For every prediction
    for pred in results_dict['predictions']:

        # If the prediction is of the correct type and meets the confidence threshold
        if pred['probability']>=prob_cutoff and pred['tagName']==tag_type:


            pred_bbox = pred_bbox_coord(pred, img_width, img_height)
            draw.rectangle(pred_bbox, fill=None, outline=bbox_color, width=bbox_width)

    return(raw_img)


def retry_with_backoff(func, image_path,  retries = 4, backoff_in_seconds = 0.5):
  attempts = 0
  while True:
    try:
        timeStart = time.time()
        logger.info("  Attempt {}".format(attempts))
        img=Image.open(image_path)
        timeEnd = time.time()
        logger.info("opening image: {}".format(timeEnd-timeStart))
        return func(img)
    except:
      if attempts == retries:
        logger.info("  Time is Up, attempt {} failed and maxed out retries".format(attempts))
        raise
      else:
        #sleep = backoff * (2^attempts) + random subsecond increment
        sleep = (backoff_in_seconds * 2 ** attempts + random.uniform(0, 1))
        logger.info(" Sleep :", str(sleep) + "s")
        time.sleep(sleep)
        attempts += 1
        pass

def get_custom_vision_preds(input_path, output_path, config):

    pathlib.Path(f"{output_path}/img").mkdir(parents=True, exist_ok=True)
    pathlib.Path(f"{output_path}/json").mkdir(parents=True, exist_ok=True)
    pathlib.Path(f"{output_path}/other").mkdir(parents=True, exist_ok=True)

    save_configs = config.get("json", False)
    if save_configs:
        logger.info("saving results to json")

    logger.info(f"looking for images in {input_path}")
    # For every image in the input directory
    extensions = ( "jpg","png","bmp","gif" )
    for input_file in os.scandir(input_path):
        t1_start = time.time()
        logger.info(input_file.name)
        counter = 1
        # Open the image
        with open(input_file.path, mode="rb") as img:
            if input_file.path.endswith(extensions):
                # Send the image to the custom vision model
                #Timer to evaulate request time for detect image
              
                #send an image to custom vision model with retry control loop
                requestStart = time.time()
                results = retry_with_backoff(predict_image, input_file.path)
                requestEnd = time.time()
                logger.info("Request time: {}".format(requestEnd-requestStart))
                pilStart= time.time()
                # Collect the resulting predictions
                results_dict = results #.as_dict()
                # Open the image in Pil
                pil_img = Image.open(img)
                pilEnd = time.time()
                logger.info("pil_img time: {}".format(pilEnd-pilStart))


                predStart = time.time()
                # Append the detection bboxes to the PIL image
                pil_img = img_with_preds(pil_img,
                                        results_dict,
                                        config['prob_cutoff'],
                                        config['tag_type'],
                                        bbox_color=config['bbox_color'],
                                        bbox_width=config['bbox_width'])
                predEnd = time.time()
                logger.info("pred time: {}".format(predEnd-predStart))

                # Save off the image with the detections
                saveStart = time.time()
                pil_img.save(os.path.join(output_path,'img',input_file.name))

                # Save off a JSON with the results
                if save_configs:
                    json_name = '.'.join(input_file.name.split('.')[:-1])+'.json'
                    with open(os.path.join(output_path,'json',json_name),'w') as json_output:
                        json.dump(results_dict,json_output)
                saveEnd = time.time()
                logger.info("save time: {}".format(saveEnd-saveStart))

            else:
                print("File is not an image, copying to destination directory")
                sourcePath = input_file.path
                destinationPath = os.path.join(output_path,'other',input_file.name)

                print(f"Copying file from {sourcePath} to {destinationPath}")
                shutil.copyfile(sourcePath,destinationPath)
                print(f"Copied file from {sourcePath} to {destinationPath}")

        t1_stop = time.time()
        detect_img_requestTime = t1_stop-t1_start
        logger.info("{} process time: {}".format(input_file.name, detect_img_requestTime))
    logger.info("done")

# Run
if __name__ == '__main__':
    logger.setLevel("DEBUG")
    logger.addHandler(logging.StreamHandler())
    logger.handlers[0].setFormatter(logging.Formatter("[%(asctime)s] %(msg)s"))

    # Define Input and Output Paths
    input_path = os.path.abspath(os.environ['APP_INPUT_DIR'])
    output_path = os.path.abspath(os.environ['APP_OUTPUT_DIR'])
    config_path = os.path.abspath(os.environ['APP_CONFIG_DIR'])

    os.makedirs(input_path, exist_ok=True)
    os.makedirs(output_path, exist_ok=True)

    logger.info(f"input  {input_path}")
    logger.info(f"output {input_path}")
    logger.info(f"config {config_path}")

    # Collect items from the config file
    with open(config_path) as config:
        config = json.load(config)

    logger.info(f"using config {config}")
    initialize() #Loads Offline CV model.pb
    get_custom_vision_preds(input_path, output_path, config)