## Preparation of layers LandGIS
## tom.hengl@gmail.com

load(".RData")
library(rgdal)
library(raster)
library(plyr)
library(fastSave)
source("saveRDS_functions.R")
source("LandGIS_functions.R")

## grid definition:
tif.land="/data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif"
r <- raster(tif.land)
ncols = ncol(r)
nrows = nrow(r)
cellsize = res(r)[1]
te = as.vector(extent(r))[c(1,3,2,4)]

## Resample all layers of interest to 250m resolution:
ds1km.lst = c(list.files("../layers1km", pattern=glob2rx("dtm_*_merit.dem_m_1km_s0..0cm_2017_v1.0.tif$"), full.names = TRUE), 
              list.files("../layers1km", pattern=glob2rx("clm_precipitation_*.*_m_1km_s0..0cm_2014..2018_v0.1.tif$"), full.names = TRUE), 
              list.files("../layers1km", pattern=glob2rx("clm_lst_mod11a2.*.*_sd_1km_s0..0cm_2000..2017_v1.0.tif$"), full.names = TRUE), 
              list.files("../layers1km", pattern=glob2rx("clm_lst_mod11a2.*.*_m_1km_s0..0cm_2000..2017_v1.0.tif$"), full.names = TRUE), 
              list.files("../layers1km", pattern=glob2rx("clm_cloud.fraction_earthenv.modis.*_*_1km_s0..0cm_2000..2015_v1.0.tif$"), full.names = TRUE), 
              list.files("../layers1km", pattern=glob2rx("clm_water.vapor_nasa.eo.*_m_1km_s0..0cm_2000..2017_v1.0.tif$"), full.names = TRUE),
              list.files("../layers1km", pattern=glob2rx("clm_*.irradiation_solar.atlas.kwhm2.*_m_1km_s0..0cm_2016_v1.tif$"), full.names = TRUE),
              "../layers1km/dtm_earthquakes.dens_earthquake.usgs_m_1km_s0..0cm_1910..2017_v1.0.tif",
              "../layers1km/dtm_water.table.depth_deltares_m_1km_b0..150m_2016_v1.0.tif",
              "../layers1km/dtm_inundation.extent_giems.d15_m_1km_s0..0cm_2015_v1.0.tif",
              "../layers1km/dtm_floodmap.500y_jrc.hazardmapping_m_1km_s0..0cm_1500..2016_v1.0.tif")

library(snowfall)
sfInit(parallel=TRUE, cpus=25)
sfExport("ds1km.lst", "cellsize", "te")
#sfLibrary(rgdal)
#sfLibrary(raster)
out <- sfClusterApplyLB(ds1km.lst, function(i){system(paste0('gdalwarp ', i, ' ', gsub("/layers1km/", "/downscaled250m/", i), ' -r \"cubicspline\" -tr ', cellsize, ' ', cellsize, ' -te ', paste0(te, collapse = " "), ' -co \"BIGTIFF=YES\" -co \"COMPRESS=DEFLATE\" -wm 2000 -multi -wo \"NUM_THREADS=2\"'))})
sfStop()

ds500m.lst = c(list.files("/mnt/DATA/LandGIS/layers500m", pattern=glob2rx("lcv_surf.refl.b*_mod09a1.*_m_500m_s0..0cm_2001_v1.0.tif$"), full.names = TRUE), 
               "../layers500m/dtm_vbf_merit.dem_m_500m_s0..0cm_2017_v1.0.tif",
               "../layers500m/dtm_twi_merit.dem_m_500m_s0..0cm_2017_v1.0.tif")

library(snowfall)
sfInit(parallel=TRUE, cpus=16)
sfExport("ds500m.lst", "cellsize", "te")
#sfLibrary(rgdal)
#sfLibrary(raster)
out <- sfClusterApplyLB(ds500m.lst, function(i){system(paste0('gdalwarp ', i, ' /data/LandGIS/downscaled250m/', basename(i), ' -r \"cubicspline\" -tr ', cellsize, ' ', cellsize, ' -te ', paste0(te, collapse = " "), ' -co \"BIGTIFF=YES\" -co \"COMPRESS=DEFLATE\" -wm 2000 -multi -wo \"NUM_THREADS=3\"'))})
sfStop()

## DEM derivatives at 2 km
ds2km.lst = list.files("/data/LandGIS/layers2km", pattern=glob2rx("dtm_*_merit.dem_m_2km_s0..0cm_2017_v1.0.tif$"), full.names = TRUE)

library(snowfall)
sfInit(parallel=TRUE, cpus=16)
sfExport("ds2km.lst", "cellsize", "te")
#sfLibrary(rgdal)
#sfLibrary(raster)
out <- sfClusterApplyLB(ds2km.lst, function(i){system(paste0('gdalwarp ', i, ' /data/LandGIS/downscaled250m/', basename(i), ' -r \"cubicspline\" -tr ', cellsize, ' ', cellsize, ' -te ', paste0(te, collapse = " "), ' -co \"BIGTIFF=YES\" -co \"COMPRESS=DEFLATE\" -wm 2000 -multi -wo \"NUM_THREADS=3\"'))})
sfStop()

## Tiling system ----
tile.tbl = readRDS("/data/LandGIS/models/stacked250m_tiles.rds")
#str(tile.tbl)
pr.dirs = readRDS("/data/LandGIS/models/prediction_dirs.rds")
str(pr.dirs)
new.dirs <- paste0("/data/tt/grid250m/", pr.dirs)
x <- lapply(new.dirs, dir.create, recursive=TRUE, showWarnings=FALSE)

## Fix missing values ----
#inf.tif = list.files("/data/stacked250m", pattern=glob2rx("*.tif$"), full.names = TRUE)
## 48 layers
str(inf.tif)
## test it:
#filter_landmask(i="T38275", tile.tbl, inf.tif)
#filter_landmask(i="T40502", tile.tbl, inf.tif)
#filter_landmask(i="T27198", tile.tbl, inf.tif)
library(snowfall)
sfInit(parallel=TRUE, cpus=64)
sfExport("tile.tbl", "pr.dirs", "filter_landmask", "inf.tif")
sfLibrary(rgdal)
sfLibrary(raster)
out <- sfClusterApplyLB(pr.dirs, function(i){filter_landmask(i, tile.tbl, inf.tif)})
sfStop()

## make clean mosaics:
m.lst = tolower(c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"))
lit.lst = tolower(gsub(" ", "\\.", c("Acid Plutonics", "Acid Volcanic", "Basic Plutonics", "Basic Volcanics", "Carbonate Sedimentary Rock", "Evaporite", "Ice and Glaciers", "Intermediate Plutonics", "Intermediate Volcanics", "Metamorphics", "Mixed Sedimentary Rock", "Pyroclastics", "Siliciclastic Sedimentary", "Unconsolidated Sediment", "Undefined")))
ldf.lst = tolower(gsub(" ", "\\.", c("Breaks Foothills", "Flat Plains", "High Mountains Deep Canyons", "Hills", "Low Hills", "Low Mountains", "Smooth Plains")))

ouf.tif = c(paste0("/data/LandGIS/downscaled250m/clm_cloud.fraction_earthenv.modis.", m.lst, "_p_1km_s0..0cm_2000..2015_v1.0.tif"),
            paste0("/data/LandGIS/layers250m/dtm_landform_usgs.ecotapestry.", ldf.lst, "_p_250m_s0..0cm_2014_v1.0.tif"),
            "/data/LandGIS/downscaled250m/dtm_inundation.extent_giems.d15_m_1km_s0..0cm_2015_v1.0.tif",
            paste0("/data/LandGIS/layers250m/dtm_lithology_usgs.ecotapestry.", lit.lst, "_p_250m_s0..0cm_2014_v1.0.tif"),
            "/data/LandGIS/layers250m/lcv_water.occurance_jrc.surfacewater_p_250m_b0..200cm_1984..2016_v1.0.tif",
            paste0("/data/LandGIS/downscaled250m/clm_snow.prob_esacci.", m.lst, "_p_1km_s0..0cm_2000..2016_v1.0.tif"))
ot.lst = c(rep("Int16", 12), rep("Byte", 48-12)); dstnodat.lst = c(rep(-32768, 12), rep(255, 48-12))
View(data.frame(inf.tif, basename(ouf.tif), ot.lst, dstnodat.lst))

library(snowfall)
sfInit(parallel=TRUE, cpus=18)
sfExport("ouf.tif", "inf.tif", "mosaick_ll", "cellsize", "te", "dstnodat.lst", "ot.lst")
sfLibrary(rgdal)
sfLibrary(raster)
out <- sfClusterApplyLB(1:length(inf.tif), function(x){mosaick_ll(out.tif=ouf.tif[x], in.path="/data/tt/grid250m", ot=ot.lst[x], dstnodata=dstnodat.lst[x], dominant=FALSE, resample="near", metadata=NULL, aggregate=FALSE, te=paste0(te, collapse = " "), tr=cellsize, only.metadata=FALSE, pattern=paste0("*_", basename(inf.tif[x]), "$"))})
sfStop()

## Dominant class ----
## Derive most probable landform / lithology classes:
new.dirs2 <- paste0("/data/tt/LandGIS/calc250m/", pr.dirs)
x <- lapply(new.dirs2, dir.create, recursive=TRUE, showWarnings=FALSE)
## landforms:
lf.input.tif = list.files("/data/LandGIS/layers250m/", pattern=glob2rx("dtm_landform_usgs.ecotapestry.*_p_250m_s0..0cm_2014_v1.0.tif$"), full.names=TRUE)
lf.col.legend = data.frame(Number=1:length(lf.input.tif), Group=basename(lf.input.tif), Name=sapply(lf.input.tif, function(i){strsplit(i, "_")[[1]][3]}))
dominant_class(i="T38275", tile.tbl, input.tif=lf.input.tif, col.legend=lf.col.legend, tvar="landform", out.dir="/data/tt/LandGIS/calc250m")
library(snowfall)
sfInit(parallel=TRUE, cpus=64)
sfExport("tile.tbl", "lf.input.tif", "dominant_class", "lf.col.legend")
sfLibrary(rgdal)
sfLibrary(raster)
sfLibrary(plyr)
out <- sfClusterApplyLB(pr.dirs, function(i){ dominant_class(i, tile.tbl, input.tif=lf.input.tif, col.legend=lf.col.legend, tvar="landform", out.dir="/data/tt/LandGIS/calc250m") })
sfStop()
mosaick_ll(out.tif="/mnt/DATA/LandGIS/layers250m/dtm_landform_usgs.ecotapestry_c_250m_s0..0cm_2014_v1.0.tif", in.path="/data/tt/LandGIS/calc250m", ot="Byte", dstnodata=255, dominant=FALSE, resample="near", metadata=NULL, aggregate=FALSE, te=paste0(te, collapse = " "), tr=cellsize, only.metadata=FALSE, pattern=paste0("*_landform.tif$"))
write.csv(lf.col.legend, "/mnt/DATA/LandGIS/layers250m/dtm_landform_usgs.ecotapestry_c_250m_s0..0cm_2014_v1.0.tif.csv")

## lithology:
lt.input.tif = list.files("/data/LandGIS/layers250m/", pattern=glob2rx("dtm_lithology_usgs.ecotapestry.*_p_250m_s0..0cm_2014_v1.0.tif$"), full.names=TRUE)
lt.col.legend = data.frame(Number=1:length(lt.input.tif), Group=basename(lt.input.tif), Name=sapply(lt.input.tif, function(i){strsplit(i, "_")[[1]][3]}))
#dominant_class(i="T38275", tile.tbl, input.tif=lt.input.tif, col.legend=lt.col.legend, tvar="lithology", out.dir="/data/tt/LandGIS/calc250m")
library(snowfall)
sfInit(parallel=TRUE, cpus=64)
sfExport("tile.tbl", "lt.input.tif", "dominant_class", "lt.col.legend")
sfLibrary(rgdal)
sfLibrary(raster)
sfLibrary(plyr)
out <- sfClusterApplyLB(pr.dirs, function(i){ dominant_class(i, tile.tbl, input.tif=lt.input.tif, col.legend=lt.col.legend, tvar="lithology", out.dir="/data/tt/LandGIS/calc250m") })
sfStop()
mosaick_ll(out.tif="/mnt/DATA/LandGIS/layers250m/dtm_lithology_usgs.ecotapestry_c_250m_s0..0cm_2014_v1.0.tif", in.path="/data/tt/LandGIS/calc250m", ot="Byte", dstnodata=255, dominant=FALSE, resample="near", metadata=NULL, aggregate=FALSE, te=paste0(te, collapse = " "), tr=cellsize, only.metadata=FALSE, pattern=paste0("*_lithology.tif$"))
write.csv(lt.col.legend, "/mnt/DATA/LandGIS/layers250m/dtm_lithology_usgs.ecotapestry_c_250m_s0..0cm_2014_v1.0.tif.csv")

## Covariate layers ----
r = raster("/data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif")
te.ll = as.vector(extent(r))[c(1,3,2,4)]
cellsize.ll = res(r)[1]
p4s = proj4string(r)
g100m.tifs = unlist(sapply(c("coverfraction", "Landsat2018"), function(i){list.files("/mnt/DATA/Landsat", pattern=i, full.names = TRUE)})) ## "geomorphon90m"
g100m.tifs.out = paste0("/mnt/archive/LandGIS/layers250m/", c(paste0("lcv_", c("bare", "crops", "grass", "moss", "shrub", "snow", "tree", "urban", "water.permanent", "water.seasonal"), "_probav.lc100_p_250m_s0..0cm_2017_v1.0.tif"), paste0("lcv_landsat.", c("nir", "red", "swir1", "swir2"), "_wri.forestwatch_m_250m_s0..0cm_2018_v1.2.tif")))
## c(paste0("dtm_", c("eastness100m", "northness100m", "rough.magnitude100m", "slope100m", "vrm100m"),"_merit.dem_m_250m_s0..0cm_2018_v1.0.tif")
View(data.frame(g100m.tifs, g100m.tifs.out))
x = parallel::mclapply(1:length(g100m.tifs), function(i){system(paste0('gdalwarp ', g100m.tifs[i], ' ', g100m.tifs.out[i], ' -r \"average\" -tr ', cellsize.ll, ' ', cellsize.ll, ' -te ', paste(te.ll, collapse = " "), ' -co \"BIGTIFF=YES\" -wm 2000 -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=4\"'))}, mc.cores=length(g100m.tifs))

g1km.tifs = unlist(sapply(c("sm2rain", "floodmap.", "bioclim.var", "temp_worldclim.chelsa"), function(i){list.files("/mnt/DATA/LandGIS/layers1km", pattern=i, full.names = TRUE)}))
## 64
x = parallel::mclapply(1:length(g1km.tifs), function(i){system(paste0('gdalwarp ', g1km.tifs[i], ' /data/LandGIS/downscaled250m/', basename(g1km.tifs[i]), ' -r \"cubicspline\" -tr ', cellsize.ll, ' ', cellsize.ll, ' -te ', paste(te.ll, collapse = " "), ' -co \"BIGTIFF=YES\" -wm 2000 -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=4\"'))}, mc.cores=12)
## wind speed
g5km.tifs = list.files("/mnt/DATA/LandGIS/layers5km", pattern="wind", full.names = TRUE)
## 12
x = parallel::mclapply(1:length(g5km.tifs), function(i){system(paste0('gdalwarp ', g5km.tifs[i], ' /data/LandGIS/downscaled250m/', basename(g5km.tifs[i]), ' -r \"cubicspline\" -tr ', cellsize.ll, ' ', cellsize.ll, ' -te ', paste(te.ll, collapse = " "), ' -co \"BIGTIFF=YES\" -wm 2000 -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=4\"'))}, mc.cores=12)
## precipitation SD
g10km.tifs = list.files("/mnt/DATA/SMRAIN/raw", pattern="_sd.10", full.names = TRUE)
## 12
x = parallel::mclapply(1:length(g10km.tifs), function(i){system(paste0('gdalwarp ', g10km.tifs[i], ' /data/LandGIS/downscaled250m/', basename(g10km.tifs[i]), ' -r \"cubicspline\" -tr ', cellsize.ll, ' ', cellsize.ll, ' -te ', paste(te.ll, collapse = " "), ' -co \"BIGTIFF=YES\" -wm 2000 -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=4\"'))}, mc.cores=12)

## Sample 100k random points ----
#Pnts.sim <- raster::sampleRandom(raster("/data/LandGIS/layers250m/lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0.tif"), size=5e4, sp=TRUE)
## 15 mins
#plot(Pnts.sim)
#saveRDS(Pnts.sim, "/data/LandGIS/models/Pnts_sampleRandom_5e4.rds")
Pnts.sim = readRDS.gz("/data/LandGIS/models/Pnts_sampleRandom_5e4.rds")
d250m.lst = list.files("/mnt/archive/LandGIS/downscaled250m", pattern = glob2rx("*.tif$"), full.names = TRUE)
r250m.lst = list.files("/mnt/archive/LandGIS/layers250m", pattern = glob2rx("*.tif$"), full.names = TRUE)
length(r250m.lst) + length(d250m.lst)
## check if all layers are perfectly aligned
tif.sel = c(d250m.lst, r250m.lst[-unlist(sapply(c("lcv_landmask", "admin", "dec_r", "jan_r", "_c_"), function(i){grep(i, r250m.lst)}))])
summary(file.exists(tif.sel))
x.c = lapply(tif.sel, function(i){as.data.frame(t(unclass(GDALinfo(i))))})
x.c = do.call(rbind, x.c)
View(x.c)
## 356
x = raster::stack(c(d250m.lst, r250m.lst))
## OK

## Overlay rnd points ----
library(snowfall)
sfInit(parallel=TRUE, cpus=28)
sfExport("Pnts.sim", "tif.sel", "over_rds", "saveRDS.gz")
sfLibrary(raster)
x <- sfClusterApplyLB(tif.sel, function(i){over_rds(i, y=Pnts.sim@coords)})
sfStop()
ov.lst = list.files("/data/LandGIS/overlay", pattern = ".rds", full.names = TRUE)
ov.Pnts = dplyr::bind_cols(lapply(ov.lst, function(i){data.frame(readRDS(i))}))
names(ov.Pnts) = gsub(".rds", "", basename(ov.lst))
## remove layers with too many missing values
stat.ov = lapply(ov.Pnts, function(i){data.frame(t(as.vector(summary(i))))})
stat.ov = dplyr::bind_rows(stat.ov)
names(stat.ov) = c("min", "q1st", "median", "mean", "q3rd", "max", "na.count")
stat.ov$layer_name = names(ov.Pnts)
str(stat.ov)
hist(stat.ov$na.count, breaks=35, col="grey")
summary(stat.ov$na.count>15000)
rm.ov = c(which(stat.ov$na.count>15000), which(names(ov.Pnts) %in% "dtm_tpi_merit.dem_m_2km_s0..0cm_2017_v1.0.tif"))
names(ov.Pnts)[rm.ov]
write.csv(stat.ov[,c("layer_name","min","q1st", "median", "mean", "q3rd", "max", "na.count")], "landgis_layers.csv")

#x = list.files("/data/tt/LandGIS/grid250m", glob2rx("*.rds$"), recursive=TRUE, full.names=TRUE)
#unlink(x)
#xs = sapply(x, file.size)
#str(x[which(xs==0)])
#unlink(x[which(xs==0)])
## run in parallel
#system.time( writeRDS.tile(i="T38714", tif.sel, tile.tbl) )
#system.time( writeRDS.tile(i="T52354", tif.sel, tile.tbl) )
## takes >16 hrs
library(snowfall)
snowfall::sfInit(parallel=TRUE, cpus=62)
snowfall::sfLibrary(rgdal)
snowfall::sfExport("writeRDS.tile", "fill_NA_globe", "tile.tbl", "tif.sel", "pr.dirs")
out <- snowfall::sfClusterApplyLB(pr.dirs, function(i){ writeRDS.tile(i, tif.sel, tile.tbl) })
snowfall::sfStop()
save.image.pigz(n.cores=64)

## Check broken files:
# library(snowfall)
# sfInit(parallel=TRUE, cpus=64)
# sfLibrary(rgdal)
# sfExport("tile.tbl", "pr.dirs", "check_RDS")
# out <- sfClusterApplyLB(pr.dirs[], function(i){check_RDS(i, tile.tbl)})
# sfStop()

## Add additional tifs ----
tif.add = list.files("/mnt/archive/LandGIS/layers250m", pattern="2014..2019", full.names=TRUE)
tif.add = tif.add[-sapply(c("dec_r", "jan_r"), function(i){grep(i, tif.add)})]
#system.time( add_writeRDS.tile(i="T38714", tif.add, tile.tbl, tif.rm="proba.v.") )
## takes >16 hrs
library(snowfall)
snowfall::sfInit(parallel=TRUE, cpus=64)
snowfall::sfLibrary(rgdal)
snowfall::sfExport("add_writeRDS.tile", "fill_NA_globe", "tile.tbl", "tif.add", "pr.dirs")
out <- snowfall::sfClusterApplyLB(pr.dirs, function(i){ add_writeRDS.tile(i, tif.add, tile.tbl, tif.rm="proba.v.") })
snowfall::sfStop()

## fill-in missing values (repeated)
#fill_NA_tile(i="T45733", tile.tbl)
library(snowfall)
snowfall::sfInit(parallel=TRUE, cpus=64)
snowfall::sfLibrary(rgdal)
snowfall::sfExport("fill_NA_tile", "fill_NA_globe", "tile.tbl", "pr.dirs")
out <- snowfall::sfClusterApplyLB(pr.dirs, function(i){ fill_NA_tile(i, tile.tbl) })
#out <- snowfall::sfClusterApplyLB(paste0("T", 49015:51757), function(i){ fill_NA_tile(i, tile.tbl) })
snowfall::sfStop()

save.image.pigz(n.cores=64)
