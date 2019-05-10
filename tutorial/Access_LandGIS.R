## Accessing LandGIS data from R
## tom.hengl@opengeohub.org; antonijevic.ognjen@gmail.com

library(rjson)
library(rgdal)
library(fossil)
library(plotKML)

## REST multipoint query ----
path <- geopath(lon1=4.9, lon2=4.9, lat1=52.3, lat2=12)
unlink("test_points.geojson")
writeOGR(as(path, "SpatialPointsDataFrame"), "test_points.geojson", layer="test_points", driver="GeoJSON")
## open layer in a browser:
browseURL('https://landgis.opengeohub.org/#/?base=Stamen%20(OpenStreetMap)&center=49.6466,9.1126&zoom=7&opacity=80&layer=veg_fapar_proba.v.*_d&time=July')
## overlay points and grids:
system('curl -X POST --form "points=@test_points.geojson" --form "layer=pnv_fapar_proba.v.jul_d_1km_s0..0cm_2014..2017_v0.1.tif" https://landgisapi.opengeohub.org/query/points -o results.json')
df <- data.frame(matrix(unlist(rjson::fromJSON(file="results.json")), ncol = 3, byrow = TRUE))
str(df)
plot(df[,2], df[,3], type="l")
## 255 is the missing value

## Write soil profiles as geojson ----
library(sf)
hor <- read.csv('../training_points/soil/NCSS_horizons_sample.csv', stringsAsFactors = FALSE)
site <- read.csv('../training_points/soil/NCSS_sites_sample.csv', stringsAsFactors = FALSE)
## bind to a 3D point data
profs <- plyr::join(site, hor)
coords = c("longitude_decimal_degrees", "latitude_decimal_degrees")
profs <- profs[complete.cases(profs[,coords]),]
profs.st <- st_as_sf(profs, coords = coords, crs = 4326, agr = "constant")
st_write(profs.st, dsn = "NCSS_sample.geojson", layer = "NCSS_sample", driver = "GeoJSON")
## Metadata for columns is at: https://github.com/Envirometrix/LandGISmaps/blob/master/training_points/soil/NCSS_Data_Dictionary_Data_Tier.csv
## Procedures at: https://github.com/Envirometrix/LandGISmaps/blob/master/training_points/soil/NCSS_Analysis_Procedure.csv
## see also https://cran.r-project.org/web/packages/geojsonio/
