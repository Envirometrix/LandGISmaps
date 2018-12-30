## Derivation of SOC change for 2001--2015 (based on the land cover changes)
## Ichsani@envirometrix.net and tom.hengl@envirometrix.net

#setwd("/data/LDN")
load(".RData")
library(aqp)
library(plyr)
library(dplyr)
library(sp)
library(rgdal)
library(raster)
library(foreign)
library(utils)
library(R.utils)
library(snowfall)
library(parallel)
library(tools)
library(GSIF)
library(plotKML)
library(RSAGA)
library(data.table)
library(compiler)

source('functions_SOC_change.R')
source("/data/LandGIS/R/saveRDS_functions.R")

## Resample all maps to the same grid ----
r.lc = raster("/data/LDN/ESA_landcover/ESACCI-LC-L4-LCCS-Map-300m-P1Y-1992_2015-v2.0.7.tif")
res(r.lc)
lc.leg = read.csv("/data/LDN/ESA_landcover/ESACCI-LC-Legend.csv", sep = ";")
lcA.leg = read.csv("ESA_landcover_legend.csv")

## Soil carbon stock map ----
## 0-30 cm only
sumf <- function(x){calc(x, sum, na.rm=TRUE)}
s1 = raster::stack(paste0("/data/LandGIS/predicted250m/", c("sol_organic.carbon.stock_msa.kgm2_m_250m_b0..10cm_1950..2017_v0.2.tif", "sol_organic.carbon.stock_msa.kgm2_m_250m_b10..30cm_1950..2017_v0.2.tif")))
beginCluster()
r <- clusterR(s1, fun=sumf, filename="/data/LandGIS/predicted250m/sol_organic.carbon.stock_msa.kgm2_m_250m_b0..30cm_1950..2017_v0.2.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"), NAflag=-32767, overwrite=TRUE)
endCluster()
#system('gdal_translate /data/LandGIS/predicted250m/sol_organic.carbon.stock_msa.kgm2_m_250m_b0..10cm_1950..2017_v0.2.tif /data/tmp/sol_organic.carbon.stock_msa.kgm2_m_250m_b0..10cm_1950..2017_v0.2.sdat -of \"SAGA\" -ot \"Int16\"')
#system('gdal_translate /data/LandGIS/predicted250m/sol_organic.carbon.stock_msa.kgm2_m_250m_b10..30cm_1950..2017_v0.2.tif /data/tmp/sol_organic.carbon.stock_msa.kgm2_m_250m_b10..30cm_1950..2017_v0.2.sdat -of \"SAGA\" -ot \"Int16\"')
#system('gdal_translate /data/tmp/sol_organic.carbon.stock_msa.kgm2_m_250m_b0..30cm_1950..2017_v0.2.sdat /data/LandGIS/predicted250m/sol_organic.carbon.stock_msa.kgm2_m_250m_b0..30cm_1950..2017_v0.2.tif -ot \"Int16\" -co \"COMPRESS=DEFLATE\"')
## resample to LC grid
system(paste0('gdalwarp /data/tmp/sol_organic.carbon.stock_msa.kgm2_m_250m_b0..30cm_1950..2017_v0.2.sdat OCSTHA_M_30cm_300m_ll.tif -multi -wo \"NUM_THREADS=32\" -co \"BIGTIFF=YES\" -wm 2000 -co \"COMPRESS=DEFLATE\" -overwrite -tr ', res(r.lc)[1],' ', res(r.lc)[2], ' -ot \"Int16\" -te ', paste(as.vector(extent(r.lc))[c(1,3,2,4)], collapse=" ")))
## Bioclimatic zones (http://ecoexplorer.arcgis.com/eco/maps.html):
#system(paste0('gdalwarp EF_Bio_Des_250m.tif EF_Bio_Des_300m.tif -ot \"Byte\" -multi -co \"BIGTIFF=YES\" -wm 2000 -co \"COMPRESS=DEFLATE\" -tr ', res(r.lc)[1],' ', res(r.lc)[2], ' -r \"near\" -te ', paste(as.vector(extent(r.lc))[c(1,3,2,4)], collapse=" ")))

## bioclimatic zones legend ----
cl.leg = read.csv("/data/LDN/ESA_landcover/Bioclimatic_legend.csv")
cl.leg$number_agg = as.integer(cl.leg$levs_agg)
str(cl.leg)
## Number of combinations ----
comb.lc = expand.grid(lc.leg$NB_LAB, lc.leg$NB_LAB)
comb.lc$LCC = paste(comb.lc$Var1, comb.lc$Var2, sep="_")
comb.leg = expand.grid(comb.lc$LCC, unique(cl.leg$number_agg))
comb.leg$LCC_CL = paste(comb.leg$Var1, comb.leg$Var2, sep="_")
comb.leg = data.frame(Value=1:nrow(comb.leg), NAME=comb.leg$LCC_CL)
str(comb.leg)
comb.leg$LC_1 = plyr::join(data.frame(NB_LAB=sapply(paste(comb.leg$NAME), function(x){strsplit(split="_", x)[[1]][1]})), lc.leg)$LCCOwnLabel
comb.leg$AGG_NAME_1 = plyr::join(data.frame(Value=sapply(paste(comb.leg$NAME), function(x){strsplit(split="_", x)[[1]][1]})), lcA.leg)$AGG_NAME
comb.leg$LC_2 = plyr::join(data.frame(NB_LAB=sapply(paste(comb.leg$NAME), function(x){strsplit(split="_", x)[[1]][2]})), lc.leg)$LCCOwnLabel
comb.leg$AGG_NAME_2 = plyr::join(data.frame(Value=sapply(paste(comb.leg$NAME), function(x){strsplit(split="_", x)[[1]][2]})), lcA.leg)$AGG_NAME
comb.leg$CLIMATE = plyr::join(data.frame(number_agg=sapply(paste(comb.leg$NAME), function(x){strsplit(split="_", x)[[1]][3]})), cl.leg, match="first")$levs_agg
comb.leg[100,]
write.csv(comb.leg, "LandCover_climate_CF.csv")
## Combination LC and climate only:
combA.leg = expand.grid(lc.leg$NB_LAB, unique(cl.leg$number_agg))
combA.leg$LCC_CL = paste(combA.leg$Var1, combA.leg$Var2, sep="_")
combA.leg = data.frame(Value=1:nrow(combA.leg), NAME=combA.leg$LCC_CL)
## 380 combinations

## Tiling system 300 m ----
obj <- GDALinfo("/data/LDN/ESA_landcover/ESACCI-LC-L4-LCCS-Map-300m-P1Y-1992_2015-v2.0.7.tif")
tile.lst <- getSpatialTiles(obj, block.x=2, return.SpatialPolygons=TRUE)
tile.tbl <- getSpatialTiles(obj, block.x=2, return.SpatialPolygons=FALSE)
tile.tbl$ID = as.character(1:nrow(tile.tbl))
str(tile.tbl)
## 16,200 tiles
tile.pol = SpatialPolygonsDataFrame(tile.lst, tile.tbl)
writeOGR(tile.pol, "tiles.shp", "tiles", "ESRI Shapefile")
## Overlay tiles and land cover (fully parallelized) and remove pixels without any land cover data:
system(paste('gdal_translate /data/LDN/ESA_landcover/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2000-v2.0.7.tif ESACCI-LC-L4-LCCS-Map-300m-P1Y-2000-v2.0.7.sdat -of \"SAGA\" -ot \"Byte\"'))
system(paste0('saga_cmd -c=64 shapes_grid 2 -GRIDS=\"ESACCI-LC-L4-LCCS-Map-300m-P1Y-2000-v2.0.7.sgrd\" -POLYGONS=\"tiles.shp\" -PARALLELIZED=1 -RESULT=\"ov_ADMIN_tiles.shp\"'))
ov_ADMIN = readOGR("ov_ADMIN_tiles.shp", "ov_ADMIN_tiles")
summary(sel.t <- !ov_ADMIN@data[,"ESACCI.LC.L.5"]==210)
## 7109 tiles with values
ov_ADMIN = ov_ADMIN[sel.t,]
#plot(ov_ADMIN)  
t.sel = as.character(ov_ADMIN$ID)
new.dirs <- paste0("/data/tt/LDN/tiled/T", t.sel)
x <- lapply(new.dirs, dir.create, recursive=TRUE, showWarnings=FALSE)

## test it:
#SOC_change_ts(i=12873, tile.tbl=tile.tbl, CF.tbl=CF.tbl, cl.leg=cl.leg)
#SOC_change_ts(i=5642, tile.tbl=tile.tbl, CF.tbl=CF.tbl, cl.leg=cl.leg)

library(snowfall)
sfInit(parallel=TRUE, cpus=parallel::detectCores())
sfExport("SOC_change_ts", "tile.tbl", "CF.tbl", "cl.leg", "prop_FC", "t.sel", "myFuncCmp")
sfLibrary(rgdal)
sfLibrary(plyr)
sfLibrary(Matrix)
sfLibrary(data.table)
sfLibrary(compiler)
#x <- sfClusterApplyLB(as.numeric(t.sel)[sample(length(t.sel), parallel::detectCores())], function(x){ try( SOC_change_ts(x, tile.tbl=tile.tbl, CF.tbl=CF.tbl, cl.leg=cl.leg) ) })
x <- sfClusterApplyLB(rev(as.numeric(t.sel)), function(x){ try( SOC_change_ts(x, tile.tbl=tile.tbl, CF.tbl=CF.tbl, cl.leg=cl.leg) ) })
sfStop()

## clean-up:
#x = list.files("/data/tt/LDN/tiled", pattern=".tif", full.names = TRUE, recursive = TRUE)
## 5292
#unlink(x)

## Final mosaics ----
r = raster("/data/LandGIS/layers250m/lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
cellsize = res(r)[1]

vars = c("dOCS", paste0("OCS", 2001:2015))
filename.lst = paste0("/data/LandGIS/predicted250m/", c("ldg_organic.carbon.stock_msa.kgm2_td_250m_b0..30cm_2001..2015_v0.2.tif", paste0("sol_organic.carbon.stock_msa.kgm2_m_250m_b0..30cm_", 2001:2015, "_v0.1.tif")))
sfInit(parallel=TRUE, cpus=25)
sfExport("make_mosaic", "vars", "filename.lst", "cellsize", "te")
t <- sfLapply(1:length(vars), function(x){ make_mosaic(vars[x], filename=filename.lst[x], tr=cellsize, te=paste(te, collapse = " "))  })
sfStop()

## Robinson projection:
system(paste0('gdalwarp /mnt/DATA/LandGIS/predicted250m/ldg_organic.carbon.stock_msa.kgm2_td_250m_b0..30cm_2001..2015_v0.1.tif ldg_organic.carbon.stock_msa.kgm2_td_5km_b0..30cm_2001..2015_v0.1.tif -r \"average\" -tr 10000 10000 -t_srs \"+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs\" -te -16810131 -6625155 16810131 8343004 -co \"COMPRESS=DEFLATE\"'))
## 50 km
system(paste0('gdalwarp /mnt/DATA/LandGIS/predicted250m/ldg_organic.carbon.stock_msa.kgm2_td_250m_b0..30cm_2001..2015_v0.1.tif ldg_organic.carbon.stock_msa.kgm2_td_50km_b0..30cm_2001..2015_v0.1.tif -r \"average\" -tr 50000 50000 -t_srs \"+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs\" -te -16810131 -6625155 16810131 8343004 -co \"COMPRESS=DEFLATE\"'))

## Forest cover ----
## http://www.unep-wcmc.org/resources-and-data/generalised-original-and-current-forest
ofc = "/mnt/DATA/WHRC_soilcarbon/model10km/other/ofc_gen.dbf"
shpF.db <- read.dbf(ofc)
shpF.db$dbf$TYPE_INT = as.integer(shpF.db$dbf$TYPE)
str(shpF.db)
write.dbf(shpF.db, ofc)
forestcover_leg = data.frame(Value=1:length(levels(shpF.db$dbf$TYPE)), Classes=levels(shpF.db$dbf$TYPE))
write.csv(forestcover_leg, "forestcover_leg.csv")
## convert to geotifs:
system(paste0('saga_cmd -c=64 grid_gridding 0 -INPUT \"/mnt/DATA/WHRC_soilcarbon/model10km/other/ofc_gen.shp\" -FIELD \"TYPE_INT\" -GRID \"./250m_ll/ofc_gen.sgrd\" -GRID_TYPE 2 -TARGET_DEFINITION 0 -TARGET_USER_SIZE ', cellsize, ' -TARGET_USER_XMIN ', te[1]+cellsize/2,' -TARGET_USER_XMAX ', te[3]-cellsize/2, ' -TARGET_USER_YMIN ', te[2]+cellsize/2,' -TARGET_USER_YMAX ', te[4]-cellsize/2))
## Intact forest landscapes ----
## http://www.intactforests.org/data.ifl.html
for(j in c(2000,2013,2016)){
  system(paste0('saga_cmd -c=64 grid_gridding 0 -INPUT \"/mnt/DATA/IFL/IFL_',j,'/ifl_',j,'.shp\" -FIELD \"IFL_ID\" -GRID \"./250m_ll/ifl_',j,'.sgrd\" -GRID_TYPE 2 -TARGET_DEFINITION 0 -TARGET_USER_SIZE ', cellsize, ' -TARGET_USER_XMIN ', te[1]+cellsize/2,' -TARGET_USER_XMAX ', te[3]-cellsize/2, ' -TARGET_USER_YMIN ', te[2]+cellsize/2,' -TARGET_USER_YMAX ', te[4]-cellsize/2))
}

#x = list.files("/data/tt/LandGIS/calc250m", "FC", recursive = TRUE, full.names = TRUE)
#unlink(x)

## 7 periods: historic, 1995, 2000, 2005, 2010, 2013 and 2016:
tileL.tbl = readRDS("/data/LandGIS/models/stacked250m_tiles.rds")
prL.dirs = readRDS("/data/LandGIS/models/prediction_dirs.rds")
tileL.pol = readOGR("/data/LandGIS/models/tiles_ll_100km.shp")
tileL.pol = tileL.pol[paste0("T", tileL.pol$ID) %in% prL.dirs,]
#historic_forest(i="T38715", tileL.tbl)
#historic_forest(i="T35350", tileL.tbl)

sfInit(parallel=TRUE, cpus=parallel::detectCores())
sfExport("historic_forest", "tileL.tbl", "prL.dirs")
sfLibrary(raster)
sfLibrary(rgdal)
out <- sfClusterApplyLB(prL.dirs, function(i){try( historic_forest(i, tileL.tbl) )})
sfStop()

## Final mosaics ----
filename.lst = paste0("/data/LandGIS/predicted250m/ldg_forest.cover_esacci.ifl_c_250m_s0..0cm_", c("BC1000",1995,2000,2005,2010,2013,2016), "_v0.1.tif")
## 7 maps
varn.lst = paste0("FC", c(0,1995,2000,2005,2010,2013,2016))

library(snowfall)
sfInit(parallel=TRUE, cpus=length(filename.lst))
sfExport("varn.lst", "make_mosaic", "filename.lst", "te", "cellsize")
out <- sfClusterApplyLB(1:length(filename.lst), function(x){ try( make_mosaic(x=varn.lst[x], filename=filename.lst[x], path="/data/tt/LandGIS/calc250m", tr=cellsize, te=paste(te, collapse = " "), ot="Byte", dstnodata="255") )})
sfStop()
