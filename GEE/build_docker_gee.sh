#!/bin/bash

wget https://raw.githubusercontent.com/google/earthengine-api/master/docker/run.sh
wget https://raw.githubusercontent.com/google/earthengine-api/master/docker/license-ee.txt
wget https://raw.githubusercontent.com/google/earthengine-api/master/docker/datalab-ee.txt

docker build -t gee/gee_gdal .

# docker run -d -p 11188:8080 -v /home/josip/gee/content:/content -e PROJECT_ID=gee-for-landgis --name gee_gdal gee/gee_gdal