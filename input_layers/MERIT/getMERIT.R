## Preprocessing MERIT DEM (http://hydro.iis.u-tokyo.ac.jp/~yamadai/MERIT_DEM/)
## tom.hengl@gmail.com

setwd("/data/MERIT")
load(".RData")
library(rgdal)
library(parallel)
library(raster)
setwd("/data/MERIT")
source("DEM_functions.R")
load("/data/models/equi7t1.rda")
load("/data/models/equi7t3.rda")
#tile.names <- names(equi7t1)
## Continents:
ext <- as.list(1:7)
ext[[1]] <- c(-32.42, -42.90, 64.92, 41.08) ## "AF"
ext[[2]] <- c(-66.4, -56.17, 55.44, -44.30) ## "AN"
ext[[3]] <- c(40.35, -4.67, 180, 87.37) ## "AS"
ext[[4]] <- c(-31.4, 32.2, 60.6, 82.40) ## "EU"
ext[[5]] <- c(-180, -9.71, -10.3, 83.3) ## "NA"
ext[[6]] <- c(92.68, -53.25, 180, 26.38) ## "OC"
ext[[7]] <- c(-122.85, -56.29, -16.04, 20.23) ## "SA"
names(ext) <- names(equi7t3)

## Download all tiles into the dir ----
pw = scan("~/meritdem_pw", what="character")
system(paste0('wget -N -nv -r -np -nH --accept "*.tar.gz" --reject="index.html" --cut-dirs=4 --level=5 --http-user="globaldem" --http-password=', pw, ' "http://hydro.iis.u-tokyo.ac.jp/~yamadai/MERIT_DEM/"'))
gz.lst = list.files(pattern=glob2rx("*.tar.gz"))
## Untar (in parallel not a good idea unfortunately):
#mclapply(gz.lst, FUN=function(i){untar(i)}, mc.cores=6) 	
lapply(gz.lst, function(i){untar(i)})

## Make a mosaic:
dem.lst <- list.files(path="/data/MERIT", pattern=glob2rx("*_dem.flt$"), full.names=TRUE, recursive=TRUE)
## 1150 tiles
## check if the untar went ok:
dem.size.lst = sapply(dem.lst, file.size)
str(dem.lst[dem.size.lst<1.4e8])
#unlink(dem.lst[dem.size.lst<1.4e8])
#mclapply(gz.lst, FUN=function(i){untar(i, extras="--skip-old-files")}, mc.cores=6)
#lapply(gz.lst, function(i){untar(i, extras="--skip-old-files")})

cat(dem.lst, sep="\n", file="MERIT_tiles.txt")
system('gdalbuildvrt -input_file_list MERIT_tiles.txt MERIT_100m.vrt')
system('gdalinfo MERIT_100m.vrt')
## Size is 432000, 174000
## Pixel Size = (0.000833333353512,-0.000833333353512)
#system(paste0('gdalwarp MERIT_100m.vrt MERIT_dem_1km_v28_July_2017.tif -ot \"Int16\" -co \"BIGTIFF=YES\" -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -tr ', 1/120, ' ', 1/120))
system('gdalwarp MERIT_100m.vrt MERIT_dem_100m_v28_July_2017.tif -s_srs \"+proj=longlat +datum=WGS84\" -ot \"Int16\" -co \"BIGTIFF=YES\" -r \"near\" -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -multi')
## takes 6-7 hours... 206GB file?!
system('gdal_translate MERIT_dem_100m_v28_July_2017.tif MERIT_dem_100m_v28_July_2017_i.tif -ot \"Int16\" -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\" -co \"NUM_THREADS=24\"')
system('gdaladdo MERIT_dem_100m_v28_July_2017_i.tif 2 4 8 16 32 64 128')
## File now 19GB
## Add metadata ----
md.Fields = c("SERIES_NAME", "ATTRIBUTE_UNITS_OF_MEASURE", "CITATION_URL", "CITATION_ORIGINATOR",	"CITATION_ADDRESS",	"PUBLICATION_DATE", "PROJECT_URL", "DATA_LICENSE")
md.Values = c("MERIT DEM: Multi-Error-Removed Improved-Terrain DEM", "meter", "http://dx.doi.org/10.1002/2017GL072874", "Institute of Industrial Sciences, The University of Tokyo", "yamadai [at] rainbow.iis.u-tokyo.ac.jp", "15 May, 2017", "http://hydro.iis.u-tokyo.ac.jp/~yamadai/MERIT_DEM/", "https://creativecommons.org/licenses/by-nc/4.0/")
m = paste('-mo ', '\"', md.Fields, "=", md.Values, '\"', sep="", collapse = " ")
command = paste0('gdal_edit.py ', m,' MERIT_dem_100m_v28_July_2017_i.tif')
system (command, intern=TRUE)
system('gdalinfo MERIT_dem_100m_v28_July_2017_i.tif')

## Derive DEM parameters
load("equi7t3.rda")
#tile.tif(x="MERIT_dem_100m_v28_July_2017_i.tif", equi7t3[["NA"]], out.dir="/data/MDEM/stiled100m/", tr=100)
## Resample to various resolutions ----
x <- lapply(equi7t3, function(i){tile.tif(x="MERIT_dem_100m_v28_July_2017_i.tif", t=i)})
x <- lapply(equi7t3, function(i){tile.tif(x="MERIT_dem_100m_v28_July_2017_i.tif", t=i, out.dir="/data/MDEM/stiled250m/", tr=250, r="average")})
x <- lapply(equi7t3, function(i){tile.tif(x="MERIT_dem_100m_v28_July_2017_i.tif", t=i, out.dir="/data/MDEM/stiled1km/", tr=1000, r="average")})
x <- lapply(equi7t3, function(i){tile.tif(x="MERIT_dem_100m_v28_July_2017_i.tif", t=i, out.dir="/data/MDEM/stiled2km/", tr=2500, r="average")})
## Mosaics (per continent):
for(j in 1:length(equi7t3)){
  if(!file.exists(paste0("/data/MDEM/DEM_", names(equi7t3)[j], "_250m.tif"))){
    t.lst <- list.files(path="/data/MDEM/stiled250m", pattern=glob2rx(paste0("DEM_", names(equi7t3)[j], "_*_*.tif$")), full.names=TRUE, recursive=TRUE)
    unlink("my_liste.txt")
    cat(t.lst, sep="\n", file="my_liste.txt")
    system(paste0('gdalbuildvrt -input_file_list \"my_liste.txt\" ', names(equi7t3)[j], '.vrt'))
    system(paste0('gdalwarp ', paste0(names(equi7t3)[j], ".vrt"), ' ', paste0("/data/MDEM/DEM_", names(equi7t3)[j], "_250m.tif"), ' -r \"near\" -ot \"Int16\" -co \"COMPRESS=DEFLATE\"'))
  }
}

regs <- c("AF","AS","EU","NA","OC","SA")
## Derive DEM parameters per continent ---
## VERY COMPUTATIONAL!
setwd("/data/MDEM")
sapply(regs, function(x){ saga_DEM_derivatives(INPUT=paste0("DEM_", x, "_2km.tif")) })
sapply(regs, function(x){ saga_DEM_derivatives(INPUT=paste0("DEM_", x, "_1km.tif")) })
sapply(regs, function(x){ saga_DEM_derivatives(INPUT=paste0("DEM_", x, "_100m.tif"), sel=c("SLP","MRN")) })
sapply(regs, function(x){ saga_DEM_derivatives(INPUT=paste0("DEM_", x, "_250m.tif"), sel=c("SLP","CPR","CRV","VBF","VDP","OPN","DVM","MRN","TPI")) })


## Sample distributions ----
x = list.files("/data/MDEM", pattern=glob2rx("DEM_EU_1km_*.sdat$"), full.names = TRUE)
ds = parallel::mclapply(x, function(i){sampleRandom(raster(i), 300)}, mc.cores = length(x))
ds.r = lapply(ds, range, na.rm=TRUE)
names(ds.r) = sapply(x, function(i){strsplit(basename(i), "_")[[1]][4]})
ds.r

## Convert all sdat files to GeoTIFFs ----
sdat.lst = list.files("/data/MDEM", pattern=glob2rx("DEM_*_*_*.sdat$"), full.names = TRUE)
x = parallel::mclapply(sdat.lst, sdat2geotif, mc.cores = 20)
tif.lst = list.files("/data/MDEM", pattern=glob2rx("*.tif$"), full.names = TRUE)
unlink(sdat.lst)

## grid definition:
r <- raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
ncols = ncol(r)
nrows = nrow(r)
cellsize = res(r)[1]
te = as.vector(extent(r))[c(1,3,2,4)]

## Global mosaics 250m resolution ----
dem.lst = c("devmean","devmean2","tpi","mrn","twi","downlocal","down","uplocal", "openn", "openp", "slope", "vbf")
out.dem.lst = c("MERITDEM_dvm", "MERITDEM_dv2mer", "MERITDEM_tpimer", "MERITDEM_mrnmer", "MERITDEM_twimer", "MERITDEM_crdmer", "MERITDEM_crvmer", "MERITDEM_crumer", "MERITDEM_negmer", "MERITDEM_posmer", "MERITDEM_slpmer", "MERITDEM_vbfmer")
tiled.lst = lapply(dem.lst, function(x){list.files(path="/data/MDEM", pattern=glob2rx(paste0("DEM_*_250m_", x, ".tif$")), full.names=TRUE)})
names(tiled.lst) = out.dem.lst
out.dem.lst = out.dem.lst[sapply(tiled.lst, function(x){ !length(x)==0})]
tiled.lst = tiled.lst[sapply(tiled.lst, function(x){ !length(x)==0})]
#system(paste0('gdalinfo ', tiled.lst[[1]][2])) 
ot.DEM <- sapply(tiled.lst, function(x){ paste(attr(GDALinfo(x[2]), "df")$GDType) })
nodata.DEM <- ifelse(ot.DEM=="Byte", 255, ifelse(ot.DEM=="Int16", -32768, NA))
tile.names <- paste(sapply(basename(tiled.lst[[1]]), function(i){strsplit(i, "_")[[1]][2]}))
ext.DEM <- ext[which(names(ext) %in% tile.names)]

## run mosiacking in parallel:
sfInit(parallel=TRUE, cpus=length(tiled.lst))
sfExport("equi7t1", "ext.DEM", "out.dem.lst", "tiled.lst", "tiles_equi7t3", "mosaick_equi7", "nodata.DEM", "ot.DEM", "tile.names", "cellsize", "te")
out <- sfClusterApplyLB(1:length(out.dem.lst), function(x){try( mosaick_equi7(i="dominant", varn=out.dem.lst[x], ext.lst=ext.DEM, tr=cellsize, r250m=TRUE, ot=ot.DEM[x], dstnodata=nodata.DEM[x], in.path="/data/MDEM", out.path='/data/MDEM', tile.names=tile.names, build.pyramids=TRUE, vrt.tmp=tiled.lst[[x]], cleanup=FALSE, te=paste(te, collapse = " ")) )})
sfStop()

system(paste0('gdalwarp MERIT_dem_100m_v28_July_2017_i.tif /data/OpenLandData/layers250m/MERITDEM_dem_250m_ll.tif -r \"average\" -tr ', res(r)[1], ' ', res(r)[2], ' -te ', paste(extent(r)[c(1,3,2,4)], collapse = " "), ' -co \"COMPRESS=DEFLATE\"'))
tif.250m = list.files("/data/OpenLandData/layers250m", pattern=glob2rx("MERITDEM_*.tif$"), full.names = TRUE)
x = parallel::mclapply(tif.250m, function(i){ system(paste0('gdalwarp ', i, ' ', gsub("250m", "1km", i), ' -r \"average\" -tr ', 1/120, ' ', 1/120, ' -te ', paste(extent(r)[c(1,3,2,4)], collapse = " "), ' -co \"COMPRESS=DEFLATE\"')) }, mc.cores = 24)
save.image()

## clean-up:
#del.lst = list.files(path="/data/MDEM", pattern=glob2rx("*_250m_r.tif$"), full.names=TRUE, recursive=TRUE)
#unlink(del.lst)
