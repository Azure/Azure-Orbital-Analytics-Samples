FROM python:3.7-slim

ENV APP_INPUT_DIR="data/in"
ENV APP_OUTPUT_DIR="data/out"
ENV APP_CONFIG_DIR="data/config.json"
RUN mkdir -p $APP_INPUT_DIR $APP_OUTPUT_DIR

COPY src/requirements.txt ./requirements.txt

RUN pip install -U pip
RUN cat requirements.txt | xargs -n 1 -L 1 pip install --no-cache-dir

COPY src/ ./

CMD python ./custom_vision.py
