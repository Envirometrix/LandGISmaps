#!/usr/bin/python
import os, glob
from osgeo import gdal
# Processes a folder of GeoTiff files and converts them to Cloud Optimized GeoTiffs and
# writes them to another folder. Skips files that are already cloud optimized - that have "CO=YES" metadata tag 



in_folder = "/data/layers_to_display/to_process"
out_folder = "/data/layers_to_display/layers1km"

for i in glob.glob(in_folder + "/*.tif"):
    basename  = i.split("/")[-1]
    print("Processing file   " + basename)
    gt = gdal.Open(i)
    co = gt.GetMetadata()["CO"]
    if co == "YES":
    	print("GeoTiff already Cloud Optimized, moving on to next...")
    	continue
    else:
    	if not os.path.exists(out_folder + "/" + basename):
        	print("processing file " + basename)
        	cmd = "gdaladdo -r near {} 2 4 8 16 32 64 128".format(i)
        	os.system(cmd)
        	cmd2 = "gdal_translate -mo \"CO=YES\" -co \"TILED=YES\" -co \"BLOCKXSIZE=512\" -co \"BLOCKYSIZE=512\" -co \"COMPRESS=LZW\" " + \
                " -co \"COPY_SRC_OVERVIEWS=YES\" --config GDAL_TIFF_OVR_BLOCKSIZE 512 {} {}".format(i, out_folder + "/" + basename)
        	os.system(cmd2)
        else:
        	print("File  " + basename)
        	print("already exists in target folder ")

