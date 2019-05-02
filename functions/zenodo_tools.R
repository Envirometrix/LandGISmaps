## upload to zenodo using API ()

#library(rjson)
library(jsonlite)
library(RCurl)
library(rgdal)

#in.files = list.files("/mnt/earthimg/LandGIS/layers500m", pattern=glob2rx("veg_*_mod17a2h.*_*_500m_s0..0cm_*..*_*.tif"), full.names =TRUE) ## GPP
#in.files = list.files("/data/LandGIS/layers250m", pattern=glob2rx("veg_fapar_proba.v.*_d_250m_s0..0cm_2014..2017_v1.0.tif"), full.names =TRUE) ## FAPAR mean
#in.files = list.files("/mnt/DATA/LandGIS/layers1km", pattern=glob2rx("*mod11a2*.tif$"), full.names =TRUE) ## MODIS LST
#in.files = "/mnt/projects/mangroves/soildata/mangroves_SOC_points.gpkg"
in.files = list.files("/data/LandGIS/predicted250m", pattern=glob2rx("sol_order_usda.soiltax.*_p_250m_s0..0cm_1950..2017_v0.1.tif$"), full.names =TRUE)
## check file size:
sum(sapply(in.files, file.size))/1e9

str(in.files)
TOKEN = scan("~/TOKEN_ACCESS", what="character")
#dep.id = "1442733" ## GPP
#dep.id = "1450337" ## FAPAR mean
#dep.id = "1435938" ## MODIS LST
dep.id = "1469348" ## Mangroves
## list all files currently available:
list.files = paste0('https://zenodo.org/api/deposit/depositions/', dep.id, '/files?access_token=', TOKEN)
f.lst = fromJSON(list.files)
#str(f.lst)
## get the bucket ID:
x = fromJSON(system(paste0('curl -H \"Accept: application/json\" -H \"Authorization: Bearer ', TOKEN, '\" \"https://www.zenodo.org/api/deposit/depositions/', dep.id, '\"'), intern=TRUE, show.output.on.console = FALSE))
## upload missing files
for(i in 1:length(in.files)){
  out.file = basename(in.files[i])
  if(!(out.file %in% f.lst$filename)){
   system(paste0('curl -X PUT -H \"Accept: application/json\" -H \"Content-Type: application/octet-stream\" -H \"Authorization: Bearer ', TOKEN, '\" -d @', in.files[i], ' ', x$links$bucket, '/', out.file))
    #system(paste0('curl -i ', list.files, ' -F name=', out.file,' -F file=@', in.files[i]))
  }
}
