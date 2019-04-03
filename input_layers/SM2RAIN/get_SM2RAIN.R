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

x = fromJSON(system('curl -H \"Accept: application/json\" \"https://zenodo.org/api/records/2591215\"', intern = TRUE, show.output.on.console = FALSE))
sel.nc = x$files$links$download
str(sel.nc)
for(i in sel.nc){ if(!file.exists(basename(i))){ download.file(i, basename(i)) } }
system(paste0('gdalinfo ', basename(sel.nc[1])))
#r = raster(basename(sel.nc[1]))
## Misses grid definition
r = raster(resolution=c(0.11,0.11), xmn=-180, xmx=180, ymn=-60, ymx=80, crs="+proj=longlat +datum=WGS84")
r
fill.na <- function(x, i=5) {
  if( is.na(x)[i] ) {
    return( round(mean(x, na.rm=TRUE),0) )
  } else {
    return( round(x[i],0) )
  }
}  

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

## Compress per year:
for(i in 2007:2018){
  out.zip = paste0("SM2RAIN_daily.rainfall_", i, "_10km.zip")
  if(!file.exists(out.zip)){
    tif.sel = list.files(path="/mnt/DATA/SMRAIN/raw", pattern=glob2rx(paste0("*_", i, "-*-*_10km.tif$")), full.names = TRUE)
    zip(zipfile = out.zip, files = tif.sel)
  }
}
