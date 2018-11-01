## Derive global density of earthquakes using the National Geophysical Data Center / World Data Service (NGDC/WDS): Significant Earthquake Database. National Geophysical Data Center, NOAA. doi:10.7289/V5TD9V7K
## USGS Earthquake Archives http://earthquake.usgs.gov/earthquakes/
## tom.hengl@gmail.com

setwd("/mnt/nas/earthquakes")
load(".RData")
library(sp)
library(rgdal)
library(raster)
library(spatstat)
library(maptools)
library(plyr)
system("gdal-config --version")
## 2.2.1
t_srs <- "+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

## Download quakes:
x = sapply(1900:2018, function(i){ if(!file.exists(paste0("quakes_",i,"_magnitude4.csv"))) download.file(paste0('https://earthquake.usgs.gov/fdsnws/event/1/query?format=csv&starttime=', i, '-01-01&endtime=', i+1, '-01-02&minmagnitude=4'), destfile=paste0("quakes_",i,"_magnitude4.csv"), method="curl") })

## read quakes and focus on intensity:
quakes <- rbind.fill(lapply(list.files(pattern=glob2rx("quakes_*_*.csv")), read.csv, stringsAsFactors=FALSE))
#plot(quakes[,c("longitude","latitude")])
#x <- as.data.frame(readOGR("quakes.shp", "quakes"))
#x <- plyr::rename(x, replace=c("coords.x1"="longitude", "coords.x2"="latitude", "YEAR"="time", "MAGF"="mag"))
#sel = c("longitude","latitude","mag","time")
#quakes <- rbind(quakes[,sel], x[,sel])
quakes$mag <- ifelse(is.na(quakes$mag), 4, quakes$mag)
quakes$ID <- paste(quakes$longitude, quakes$latitude, quakes$mag, quakes$time, sep="_")
#quakes <- quakes[!duplicated(quakes$ID),]
str(quakes) ## 405,885 quakes 4+
save(quakes, file="quakes.rda")
coordinates(quakes) <- ~ longitude + latitude
proj4string(quakes) = "+proj=longlat +ellps=WGS84"

## volcanoes (http://www.ngdc.noaa.gov/hazard/volcano.shtml):
volcanoes <- read.csv("volcanoes.csv")
volcanoes <- volcanoes[!is.na(volcanoes$Latitude),]
str(volcanoes)
save(volcanoes, file="volcanoes.rda")
coordinates(volcanoes) <- ~ Longitude + Latitude
proj4string(volcanoes) = "+proj=longlat +ellps=WGS84"

GDALinfo("/data/MOD11A2/landMask1km_B.sdat")
unlink("landMask5km.tif")
system(paste0(gdalwarp, ' /data/MOD11A2/landMask1km_B.sdat landMask5km.tif -r \"near\" -tr 0.05 0.05 -te -180 -70 180 84 -co \"COMPRESS=DEFLATE\"'))
## reproject to TM projection to minimize distortions:
GDALinfo("landMask5km.tif")
unlink("landMask5km_tm.tif")
system(paste0(gdalwarp, ' landMask5km.tif landMask5km_tm.tif -r \"near\" -tr 5000 5000 -t_srs \"', t_srs, '\" -co \"COMPRESS=DEFLATE\"'))
mask <- readGDAL("landMask5km_tm.tif")
mask$total = 1
wowin <- as(mask["total"], "owin")
quakes.xy <- spTransform(quakes, CRS(proj4string(mask)))
unlink("quakes_tm.shp")
writeOGR(quakes.xy, "quakes_tm.shp", "quakes_tm", "ESRI Shapefile")
#summary(wowin[["m"]][1,])
#summary(wowin[["m"]][,1])
#wowin <- owin(c(-180,180), c(-90,90))
quakes.ppp <- ppp(quakes.xy@coords[,1], quakes.xy@coords[,2], marks=quakes.xy$mag, window=wowin)
## 853 points were rejected as lying outside the specified window
#plot(quakes.ppp)
## TAKES >1hr:
densMAG <- density.ppp(quakes.ppp, sigma=30000, weights=quakes.ppp$marks)
dens.MAG = as(densMAG, "SpatialGridDataFrame")
dens.MAG$vf = dens.MAG$v*1e9
plot(log1p(raster(dens.MAG["vf"])), col=rev(bpy.colors(30)))
unlink("dens.MAG.tif")
writeGDAL(dens.MAG["vf"], "dens.MAG.tif", type="Int16", mvFlag=-32768, options="COMPRESS=DEFLATE")
## This one takes only few minutes, but shows some artifacts (circles)!
#system(paste0('saga_cmd -c=24 grid_gridding 6 -POINTS=\"quakes_tm.shp\" -POPULATION=\"mag\" -RADIUS=120000 -KERNEL=1 -TARGET_DEFINITION=0 -TARGET_USER_XMIN=', mask@bbox["x","min"],' -TARGET_USER_XMAX=', mask@bbox["x","max"],' -TARGET_USER_YMIN=', mask@bbox["y","min"],' -TARGET_USER_YMAX=', mask@bbox["y","max"],' -TARGET_USER_SIZE=5000 -TARGET_USER_FITS=0 -TARGET_OUT_GRID=\"dens.MAG.sgrd\"'))
#system("7za a dens.MAG.7z dens.MAG.*")
#plot(raster("dens.MAG.sdat"))
system(paste0('gdalwarp /mnt/nas/NGA/gshap_arcgis/gshap_globe gshap_globe.tif -tr 5000 5000 -t_srs \"', t_srs, '\" -te -20037498 -11025344  20032502  18764656 -co \"COMPRESS=DEFLATE\" -overwrite'))
dens.MAG$gshap = readGDAL("gshap_globe.tif")$band1
dens.spc = as(dens.MAG[c("vf","gshap")], "SpatialPixelsDataFrame")
str(dens.spc@data)
dens.MAG.spc = GSIF::spc(dens.spc, ~vf+gshap)
summary(dens.MAG.spc@predicted$PC1)
#plot(raster(dens.MAG.spc@predicted["PC1"]))
dens.MAG.spc@predicted$vf = dens.MAG.spc@predicted$PC1*100
writeGDAL(dens.MAG.spc@predicted["vf"], "PC1_dens_MAG.tif", type="Int16", mvFlag=-32768, options="COMPRESS=DEFLATE")

r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
system(paste0('gdalwarp PC1_dens_MAG.tif earthquakes_dens_MAG_1km_ll.tif -ot \"Int16\" -co \"COMPRESS=DEFLATE\" -dstnodata \"-32768\" -te ', paste(te, collapse=" "),' -tr ', 1/120, ' ', 1/120, ' -r \"cubicspline\" -s_srs \"', proj4string(mask), '\" -t_srs \"+proj=longlat +ellps=WGS84\" -overwrite'))

## volcanoes ----
## NOT USED
volcanoes.xy <- spTransform(volcanoes, CRS(proj4string(mask)))
volcanoes.xy$marks = 1
unlink("volcanoes_tm.shp")
writeOGR(volcanoes.xy, "volcanoes_tm.shp", "volcanoes_tm", "ESRI Shapefile")
volcanoes.ppp <- ppp(volcanoes.xy@coords[,1], volcanoes.xy@coords[,2], marks=volcanoes.xy$mag, window=wowin)
## 16 points were rejected as lying outside the specified window
#plot(quakes.ppp)
## TAKES >1hr:
dens.volc <- density.ppp(volcanoes.ppp, sigma=60000)
dens.volc = as(dens.volc, "SpatialGridDataFrame")
dens.volc$vf = dens.volc$v*1e12
plot(raster(dens.volc["vf"]), col=rev(bpy.colors(30)))
unlink("volcanoes5km.tif")
writeGDAL(dens.volc["vf"], "volcanoes5km.tif", type="Int16", options="COMPRESS=DEFLATE")
#system(paste0('/usr/local/bin/saga_cmd -c=48 grid_gridding 6 -POINTS=\"volcanoes_tm.shp\" -POPULATION=\"marks\" -RADIUS=60000 -KERNEL=1 -TARGET_DEFINITION=0 -TARGET_USER_XMIN=', mask@bbox["x","min"],' -TARGET_USER_XMAX=', mask@bbox["x","max"],' -TARGET_USER_YMIN=', mask@bbox["y","min"],' -TARGET_USER_YMAX=', mask@bbox["y","max"],' -TARGET_USER_SIZE=5000 -TARGET_USER_FITS=0 -TARGET_OUT_GRID=\"volcanoes5km.sgrd\"'))
#system("7za a volcanoes5km.7z volcanoes5km.*")
#plot(raster("volcanoes5km.sdat"))
#points(volcanoes.xy)
