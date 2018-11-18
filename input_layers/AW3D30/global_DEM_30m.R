## Create global 30 m resolution grids based on AW3D30 and OSM:
## tom.hengl@envirometrix.net

## install packages best from github:
#devtools::install_github("ropensci/osmdata")
#devtools::install_github("ecohealthalliance/fasterize")
library(osmdata)
library(fasterize)
library(rgdal)
library(sf)
library(parallel)

gz.lst = list.files("./v1804", pattern=glob2rx("*.tar.gz"), full.names = TRUE)
tif.lst <- mclapply(gz.lst, FUN=function(i){untar(i, list = TRUE)}, mc.cores=60)
#tif.lst <- lapply(gz.lst, function(i){untar(i, list = TRUE)})
#del.lst <- list.files(recursive=TRUE, full.names=TRUE)
#sel <- c(grep(pattern=glob2rx("*_HDR.txt$"), del.lst), grep(pattern=glob2rx("*_LST.txt$"), del.lst), grep(pattern=glob2rx("*_STK.tif$"), del.lst), grep(pattern=glob2rx("*_QAI.txt$"), del.lst), grep(pattern=glob2rx("*_MSK.tif$"), del.lst))
#unlink(del.lst[sel])
## only DSM file needed:
lapply(1:length(gz.lst), function(i){untar(gz.lst[i], files=tif.lst[[i]][grep(pattern=glob2rx("*_DSM.tif$"), tif.lst[[i]])], verbose=TRUE, extras="--keep-old-files")})
dem.lst <- list.files(pattern=glob2rx("*_DSM.tif$"), full.names=TRUE, recursive=TRUE)
## 22079 tiles
## check if the untar went ok:
dem.size.lst = sapply(dem.lst, file.size)
str(dem.lst[dem.size.lst<1.4e6])
## two tiles corrup!
#unlink("./S010E015_S005E020/S008E015_AVE_DSM.tif")
#unlink("./S015W075_S010W070/S014W074_AVE_DSM.tif")
## compress in parallel:
#seq.lst = seq(1, length(dem.lst), by=60)
#sapply(1:length(seq.lst), function(i){system(paste0("7za a -t7z AW3D30_30m_v1804.7z ", paste(dem.lst[i:(i+1)], collapse = " "), " -mmt -aos"))})

## Make a global mosaic:
cat(dem.lst, sep="\n", file="AW3D30_tiles.txt")
system('gdalbuildvrt -input_file_list AW3D30_tiles.txt AW3D30_30m.vrt')
system('gdalinfo AW3D30_30m.vrt')
## Size is 1296000, 594000
## Pixel Size = (0.000277777777778,-0.000277777777778)
#system(paste0('gdalwarp AW3D30_30m.vrt AW3D30_dem_1km_v19_July_2018.tif -ot \"Int16\" -co \"BIGTIFF=YES\" -wm 2000 -srcnodata \"-9999\" -overwrite -multi -co \"COMPRESS=DEFLATE\" -tr ', 1/120, ' ', 1/120))
#unlink("AW3D30_dem_30m_v19_July_2018.tif")
#system('gdalwarp AW3D30_30m.vrt AW3D30_dem_30m_v19_July_2018.tif -s_srs \"+proj=longlat +datum=WGS84\" -ot \"Int16\" -co \"BIGTIFF=YES\" -srcnodata \"-9999\" -r \"near\" -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -multi -te -180 -62.00081 179.99994 87.37000 -wo \"NUM_THREADS=ALL_CPUS\"')
## takes ca 1hrs
r100m = raster("/mnt/DATA/MERIT/MERIT_dem_100m_v28_July_2017_i.tif")
r100m
system(paste0('gdalwarp AW3D30_30m.vrt AW3D30_dem_100m_v19_July_2018.tif -s_srs \"+proj=longlat +datum=WGS84\" -ot \"Int16\" -co \"BIGTIFF=YES\" -srcnodata \"-9999\" -dstnodata \"-9999\" -tr ', res(r100m)[1],' ', res(r100m)[2],' -r \"average\" -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -multi -te -180 -60.00042 179.9996 84.99958 -wo \"NUM_THREADS=ALL_CPUS\"'))
## takes 6-7 hours... 206GB file?!
#system('gdal_translate AW3D30_dem_30m_v28_July_2017.tif AW3D30_dem_30m_v28_July_2017_i.tif -ot \"Int16\" -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\" -co \"NUM_THREADS=24\"')
#system('gdaladdo AW3D30_dem_30m_v28_July_2017_i.tif 2 4 8 16 32 64 128')
## Add metadata ----
md.Fields = c("SERIES_NAME", "ATTRIBUTE_UNITS_OF_MEASURE", "CITATION_URL", "CITATION_ORIGINATOR",	"CITATION_ADDRESS",	"PUBLICATION_DATE", "PROJECT_URL", "DATA_LICENSE")
md.Values = c("AW3D30: v1804", "meter", "https://ieeexplore.ieee.org/document/8128293/", "ALOS Science Project, Earth Observation Research Center (EORC), Japan Aerospace Exploration Agency (JAXA)", "aproject@jaxa.jp", "April, 2018", "http://www.eorc.jaxa.jp/ALOS/en/aw3d30/index.htm", "https://creativecommons.org/licenses/by/4.0/")
m = paste('-mo ', '\"', md.Fields, "=", md.Values, '\"', sep="", collapse = " ")
command = paste0('gdal_edit.py ', m,' AW3D30_dem_100m_v19_July_2018.tif')
system (command, intern=TRUE)
system('gdalinfo AW3D30_dem_100m_v19_July_2018.tif')

## Boulder sample data set:
ext = c(-105.90, 39.70, -104.65, 40.39)
system(paste0('gdalwarp AW3D30_30m.vrt /home/dev/Downloads/Boulder_AW3D30_dem_30m_v19_July_2018.tif -s_srs \"+proj=longlat +datum=WGS84\" -ot \"Int16\" -co \"BIGTIFF=YES\" -srcnodata \"-9999\" -dstnodata \"-9999\" -te ', paste(ext, collapse = " "), '  -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\"'))
system(paste0('gdalwarp /mnt/DATA/MERIT/MERIT_dem_100m_v28_July_2017_i.tif /home/dev/Downloads/Boulder_MERIT_dem_100m_v28_July_2017.tif -s_srs \"+proj=longlat +datum=WGS84\" -ot \"Int16\" -co \"BIGTIFF=YES\" -srcnodata \"-9999\" -dstnodata \"-9999\" -te ', paste(ext, collapse = " "), '  -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\"'))

