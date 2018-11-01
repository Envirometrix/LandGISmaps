## Land vegetation products from http://land.copernicus.vgt.vito.be
## tom.hengl@gmail.com

setwd("/data/Copernicus_vito")
library(raster)
library(rgdal)
library(data.table)
load(".RData")

source("/data/LandGIS/R/LandGIS_functions.R")
days <- as.numeric(format(seq(ISOdate(2015,1,1), ISOdate(2015,12,31), by="month"), "%j"))-1
m.lst <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")

setwd("/mnt/nas/Copernicus_vito/FAPAR_300m_V1")
## fraction_of_surface_downwelling_photosynthetic_radiative_flux_absorbed_by_vegetation (8-bit unsigned integer)
## http://land.copernicus.eu/global/products/fapar
nc.lst <- list.files("/mnt/nas/Copernicus_vito/FAPAR_300m_V1", pattern=glob2rx("*.nc$"), full.names = TRUE, recursive = TRUE)
system(paste('gdalinfo ', nc.lst[1]))

r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
cellsize = res(r)[1]

## convert to geotif ----
library(parallel)
x = mclapply(nc.lst, FUN = function(i){ system(paste0('gdalwarp NETCDF:\"',i,'\":FAPAR ', gsub(".nc", ".tif", basename(i)),' -co \"BIGTIFF=YES\" -co \"compress=deflate\" -tr ', res(r),' ', res(r), ' -r \"near\" -te ', paste(te, collapse = " "))) }, mc.cores = 6)

## Median, min, sd and max values per month ----
setwd("/data/Copernicus_vito")
tif.lst <- list.files("./FAPAR_300m_V1", pattern=glob2rx("*.tif$"), full.names = TRUE)
tile.tbl = readRDS("/data/LandGIS/models/stacked250m_tiles.rds")
pr.dirs = readRDS("/data/LandGIS/models/prediction_dirs.rds")
dsel <- c(paste0("0", 1:9), "10", "11", "12") 
new.dirs <- paste0("/data/tt/OpenLandData/covs250m/", pr.dirs)
x <- lapply(new.dirs, dir.create, recursive=TRUE, showWarnings=FALSE)
## Test if all raster stack to the same grid:
t <- raster::stack(tif.lst)
pnt.r <- raster::sampleRandom(raster(tif.lst[1]), size=100, sp=TRUE)
pnt.t <- parallel::mclapply(tif.lst, function(i){ raster::extract(raster(i), pnt.r) }, mc.cores = 24)
tif.lst[sapply(pnt.t, function(i){ !class(i)=="numeric" })]
#system(paste0('gdalinfo ', tif.lst[2]))

library(snowfall)
for(k in 1:length(m.lst)){
  tif.sel = tif.lst[unlist(sapply(paste0("_", 2014:2017, dsel[k]), function(y){ grep(y, tif.lst) }))]
  ## 12 images per month
  #stack_stats(i="T38275", tile.tbl=tile.tbl, tif.sel=tif.sel, var=paste0("FAPAR_", m.lst[k]), out=c("min","med","max"), probs=c(.025,.5,.975))
  snowfall::sfInit(parallel=TRUE, cpus=24)
  sfExport("stack_stats", "tile.tbl", "m.lst", "tif.sel", "pr.dirs", "k")
  sfLibrary(rgdal)
  sfLibrary(data.table)
  x <- sfClusterApplyLB(pr.dirs, function(x){ try( stack_stats(i=x, tile.tbl=tile.tbl, tif.sel=tif.sel, var=paste0("FAPAR_", m.lst[k]), out=c("min","med","max"), probs =c(.025,.5,.975)), silent = TRUE) })
  sfStop()
}

## for k = 3, 7, 8
## 223, 367, 122 nodes produced errors; first error: Error in getRasterData(x, band = band, offset = offset, region.dim = region.dim,  :  Failure during raster IO

## Fix missing tiles ----
t.lst = list.files("/data/tt/OpenLandData/covs250m", pattern=glob2rx("FAPAR_May_med_*.tif$"), recursive = TRUE, full.names=TRUE)
t.drs = sapply(basename(t.lst), function(i){strsplit(i, "_")[[1]][4]})

mc.lst = c(m.lst[12], m.lst, m.lst[1])
library(parallel)
for(k in 2:13){
  t0.lst = list.files("/data/tt/OpenLandData/covs250m", pattern=glob2rx(paste0("FAPAR_", mc.lst[k], "_med_*.tif$")), recursive = TRUE, full.names=TRUE)
  dt.lst = t.drs[which(!t.drs %in% sapply(basename(t0.lst), function(i){strsplit(i, "_")[[1]][4]}))]
  if(length(dt.lst)>0){
    x = parallel::mclapply(sapply(paste(dt.lst), function(u){strsplit(u, "\\.")[[1]][1]}), FUN=function(i){ missing_tile(i, var1=paste0("FAPAR_", mc.lst[k-1]), var2=paste0("FAPAR_", mc.lst[k]), var3=paste0("FAPAR_", mc.lst[k+1])) }, mc.cores=24)
  }
}  

## Mean annual FAPAR and s.d. ----
library(raster)
tifM.250m = list.files("/data/LandGIS/layers250m", pattern=glob2rx("FAPAR_*_med_2014_2017_250m_ll.tif$"), full.names = TRUE)
GDALinfo(tifM.250m[1])
#saga_grid_stats(in.tif.lst=tifM.250m, out.tif.lst=c("/data/LandGIS/layers250m/veg_fapar_land.copernicus.annual_d_250m_s0..0cm_2000..2017_v1.0.tif", "/data/LandGIS/layers250m/veg_fapar_land.copernicus.annual_sd_250m_s0..0cm_2000..2017_v1.0.tif"), cleanup=TRUE, r.lst=rep("near", length(tifM.250m)), d.lst=rep(-32768, length(tifM.250m)), tr=0.002083333, te=te)
library(snowfall)
snowfall::sfInit(parallel=TRUE, cpus=24)
sfExport("stack_mean_sd", "tile.tbl", "m.lst", "tifM.250m", "pr.dirs")
sfLibrary(rgdal)
sfLibrary(data.table)
x <- sfClusterApplyLB(pr.dirs, function(x){ try( stack_mean_sd(i=x, tile.tbl=tile.tbl, tif.sel=tifM.250m, var="FAPAR_annual", out=c("mean","sd")) ) })
sfStop()

## Make mosaics ----
d.lst = expand.grid(m.lst, c("min","med","max"))
d.lst$n = ifelse(d.lst$Var2=="min", "l.025", ifelse(d.lst$Var2=="max", "u.975", "d"))
d.lst = rbind(d.lst, data.frame(Var1=c("annual", "annual"), Var2=c("sd","mean"), n=c("sd","d")))
filename = paste0("veg_fapar_proba.v.", tolower(d.lst$Var1),"_", tolower(d.lst$n), "_250m_s0..0cm_2014..2017_v1.0.tif")

mosaic_ll_250m <- function(varn, i, out.tif, in.path="/data/tt/OpenLandData/covs250m", out.path="/data/LandGIS/layers250m", tr, te, ot="Byte", dstnodata=255){
  out.tif = paste0(out.path, "/", out.tif)
  if(!file.exists(out.tif)){
    tmp.lst <- list.files(path=in.path, pattern=glob2rx(paste0(varn, "_", i, "_T*.tif$")), full.names=TRUE, recursive=TRUE)
    out.tmp <- tempfile(fileext = ".txt")
    vrt.tmp <- tempfile(fileext = ".vrt")
    cat(tmp.lst, sep="\n", file=out.tmp)
    system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
    system(paste0('gdalwarp ', vrt.tmp, ' ', out.tif, ' -ot \"', paste(ot), '\" -dstnodata \"',  paste(dstnodata), '\" -r \"near\" -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\" -wm 2000 -tr ', tr, ' ', tr, ' -te ', te))
    system(paste0('gdaladdo ', out.tif, ' 2 4 8 16 32 64 128'))
  }
}

library(snowfall)
sfInit(parallel=TRUE, cpus=12)
sfExport("d.lst", "mosaic_ll_250m", "filename", "te", "cellsize")
out <- sfClusterApplyLB(1:nrow(d.lst), function(x){ try( mosaic_ll_250m(varn="FAPAR", i=paste(d.lst$Var1[x], d.lst$Var2[x], sep="_"), out.tif=filename[x], tr=cellsize, te=paste(te, collapse = " ")) )})
sfStop()
save.image()

## Aggregate to 1km:
tif.250m = c(list.files("/data/LandGIS/layers250m", pattern=glob2rx("veg_fapar_proba.v.*_d_250m_s0..0cm_2014..2017_v1.0.tif$"), full.names = TRUE), list.files("/data/LandGIS/layers250m", pattern=glob2rx("veg_fapar_proba.v.*_sd_250m_s0..0cm_2014..2017_v1.0.tif$"), full.names = TRUE))
x = parallel::mclapply(tif.250m, function(i){ system(paste0('gdalwarp ', i, ' ', gsub("250m", "1km", gsub("layers250m", "upscaled1km", i)), ' -r \"average\" -tr ', 1/120, ' ', 1/120, ' -ot \"Byte\" -dstnodata \"255\" -te ', paste(extent(r)[c(1,3,2,4)], collapse = " "), ' -co \"COMPRESS=DEFLATE\"')) }, mc.cores = 14)

## GDMP300 ---- 
## kg/ha/day 0-655.34 (scaling: 1/50)
## https://land.copernicus.eu/global/products/dmp
nc2.lst <- list.files("/data/Copernicus_vito/GDMP300", pattern=glob2rx("*.nc$"), full.names = TRUE, recursive = TRUE)
system(paste('gdalinfo ', nc2.lst[1]))

library(parallel)
x = mclapply(nc2.lst, FUN = function(i){ try( system(paste0('gdal_translate NETCDF:\"',i,'\":GDMP ', gsub(".nc", ".tif", basename(i)),' -co \"BIGTIFF=YES\" -co \"COMPRESS=DEFLATE\" -ot \"Int16\"')) ) }, mc.cores = 10)

## check all geotifs:
tif2.lst <- list.files("/data/Copernicus_vito/GDMP300", pattern=glob2rx("*.tif$"), full.names = TRUE)
s = lapply(tif2.lst, GDALinfo)
sum(sapply(s, function(i){class(i)=="GDALobj"}))
sl = stack(tif2.lst)

setwd("/data/Copernicus_vito/")
tifG.lst <- list.files("./GDMP300", pattern=glob2rx("*.tif$"), full.names = TRUE)
## Test if all raster stack to the same grid:
tG <- raster::stack(tifG.lst)
pntG.r <- raster::sampleRandom(raster(tifG.lst[1]), size=100, sp=TRUE)
pntG.t <- parallel::mclapply(tifG.lst, function(i){ raster::extract(raster(i), pntG.r) }, mc.cores = parallel::detectCores())
tifG.lst[sapply(pntG.t, function(i){ !class(i)=="numeric" })]
save.image()

obj <- GDALinfo(tifG.lst[1])
tileG.tbl <- GSIF::getSpatialTiles(obj, block.x=2, return.SpatialPolygons=FALSE)
tileG.tbl$ID = as.character(1:nrow(tileG.tbl))
newG.dirs <- paste0("/data/tt/OpenLandData/vito300/T", 1:nrow(tileG.tbl))
x <- lapply(newG.dirs, dir.create, recursive=TRUE, showWarnings=FALSE)

library(snowfall)
for(k in 1:length(m.lst)){
  tif.sel = tifG.lst[unlist(sapply(paste0("_", 2014:2018, dsel[k]), function(y){ grep(y, tifG.lst) }))]
  ## 12 images per month
  #stack_stats(i="T5000", tile.tbl=tileG.tbl, tif.sel=tif.sel, var=paste0("GDMP300_", m.lst[k]), out=c("min","med","max"), probs=c(.025,.5,.975), out.dir="/data/tt/OpenLandData/vito300")
  snowfall::sfInit(parallel=TRUE, cpus=parallel::detectCores())
  sfExport("stack_stats", "tileG.tbl", "m.lst", "tif.sel", "k")
  sfLibrary(rgdal)
  sfLibrary(data.table)
  x <- sfClusterApplyLB(paste0("T", 1:nrow(tileG.tbl)), function(x){ try( stack_stats(i=x, tile.tbl=tileG.tbl, tif.sel=tif.sel, var=paste0("GDMP300_", m.lst[k]), out=c("min","med","max"), probs =c(.025,.5,.975), out.dir="/data/tt/OpenLandData/vito300"), silent = TRUE) })
  sfStop()
}

## Make mosaics ----
filenameG = paste0("veg_gdmp300_proba.v.", tolower(d.lst$Var1),"_", tolower(d.lst$n), "_250m_s0..0cm_2014..2017_v1.0.tif")

library(snowfall)
sfInit(parallel=TRUE, cpus=18)
sfExport("d.lst", "mosaic_ll_250m", "filenameG", "te", "cellsize")
out <- sfClusterApplyLB(1:36, function(x){ try( mosaic_ll_250m(varn="GDMP300", i=paste(d.lst$Var1[x], d.lst$Var2[x], sep="_"), out.tif=filenameG[x], tr=cellsize, ot="Int16", dstnodata=-32767, in.path="/data/tt/OpenLandData/vito300", te=paste(te, collapse = " ")) )})
sfStop()
save.image()

## Median value for May 2017:
meanf <- function(x){calc(x, mean, na.rm=TRUE)}
qfun = function(x) {calc(x, quantile, probs = c(.5), na.rm=TRUE)} ## makes little sense if number of layers is <4
o.l = raster::stack(paste0("/data/Copernicus_vito/GDMP300/", c("c_gls_GDMP300-RT5_201705100000_GLOBE_PROBAV_V1.0.1.tif","c_gls_GDMP300-RT5_201705200000_GLOBE_PROBAV_V1.0.1.tif","c_gls_GDMP300-RT5_201705310000_GLOBE_PROBAV_V1.0.1.tif")))
beginCluster()
r1 <- clusterR(o.l, fun=meanf, filename="/data/Copernicus_vito/c_gls_GDMP300-RT5_201705__0000_GLOBE_PROBAV_V1.0.1.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"))
endCluster()
