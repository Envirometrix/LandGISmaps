## download and resampling of Version 4 DMSP-OLS Nighttime Lights Time Series (https://ngdc.noaa.gov/eog/dmsp/downloadV4composites.html)
## tom.hengl@envirometrix.net

library(R.utils)
library(rgdal)
library(XML)
library(RCurl)
library(parallel)

## get a list of files available on server:
URL = "https://ngdc.noaa.gov/eog/dmsp/downloadV4composites.html"
a <- getURL(URL)
doc <- htmlTreeParse(a, useInternalNodes = TRUE)
L = unlist(xpathApply(doc, "//a", xmlGetAttr, "href"))
Ld = L[grep(".tar", L)]
## 34 files

## download files:
for(i in 1:length(Ld)){
 if(is.na(file.info(basename(Ld[i]))$size)){
  download.file(Ld[i], destfile=basename(Ld[i]))
 }
}

## untar:
tar.lst = list.files(pattern=glob2rx("*.tar$"), full.names=TRUE)
mclapply(1:length(tar.lst), function(i){ try(untar(tar.lst[i], extras="--keep-newer-files")) }, mc.cores=6)
gz.lst = list.files(pattern=glob2rx("*.gz$"), full.names=TRUE)
mclapply(1:length(gz.lst), function(i){ try(R.utils::gunzip(gz.lst[i])) }, mc.cores=6)
## derived PCs using SAGA GIS:
tif.lst <- list.files(pattern=glob2rx("*stable_lights.*.tif$"))
source("/mnt/DATA/LandGIS/R/LandGIS_functions.R")
save.image()
GDALinfo(tif.lst[1])
r = raster("/mnt/DATA/LandGIS/upscaled1km/lcv_admin0_fao.gaul_c_1km_s0..0cm_2015_v1.0.tif")
r
te = as.vector(extent(r))[c(1,3,2,4)]
saga_grid_stats(in.tif.lst=tif.lst, out.tif.lst=paste0("PC", 1:3, ".v4b_web.stable_lights.avg_vis.tif"), cleanup=TRUE, tr=res(r)[1], te=te, out.ot="Int16", d.lst=rep(-32767, length(in.tif.lst)), a_nodata=-32768, pca=TRUE)
GDALinfo("PC1.v4b_web.stable_lights.avg_vis.sdat")
#NoDataValue = -99999
#GDType = Float32
## scale to Byte format
rv.lst = list(c(-400,0), c(-145,145), c(-145,145), c(-145,145))
mv.lst = c(255, 128, 128, 128)
for(i in 1:length(rv.lst)){
  system(paste0('gdal_translate PC', i, '.v4b_web.stable_lights.avg_vis.sdat /mnt/DATA/LandGIS/layers1km/lcv_nightlights.stable_dmsp.pc', i, '_m_1km_s0..0cm_1992..2013_v1.0.tif -scale \"', rv.lst[[i]][1] ,'\" \"', rv.lst[[i]][2], '\" 0 255 -co \"BIGTIFF=YES\" -co \"COMPRESS=DEFLATE\" -ot \"Byte\" -a_nodata ', mv.lst[i]))
  ## remove nodata value:
  system(paste0('/home/dev/Downloads/gdal-2.3.0/swig/python/scripts/gdal_edit.py /mnt/DATA/LandGIS/layers1km/lcv_nightlights.stable_dmsp.pc', i, '_m_1km_s0..0cm_1992..2013_v1.0.tif -unsetnodata'))
}
## check:
GDALinfo("/mnt/DATA/LandGIS/layers1km/lcv_nightlights.stable_dmsp.pc1_m_1km_s0..0cm_1992..2013_v1.0.tif")
