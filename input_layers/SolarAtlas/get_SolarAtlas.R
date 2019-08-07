## Global Solar irradiation
## https://globalsolaratlas.info/downloads/world
## tom.hengl@opengeohub.org
## The map is only available up to 60 degrees north and 45 degrees south

library(rgdal)
library(raster)
library(snowfall)
library(snow)
library(mlr)
library(parallelMap)
load(".RData")
source("/data/LandGIS/R/saveRDS_functions.R")

## Land mask 1km ----
r = raster("/data/LandGIS/layers1km/lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.tif")
te.ll = as.vector(extent(r))[c(1,3,2,4)]
cellsize.ll = res(r)[1]
p4s = proj4string(r)

in.tifs = c("/mnt/DATA/GlobalSolarAtlas/World_DIF_GISdata_LTAy_DailySum_GlobalSolarAtlas_GEOTIFF/DIF.tif", "/mnt/DATA/GlobalSolarAtlas/World_DNI_GISdata_LTAy_DailySum_GlobalSolarAtlas_GEOTIFF/DNI.tif")
for(j in 1:length(in.tifs)){
  system(paste0('gdalwarp ', in.tifs[j],' ', basename(in.tifs[j]), ' -tr ', cellsize.ll, ' ', cellsize.ll, ' -te ', paste(te.ll, collapse = " "), ' -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=ALL_CPUS\"'))
}
#system(paste0('gdalwarp /mnt/DATA/LandGIS/layers1km/dtm_pos.openess_merit.dem_m_1km_s0..0cm_2017_v1.0.tif /data/LandGIS/layers1km/dtm_pos.openess_merit.dem_m_1km_s0..0cm_2017_v1.0.tif -tr ', cellsize.ll, ' ', cellsize.ll, ' -overwrite -te ', paste(te.ll, collapse = " "), ' -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=ALL_CPUS\"'))
tifs.1km = c(basename(in.tifs), "/data/LandGIS/layers1km/clm_lst_mod11a2.annual.day_m_1km_s0..0cm_2000..2017_v1.0.tif", "/data/LandGIS/layers1km/clm_lst_mod11a2.annual.night_m_1km_s0..0cm_2000..2017_v1.0.tif", "/data/LandGIS/layers1km/clm_cloud.fraction_earthenv.modis.annual_m_1km_s0..0cm_2000..2015_v1.0.tif", "/data/LandGIS/layers1km/dtm_pos.openess_merit.dem_m_1km_s0..0cm_2017_v1.0.tif")
s1km = stack(tifs.1km)
#s1km = as(s1km, "SpatialGridDataFrame")
save.image()

## Fill in missing values (>60 degrees) ----
Pnts.sim <- raster::sampleRandom(raster(tifs.1km[3]), size=10000, sp=TRUE)
#plot(Pnts.sim)
ov.R = parallel::mclapply(tifs.1km, function(i){ raster::extract(raster(i), Pnts.sim) }, mc.cores = length(tifs.1km))
ov.R = as.data.frame(ov.R)
names(ov.R) = basename(tifs.1km)
f.DIF = as.formula(paste("DIF.tif ~ ", paste(names(ov.R[-c(1,2)]), collapse = "+")))
f.DNI = as.formula(paste("DNI.tif ~ ", paste(names(ov.R[-c(1,2)]), collapse = "+")))
sel.DIF = complete.cases(ov.R[,all.vars(f.DIF)])
sel.DNI = complete.cases(ov.R[,all.vars(f.DNI)])
summary(sel.DIF)
## 7526
SL.library <- c("regr.ranger", "regr.glmnet", "regr.xgboost")
#tsk <- mlr::makeRegrTask(data = ov.R[sel.DIF,all.vars(f.DIF)], target = "DIF.tif")
tsk <- mlr::makeRegrTask(data = ov.R[sel.DNI,all.vars(f.DNI)], target = "DNI.tif")
lrns <- list(mlr::makeLearner(SL.library[1], num.threads = parallel::detectCores()), mlr::makeLearner(SL.library[2]), mlr::makeLearner(SL.library[3]))
init.m <- mlr::makeStackedLearner(lrns, predict.type = "response", super.learner = "regr.glm")
parallelMap::parallelStartSocket(parallel::detectCores())
m <- mlr::train(init.m, tsk)
parallelMap::parallelStop()
#save.image()
#saveRDS.gz(m, "m_DIF.rds")
saveRDS.gz(m, "m_DNI.rds")
m$learner.model$super.model$learner.model
1-(m$learner.model$super.model$learner.model$deviance/m$learner.model$super.model$learner.model$null.deviance)
## R-square >90%
g1km = readGDAL("/data/LandGIS/layers1km/lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.tif")
g1km$band1 = ifelse(g1km$band1==2, NA, g1km$band1)
str(g1km)
## !! 20 mins
g1km = as(g1km, "SpatialPixelsDataFrame")
#saveRDS.gz(g1km, "lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.rds")
g1km = readRDS.gz("lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.rds")
gc()
#str(g1km@coords)
## 215,380,966
## 5GB
sel.fix = g1km@coords[,2] > 59.9 | g1km@coords[,2] < -44.9
#summary(sel.fix)
# 53,251,879
#str(g1km@grid.index)
## read rasters needed to make predictions
for(j in 3:length(tifs.1km)){
  g1km@data[sel.fix, names(ov.R)[j]] = readGDAL(tifs.1km[j])$band1[g1km@grid.index[sel.fix]]
}
gc()
## Predict missing pixels ----
newdata = g1km@data[which(sel.fix),all.vars(f.DIF)[-1]]
c.x = complete.cases(newdata)
#summary(c.x)
## 40,423,443
str(newdata)
saveRDS.gz(newdata, "newdata.rds")
#g1km$DIF = NA
g1km$DNI = NA
#parallelMap::parallelStartSocket(parallel::detectCores())
system.time( out <- predict(m, newdata=newdata[which(c.x),]) )
## Ranger runs in parallel, GLM takes more time
##     user   system  elapsed 
## 5505.554  533.866  347.266
hist(out$data$response)
#hist(ov.R$DIF)
#parallelMap::parallelStop()
## write fixed values
#g1km@data[which(sel.fix)[which(c.x)],"DIF"] = round(out$data$response, 2)
g1km@data[which(sel.fix)[which(c.x)],"DNI"] = round(out$data$response, 2)
obj = GDALinfo(in.tifs[2])
## 5 mins!!
#writeGDAL(g1km["DIF"], "DIF_na.tif", drivername = "GTiff", type=paste(attr(obj, "df")$GDType), options = c("COMPRESS=DEFLATE"))
writeGDAL(g1km["DNI"], "DNI_na.tif", drivername = "GTiff", type=paste(attr(obj, "df")$GDType), options = c("COMPRESS=DEFLATE"))

## true and filled values ----
g1km$DNI.f = readGDAL(tifs.1km[2])$band1[g1km@grid.index]*10
g1km$DNI.f = round(ifelse(is.na(g1km$DNI.f), g1km$DNI*10, g1km$DNI.f))
writeGDAL(g1km["DNI.f"], "/data/LandGIS/layers1km/clm_direct.irradiation_solar.atlas.kwhm2.10_m_1km_s0..0cm_2016_v1.tif", type="Int16", mvFlag = -32768, options = c("COMPRESS=DEFLATE"))
g1km$DIF.f = readGDAL(tifs.1km[1])$band1[g1km@grid.index]*100
g1km$DIF.f = round(ifelse(is.na(g1km$DIF.f), g1km$DIF*100, g1km$DIF.f))
writeGDAL(g1km["DIF.f"], "/data/LandGIS/layers1km/clm_diffuse.irradiation_solar.atlas.kwhm2.100_m_1km_s0..0cm_2016_v1.tif", type="Int16", mvFlag = -32768, options = c("COMPRESS=DEFLATE"))
