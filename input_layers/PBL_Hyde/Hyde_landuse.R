## Hyde data set (http://themasites.pbl.nl/tridion/en/themasites/hyde/index.html)
## by tom.hengl@gmail.com

library(rgdal)
library(plyr)
library(raster)

setwd("./zip")
system('wget -N -nv -r -np -nH --accept "*.zip" --reject=\"index.html\" --cut-dirs=5 --level=6 "ftp://ftp.pbl.nl/hyde/hyde3.2/2017_beta_release/001/zip/"')
## 146 files, 4,4G in 6m 14s (12,0 MB/s)
hyde.lst <- list.files(pattern = glob2rx("*_lu.zip$"), full.names = TRUE)
## extract files and stack
sapply(hyde.lst, function(x){system(paste("7za e ", x," -r -y"))})
## function to strip year:
strip_year = function(x, name, ext=".asc"){
  xn = sapply(paste(x), function(x){strsplit(strsplit(x, name)[[1]][2], ext)[[1]][1]})
  xi = rep(NA, length(xn))
  xi[grep("AD", xn)] <- as.numeric( sapply(paste(xn[grep("AD", xn)]), function(x){strsplit(x, "AD")[[1]][1]}) )
  xi[grep("BC", xn)] <- -as.numeric( sapply(paste(xn[grep("BC", xn)]), function(x){strsplit(x, "BC")[[1]][1]}) )
  return(xi)
}

cropland.lst <- list.files(pattern = glob2rx("cropland*.asc$"), full.names = TRUE) 
## 74
cropland.tbl <- data.frame(filename=cropland.lst)
cropland.tbl$Year <- strip_year(cropland.tbl$filename, name="cropland")
cropland.tbl <- cropland.tbl[order(cropland.tbl$Year),]
head(cropland.tbl)

pasture.lst <- list.files(pattern = glob2rx("pasture*.asc$"), full.names = TRUE)
pasture.tbl <- data.frame(filename=pasture.lst)
pasture.tbl$Year <- strip_year(pasture.tbl$filename, name="pasture")
pasture.tbl <- pasture.tbl[order(pasture.tbl$Year),]
head(pasture.tbl)

## resample to 10 km LandGIS mask:
r = raster("/data/LandGIS/layers250m/lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
GDALinfo(paste0(cropland.tbl$filename[1]))

library(snowfall)
snowfall::sfInit(parallel=TRUE, cpus=62)
snowfall::sfLibrary(rgdal)
snowfall::sfLibrary(raster)
snowfall::sfExport("cropland.tbl", "r", "te")
out <- snowfall::sfClusterApplyLB(1:nrow(cropland.tbl), function(i){ system(paste0('gdalwarp ', cropland.tbl[i,"filename"], ' /mnt/DATA/LandGIS/layers10km/lcv_landuse.cropland_hyde_p_10km_s0..0cm_', gsub("-", "BC", cropland.tbl[i,"Year"]), '_v3.2.tif -s_srs \"EPSG:4326\" -overwrite -r \"near\" -dstnodata 255 -ot \"Byte\" -tr ', 1/12, ' ', 1/12, ' -te ', paste(te, collapse = " "), ' -co \"COMPRESS=DEFLATE\"')) })
snowfall::sfStop()

library(snowfall)
snowfall::sfInit(parallel=TRUE, cpus=62)
snowfall::sfLibrary(rgdal)
snowfall::sfLibrary(raster)
snowfall::sfExport("pasture.tbl", "r", "te")
out <- snowfall::sfClusterApplyLB(1:nrow(pasture.tbl), function(i){ system(paste0('gdalwarp ', pasture.tbl[i,"filename"], ' /mnt/DATA/LandGIS/layers10km/lcv_landuse.pasture_hyde_p_10km_s0..0cm_', gsub("-", "BC", pasture.tbl[i,"Year"]), '_v3.2.tif -s_srs \"EPSG:4326\" -overwrite -r \"near\" -dstnodata 255 -ot \"Byte\" -tr ', 1/12, ' ', 1/12, ' -te ', paste(te, collapse = " "), ' -co \"COMPRESS=DEFLATE\"')) })
snowfall::sfStop()
