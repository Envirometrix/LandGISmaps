## Generation of global river density, surface water, precipitation and wetlands
## tom.hengl@opengeohub.org

library(maptools)
library(raster)
library(rgdal)
library(snowfall)
load(".RData")
source('/data/LandGIS/R/LandGIS_functions.R')

## Global EA grid ----
gri1d.pol = readOGR("360x114global.shp")
cellsize = 250
#te0 = c(-20037508,-8683260, 20037508, 8683260)
te = c(-20037508,-6728980, 20037508, 8421750)
gh.prj = "+proj=igh +ellps=WGS84 +units=m +no_defs"

## Goode Homolosine ----
gh.shp = "/data/RiverDensity/GlobalGrid/GoodeHomolosine/Goode_Homolosine_domain.shp"
gh.mask = "/data/RiverDensity/GlobalGrid/GoodeHomolosine/CounterDomain.geojson"
ogrInfo(gh.mask)
gh.pol = readOGR(gh.mask, disambiguateFIDs = TRUE)
spplot(gh.pol)
bbox(gh.pol)
gh.pol$FID = 1
unlink(gh.shp)
writeOGR(gh.pol, gh.shp, "Goode_Homolosine_domain", "ESRI Shapefile")
system(paste0('saga_cmd -c=64 grid_gridding 0 -INPUT \"', gh.shp, '\" -FIELD \"FID\" -GRID \"/data/RiverDensity/GlobalGrid/GoodeHomolosine/Goode_Homolosine_domain_250m.sgrd\" -GRID_TYPE 1 -TARGET_DEFINITION 0 -TARGET_USER_SIZE ', cellsize, ' -TARGET_USER_XMIN ', te[1]+cellsize/2,' -TARGET_USER_XMAX ', te[3]-cellsize/2, ' -TARGET_USER_YMIN ', te[2]+cellsize/2,' -TARGET_USER_YMAX ', te[4]-cellsize/2))
system(paste0('gdal_translate /data/RiverDensity/GlobalGrid/GoodeHomolosine/Goode_Homolosine_domain_250m.sdat /data/RiverDensity/GlobalGrid/GoodeHomolosine/Goode_Homolosine_domain_250m.tif -a_srs \"', gh.prj, '\" -co \"COMPRESS=DEFLATE\" -ot \"Byte\"'))
unlink("/data/RiverDensity/GlobalGrid/GoodeHomolosine/Goode_Homolosine_domain_250m.sdat")
## 160,300 by 60,602 pixels

## Land mask 250m ----
r = raster("/data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif")
te.ll = as.vector(extent(r))[c(1,3,2,4)]
cellsize.ll = res(r)[1]
p4s = proj4string(r)

## Tiling system GH ----
library(GSIF)
library(RSAGA)

## 100 km
objS <- GDALinfo("/data/RiverDensity/GlobalGrid/GoodeHomolosine/Goode_Homolosine_domain_250m.tif")
tileS.lst <- getSpatialTiles(objS, block.x=100000, return.SpatialPolygons=TRUE)
tileS.tbl <- getSpatialTiles(objS, block.x=100000, return.SpatialPolygons=FALSE)
tileS.tbl$ID = as.character(1:nrow(tileS.tbl))
## 60,952 tiles
tileS.pol = SpatialPolygonsDataFrame(tileS.lst, tileS.tbl)
proj4string(gh.pol) = proj4string(tileS.pol)
ov_tiles = over(tileS.pol, gh.pol)
summary(!is.na(ov_tiles))
## 48,678 tiles with values
tileS.pol = tileS.pol[!is.na(ov_tiles$FID),]
unlink("tiles_GH_100km.shp")
writeOGR(tileS.pol, "tiles_GH_100km.shp", "tiles_GH_100km", "ESRI Shapefile")
writeOGR(tileS.pol, "tiles_GH_100km.gpkg", "tiles_GH_100km", "GPKG")
save.image()
## running mosaics with >10,000 tiles is very slow

## 250 km
tileB.lst <- getSpatialTiles(objS, block.x=250000, return.SpatialPolygons=TRUE)
tileB.tbl <- getSpatialTiles(objS, block.x=250000, return.SpatialPolygons=FALSE)
tileB.tbl$ID = as.character(1:nrow(tileB.tbl))
tileB.pol = SpatialPolygonsDataFrame(tileB.lst, tileB.tbl)
ovB_tiles = over(tileB.pol, gh.pol)
summary(!is.na(ovB_tiles))
## tiles with values
tileB.pol = tileB.pol[!is.na(ovB_tiles$FID),]
#plot(tileB.pol[1])

## Land mask in GH ----
latlon2gh(input.file="/data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif", output.file="/data/RiverDensity/GlobalGrid/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.gh.tif", land.grid=tileB.pol, pixsize=250, ot="Byte", dstnodata=255)
#system(paste0('gdalwarp /data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif /data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.gh.tif -t_srs \"', gh.prj, '\" -r \"near\" -ot \"Byte\" -co \"BIGTIFF=YES\" -tr 250 250 -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=ALL_CPUS\" --config CHECK_WITH_INVERT_PROJ TRUE -te ', paste(te, collapse = " ")))
## 160,300 x 60,603 pixels
system('gdal_translate /data/RiverDensity/GlobalGrid/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.gh.tif /data/tmp/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.gh.sdat -ot \"Byte\" -of \"SAGA\"')
## ERROR 6: Unable to set GeoTransform, SAGA binary grids only support the same cellsize in x-y.
## Very frustrating - needs to be fixed by hand!
gh.sgrd = "/data/tmp/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.gh.sgrd"
grd = read.table(gh.sgrd, sep = "\t", stringsAsFactors = FALSE)
grd$V2[7] = paste0("= ", te[1]+cellsize/2)
grd$V2[8] = paste0("= ", te[2]+cellsize/2)
grd$V2[11] = paste0("= ", cellsize)
data.table::fwrite(grd, file=gh.sgrd, sep="\t", col.names=FALSE, append=TRUE)
unlink("ov_tiles_GH_100km.shp")
system(paste0('saga_cmd shapes_grid 2 -GRIDS=\"/data/tmp/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.gh.sgrd\" -POLYGONS=\"tiles_GH_100km.shp\" -PARALLELIZED=1 -RESULT=\"ov_tiles_GH_100km.shp\"'))
tileS.land.pol = readOGR("ov_tiles_GH_100km.shp")
summary(tileS.land.pol$lcv_landmas.5==2)
#Mode   FALSE    TRUE    NA's 
#logical   16673   31994      11
tileS.land.pol = tileS.land.pol[!tileS.land.pol$lcv_landmas.5==2 & !is.na(tileS.land.pol$lcv_landmas.5),]

## Global data layers

## Surface Water 1984-2018 ----
## https://global-surface-water.appspot.com/download
occ.tif = "/data/Landsat/100m/Water_occurrence.tif"
ext.tif = "/data/Landsat/100m/Water_extent.tif"
system(paste0('gdalwarp /data/Landsat/100m/Water_occurrence.tif /data/LandGIS/layers250m/lcv_water.occurance_jrc.surfacewater_p_250m_b0..200cm_1984..2018_v1.1.tif -r \"average\" -ot \"Byte\" -tr ', cellsize.ll, ' ', cellsize.ll, ' -te ', paste(te.ll, collapse = " "), ' -dstnodata 255 -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=ALL_CPUS\"'))
latlon2gh(input.file=occ.tif, output.file="/data/RiverDensity/GlobalGrid/lcv_water.occurance_jrc.surfacewater_p_250m_b0..200cm_1984..2016_v1.0.gh.tif", land.grid=tileB.pol, pixsize=250, ot="Byte", dstnodata=255, resample = "average")
## MERIT DEM
latlon2gh(input.file="/mnt/earthimg/MERIT/MERIT_dem_100m_v28_July_2017_i.tif", output.file="/data/RiverDensity/GlobalGrid/GoodeHomolosine/dtm_elevation_merit.dem_m_250m_s0..0cm_2017_v1.0.gh.tif", land.grid=tileB.pol, pixsize=250, ot="Int16", dstnodata=-32768, resample = "average")
latlon2gh(input.file="/data/LandGIS/layers250m/lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0.tif", output.file="/data/RiverDensity/GlobalGrid/GoodeHomolosine/lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0.gh.tif", land.grid=tileB.pol, pixsize=250, ot="Int16", dstnodata=-32768, resample = "near")

## Tropical wetlands ----
## Tropical and Subtropical Wetlands Distribution version 2
## https://data.cifor.org/dataset.xhtml?persistentId=doi:10.17528/CIFOR/DATA.00058
wet.tif = "./Tropical_and_Subtropical_Wetlands/TROP-SUBTROP_WetlandV2_2016_CIFOR.tif"
system(paste0('gdalwarp ', wet.tif,' /data/LandGIS/layers250m/lcv_wetlands.tropics_icraf.v2_c_250m_b0..200cm_2010..2015_v1.0.tif -r \"near\" -ot \"Byte\" -tr ', cellsize.ll, ' ', cellsize.ll, ' -te ', paste(te.ll, collapse = " "), ' -dstnodata 255 -co \"COMPRESS=DEFLATE\"'))
latlon2gh(input.file=wet.tif, output.file="/data/RiverDensity/GlobalGrid/lcv_wetlands.tropics_icraf.v2_c_250m_b0..200cm_2010..2015_v1.0.gh.tif", land.grid=tileB.pol, pixsize=250, ot="Byte", dstnodata=255)

## River Classification (GloRiC) ----
## https://www.hydrosheds.org/pages/gloric
riv.shp = "./GloRiC_v10_shapefile/GloRiC_v10_shapefile/GloRiC_v10.shp"
ogrInfo(riv.shp)
## 100 m
system(paste0('saga_cmd -c=64 grid_gridding 0 -INPUT \"', riv.shp, '\" -FIELD \"Class_hydr\" -GRID \"/data/RiverDensity/GlobalGrid/GloRiC_v10_shapefile/GloRiC_v10.sgrd\" -GRID_TYPE 0 -TARGET_DEFINITION 0 -TARGET_USER_SIZE ', 0.0008333333))
system(paste0('gdal_translate /data/RiverDensity/GlobalGrid/GloRiC_v10_shapefile/GloRiC_v10.sdat /data/Landsat/100m/GloRiC_v10.tif -a_srs \"EPSG:4326\" -co \"COMPRESS=DEFLATE\" -ot \"Byte\"'))
unlink("/data/RiverDensity/GlobalGrid/GloRiC_v10_shapefile/GloRiC_v10.sdat")
## CONVERT TO 0-100 numbers
#system('gdal_calc.py -A /data/Landsat/100m/GloRiC_v10.tif --outfile=/data/Landsat/100m/GloRiC_v10_b.tif --calc="0*(A<1)" --calc="100*(A>=1)" --co=\"COMPRESS=DEFLATE\" --type=\"Byte\"')
# In QGIS: ("GloRiC_v10@1" < 1) * 0 + ("GloRiC_v10@1" >= 1) * 100
## takes too much time / does not run in parallel
obj100m = GDALinfo("/data/Landsat/100m/GloRiC_v10.tif")
tile100m.tbl <- getSpatialTiles(obj100m, block.x=2, return.SpatialPolygons=FALSE)
tile100m.tbl$ID = as.character(1:nrow(tile100m.tbl))
#raster_calc_P(i=round(runif(1)*nrow(tile100m.tbl)), tile100m.tbl, in.tif="/data/Landsat/100m/GloRiC_v10.tif")
library(snowfall)
sfInit(parallel=TRUE, cpus=parallel::detectCores())
sfExport("raster_calc_P", "tile100m.tbl")
sfLibrary(rgdal)
out.lst <- sfClusterApplyLB(1:nrow(tile100m.tbl), function(i){ raster_calc_P(i, tile100m.tbl, in.tif="/data/Landsat/100m/GloRiC_v10.tif") })
sfStop()
tmp.lst = list.files(path="/data/tmp/tiled", pattern=glob2rx("T_*.tif$"), full.names=TRUE)
out.tmp <- tempfile(fileext = ".txt")
vrt.tmp <- tempfile(fileext = ".vrt")
cat(tmp.lst, sep="\n", file=out.tmp)
system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
system(paste0('gdalwarp ', vrt.tmp, ' /data/LandGIS/layers250m/hyd_river.density_gloric_p_250m_b0..0cm_2018_v10.tif -ot \"Byte\" -dstnodata \"255\" -co \"BIGTIFF=YES\" -multi -wo \"NUM_THREADS=ALL_CPUS\" -wm 2000 -co \"COMPRESS=DEFLATE\" -r \"average\" -overwrite -tr ', cellsize.ll, ' ', cellsize.ll, ' -te ', paste(te.ll, collapse = " ")))
unlink(tmp.lst)
latlon2gh(input.file="/data/LandGIS/layers250m/hyd_river.density_gloric_p_250m_b0..0cm_2018_v10.tif", output.file="hyd_river.density_gloric_p_250m_b0..0cm_2018_v10.gh.tif", land.grid=tileB.pol, pixsize=250, ot="Byte", dstnodata=255)

## Wetlands at 500 m ----
## https://www.earth-syst-sci-data.net/11/189/2019/essd-11-189-2019.html
system(paste0('gdalwarp /mnt/DATA/GlobalSurfaceWater/TIFF/CW-WTD/CW_WTD.tif /data/LandGIS/layers250m/lcv_wetlands.cw_upmc.wtd_c_250m_b0..200cm_2010..2015_v1.0.tif -r \"near\" -ot \"Byte\" -tr ', cellsize.ll, ' ', cellsize.ll, ' -te ', paste(te.ll, collapse = " "), ' -dstnodata 255 -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=ALL_CPUS\"'))
latlon2gh(input.file="/mnt/DATA/GlobalSurfaceWater/TIFF/CW-WTD/CW_WTD.tif", output.file="lcv_wetlands.cw_upmc.wtd_c_250m_b0..200cm_2010..2015_v1.0.gh.tif", land.grid=tileB.pol, pixsize=250, ot="Byte", dstnodata=255, resample="near")

## MERIT Hydro at 100 m ----
## https://eos.org/research-spotlights/a-more-accurate-global-river-map
upa.lst = list.files("/mnt/DATA/MERIT/UDA", pattern=glob2rx("*_upa.tif$"), full.names = TRUE, recursive = TRUE)
cat(upa.lst, sep="\n", file=paste0("/mnt/DATA/MERIT/UDA_100m.txt"))
system(paste0('gdalbuildvrt -input_file_list /mnt/DATA/MERIT/UDA_100m.txt /mnt/DATA/MERIT/UDA_100m.vrt'))
GDALinfo("/mnt/DATA/MERIT/UDA_100m.vrt")
## Float32!!
## convert using = log10( X + 1 )*10
system(paste0('gdalwarp /mnt/DATA/MERIT/UDA_100m.vrt /data/Landsat/100m/MERIT_upstream.area.tif -overwrite -multi -wo \"NUM_THREADS=ALL_CPUS\" -r \"near\" -tr 0.0008333333 0.0008333333 -co \"BIGTIFF=YES\" -co "COMPRESS=DEFLATE"'))
latlon2gh(input.file="/mnt/DATA/MERIT/UDA_100m.vrt", output.file="hyd_upstream.area_merit.hydro_m_250m_b0..0cm_2017_v1.0.gh.tif", land.grid=tileB.pol, pixsize=250, ot="Float32", dstnodata=-9999, resample="average", cleanup.files=FALSE)
## QGIS: log10("hyd_upstream.area_merit.hydro_m_250m_b0..0cm_2017_v1.0.gh@1" + 1 ) * 10
system('gdal_translate hyd_log.upstream.area_merit.hydro_m_250m_b0..0cm_2017_v1.0.gh.tif hyd_log1p.upstream.area_merit.hydro_m_250m_b0..0cm_2017_v1.0.gh.tif -co "COMPRESS=DEFLATE" -ot \"Byte\" -a_nodata 255')
#unlink("hyd_log.upstream.area_merit.hydro_m_250m_b0..0cm_2017_v1.0.gh.tif")
#unlink("hyd_upstream.area_merit.hydro_m_250m_b0..0cm_2017_v1.0.gh.tif")

## Land cover 100 m ----
## https://lcviewer.vito.be/
lc.lst = list.files("/mnt/DATA/Copernicus_vito/GLC100m", pattern=glob2rx("E120N80_ProbaV_LC100_epoch2015_global_v2.0.1_*-layer_EPSG-4326.tif$"), full.names = TRUE)
lc.leg = sapply(lc.lst, function(i){strsplit(strsplit(i, split = "v2.0.1_")[[1]][2], "_EPSG")[[1]][1]})
paste(lc.leg)
for(j in 1:length(lc.leg)){
  tif.lst = list.files("/mnt/DATA/Copernicus_vito/GLC100m", pattern=glob2rx(paste0("*_ProbaV_LC100_epoch2015_global_v2.0.1_", lc.leg[j], "_EPSG-4326.tif$")), full.names = TRUE) ## 94
  cat(tif.lst, sep="\n", file=paste0("/mnt/DATA/Copernicus_vito/GLC100m/", lc.leg[j], ".txt"))
  system(paste0('gdalbuildvrt -input_file_list /mnt/DATA/Copernicus_vito/GLC100m/', lc.leg[j], '.txt /mnt/DATA/Copernicus_vito/GLC100m/', lc.leg[j], '.vrt'))
}
# [1] "bare-coverfraction-layer"            "crops-coverfraction-layer"          
# [3] "forest-type-layer"                   "grass-coverfraction-layer"          
# [5] "moss-coverfraction-layer"            "shrub-coverfraction-layer"          
# [7] "snow-coverfraction-layer"            "tree-coverfraction-layer"           
# [9] "urban-coverfraction-layer"           "water-permanent-coverfraction-layer"
# [11] "water-seasonal-coverfraction-layer"
## Global mosaics 100 m (10 mins):
in.lst = paste0('/mnt/DATA/Copernicus_vito/GLC100m/', lc.leg, '.vrt')
sfInit(parallel=TRUE, cpus=3)
sfExport("lc.leg", "in.lst")
sfLibrary(raster)
sfLibrary(rgdal)
x <- sfClusterApplyLB(1:length(lc.leg), function(k){ if(!file.exists(paste0('/data/Landsat/100m/ProbaV_LC100_', lc.leg[k], '.tif'))){ system(paste0('gdalwarp ', in.lst[k], ' /data/Landsat/100m/ProbaV_LC100_', lc.leg[k], '.tif -overwrite -dstnodata 255 -ot Byte -multi -wo \"NUM_THREADS=20\" -r \"near\" -tr 0.0008333333 0.0008333333 -co \"BIGTIFF=YES\" -co "COMPRESS=DEFLATE"')) } } )
sfStop()
## GH
wat.glc = paste0('/data/Landsat/100m/ProbaV_LC100_', lc.leg[11], '.tif')
latlon2gh(input.file=wat.glc, output.file="/data/RiverDensity/GlobalGrid/lcv_water.seasonal_probav.glc.lc100_p_250m_b0..0cm_2015_v2.0.1.gh.tif", land.grid=tileB.pol, resample = "average", pixsize=250, ot="Byte", dstnodata=255)

## Aggregate values ----
g.lst = list.files(pattern=glob2rx("*.gh.tif$"), full.names=TRUE)
s = stack(g.lst)
#i = which(tileS.land.pol$ID==56993)
#x = grid_sum_tiled(i, tile.tbl=tileS.land.pol@data, g.lst)
sfInit(parallel=TRUE, cpus=64)
sfExport("grid_sum_tiled", "tileS.land.pol", "g.lst")
sfLibrary(rgdal)
agg.lst <- sfClusterApplyLB(1:nrow(tileS.land.pol@data), function(i){ try( grid_sum_tiled(i, tile.tbl=tileS.land.pol@data, g.lst) , silent = TRUE ) })
sfStop()
sel.df = sapply(agg.lst, is.numeric)
#agg.tbl = plyr::rbind.fill(agg.lst)
agg.tbl = as.data.frame(do.call(rbind, agg.lst))
hist(agg.tbl$hyd_log1p.upstream.area_merit.hydro_m_250m_b0..0cm_2017_v1.0.gh.tif, breaks=45)
hist(agg.tbl$lcv_water.occurance_jrc.surfacewater_p_250m_b0..200cm_1984..2016_v1.0.gh.tif, breaks=45)
tileS.land.pol@data = cbind(tileS.land.pol@data[,1:9], agg.tbl[,-which(names(agg.tbl) == "ID")])
unlink("tiles_GH_100km_land.gpkg")
writeOGR(tileS.land.pol, "tiles_GH_100km_land.gpkg", "tiles_GH_100km_land", "GPKG")

tmp.lst = list.files(path="/data/tmp/tiled", pattern=glob2rx("T*_hydrogrids.tif$"), full.names=TRUE)
out.tmp <- tempfile(fileext = ".txt")
vrt.tmp <- "/data/tmp/hydrogrids.vrt"
cat(tmp.lst, sep="\n", file=out.tmp)
system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
#system(paste0('gdalwarp /data/tmp/hydrogrids.vrt /data/RiverDensity/GlobalGrid/GoodeHomolosine/hydrogrids_250m.gh.tif -r \"near\" -co \"BIGTIFF=YES\" -tr 250 250 -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -multi -wo \"NUM_THREADS=ALL_CPUS\" -te ', paste(te, collapse = " ")))
#system(paste0('gdal_translate /data/tmp/hydrogrids.vrt /data/RiverDensity/GlobalGrid/GoodeHomolosine/hydrogrids_250m.gh.tif -co \"BIGTIFF=YES\" -co \"COMPRESS=DEFLATE\"'))
#unlink(tmp.lst)
x = file.rename(tmp.lst, gsub("/tiled", "/hydrogrids", tmp.lst))
