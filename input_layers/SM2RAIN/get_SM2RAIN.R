## Download and processing of SM2RAIN-ASCAT (2007-2018) https://doi.org/10.5281/zenodo.2591214
## tom.hengl@opengeohub.org

library(jsonlite)
library(RCurl)
library(raster)
library(rgdal)
library(fasterize)
TOKEN = scan("~/TOKEN_ACCESS", what="character")
dep.id = "2591215"
# https://zenodo.org/record/2591215/files/SM2RAIN_ASCAT_0125_2007.nc?download=1

## Download NetCDFs ----
x = fromJSON(system('curl -H \"Accept: application/json\" \"https://zenodo.org/api/records/2591215\"', intern = TRUE, show.output.on.console = FALSE))
sel.nc = x$files$links$download
str(sel.nc)
for(i in sel.nc){ if(!file.exists(basename(i))){ download.file(i, basename(i)) } }
system(paste0('gdalinfo ', basename(sel.nc[1])))
#r = raster(basename(sel.nc[1]))
## Misses grid definition

## 10km grid ----
r = raster(resolution=c(0.11,0.11), xmn=-180, xmx=180, ymn=-60, ymx=80, crs="+proj=longlat +datum=WGS84")
r
fill.na <- function(x, i=5) {
  if( is.na(x)[i] ) {
    return( round(mean(x, na.rm=TRUE),0) )
  } else {
    return( round(x[i],0) )
  }
}  

## Rasterize points ----
extra.tifs = function(j, lon, lat, rain, time, r){
  df = data.frame(lon, lat, rain[j,])
  if(sum(!is.na(df[,3]))>0){
    df = df[!is.na(df[,3]),]
    coordinates(df) = ~ lon+lat
    gt = rasterize(df, r, field=names(df))
    gtf = focal(gt, w=matrix(1,3,3), fun=fill.na, pad=TRUE, na.rm=FALSE)
    filename = paste0("daily.rainfall_", as.Date(time[j], origin = "2000-01-01"), "_10km.tif")
    if(!file.exists(filename)){
      writeRaster(gtf, filename, options=c("COMPRESS=DEFLATE"), datatype='INT4S', format="GTiff", overwrite=TRUE)
    }
  }
}

## Run in parallel ----
library("ncdf4")
library("snowfall")
for(i in basename(sel.nc)){
  nc <- nc_open(i)
  #names(nc$var)
  ## "Time" "Longitude" "Latitude"  "Rainfall"  "Conf_flag" "ssf"
  # Days since 1-Jan-2000"
  lon = ncvar_get(nc, varid="Longitude")
  #str(lon)
  lat = ncvar_get(nc, varid="Latitude")
  time = ncvar_get(nc, varid="Time")
  rain = ncvar_get(nc, varid="Rainfall")
  ## run in parallel:
  sfInit(parallel=TRUE, cpus=35)
  sfLibrary(raster)
  sfLibrary(rgdal)
  sfExport("lon", "lat", "time", "rain", "extra.tifs", "fill.na", "r")
  out <- snowfall::sfClusterApplyLB(1:nrow(rain), function(j){ extra.tifs(j, lon, lat, rain, time, r) })
  sfStop()
}

## Compress per year ----
for(i in 2007:2018){
  out.zip = paste0("SM2RAIN_daily.rainfall_", i, "_10km.zip")
  if(!file.exists(out.zip)){
    tif.sel = list.files(path="/mnt/DATA/SMRAIN/raw", pattern=glob2rx(paste0("*_", i, "-*-*_10km.tif$")), full.names = TRUE)
    zip(zipfile = out.zip, files = tif.sel)
  }
}

## Land mask ---
system(paste0('gdalwarp /mnt/DATA/LandGIS/layers1km/lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.tif /mnt/DATA/SMRAIN/raw/lcv_landmask_esacci.lc.l4_c_10km_s0..0cm_2000..2015_v1.0.tif -t_srs \"', proj4string(r), '\" -r \"near\" -tr 0.11 0.11 -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=ALL_CPUS\" -te -180 -60.03 180.03 80'))
#processing.run("gdal:warpreproject", {'INPUT':'/mnt/DATA/LandGIS/layers1km/lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.tif','SOURCE_CRS':QgsCoordinateReferenceSystem('EPSG:4326'),'TARGET_CRS':QgsCoordinateReferenceSystem('EPSG:4326'),'RESAMPLING':0,'NODATA':None,'TARGET_RESOLUTION':None,'OPTIONS':'','DATA_TYPE':0,'TARGET_EXTENT':'-180.0,180.03000000000003,-60.03,80.0 [EPSG:4326]','TARGET_EXTENT_CRS':QgsCoordinateReferenceSystem('EPSG:4326'),'MULTITHREADING':True,'OUTPUT':'/tmp/processing_66f0adf0d6994687a3158175e8648ea1/11365ccdb35442fc9e885c5d5e46d533/OUTPUT.tif'}))

## Monthly mean and SD ----
library(rgdal)
library(parallel)
library(Rfast)

m.lst <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
m0.lst <- c(paste0("0", 1:9), 10:12)
mask10km = readGDAL("/mnt/DATA/SMRAIN/raw/lcv_landmask_esacci.lc.l4_c_10km_s0..0cm_2000..2015_v1.0.tif")
mask10km = as(mask10km, "SpatialPixelsDataFrame")
mask10km = mask10km[!mask10km$band1==2,]
str(mask10km@grid.index)
## 1,219,379

for(i in 1:length(m.lst)){
  out.file = paste0('clm_precipitation_sm2rain.', tolower(m.lst[i]),'_m_10km_s0..0cm_2007..2018_v1.0.tif')
  out.file.sd = gsub("_m_", "_sd.10_", out.file)
  if(!file.exists(out.file)){
    x.lst = list.files(pattern=glob2rx(paste0('daily.rainfall_*-', m0.lst[i], '-*_10km.tif$')))
    ## read about 350 tifs to memory
    m = parallel::mclapply(1:length(x.lst), function(j){ readGDAL(x.lst[j], silent=TRUE)$band1[mask10km@grid.index] }, mc.cores=64)
    ## 1.7GB
    m = as.matrix(data.frame(m))
    m[is.na(m)] <- 0
    mask10km$m = Rfast::rowsums(m, indices = NULL, parallel = TRUE)/12
    writeGDAL(mask10km["m"], out.file, type = "Int16", mvFlag = -32768, options = c("COMPRESS=DEFLATE"))
    if(!file.exists(out.file.sd)){
      mask10km$sd = Rfast::rowVars(m, suma = NULL, std = TRUE)*10
      writeGDAL(mask10km["sd"], out.file.sd, type = "Int16", mvFlag = -32768, options=c("COMPRESS=DEFLATE"))
    }
    rm(m)
    gc()
  }
}

