Soil water content (volumetric %) for 33kPa and 1500kPa suctions predicted at 6 standard depths (0, 10, 30, 60, 100 and 200 cm) at 250 m resolution
====================================================================================================================================================

   Soil water content (volumetric) in percent for 33 kPa and 1500 kPa suctions predicted at 6 standard depths (0, 10, 30, 60, 100 and 200 cm) at 250 m resolution. Training points are based on a global compilation of soil profiles ( [ USDA NCSS ](https://ncsslabdatamart.sc.egov.usda.gov/) , [ AfSPDB ](https://www.isric.org/projects/africa-soil-profiles-database-afsp) , [ ISRIC WISE ](https://data.isric.org/geonetwork/srv/eng/catalog.search#/metadata/a351682c-330a-4995-a5a1-57ad160e621c) , [ EGRPR ](http://egrpr.esoil.ru/) , [ SPADE ](https://esdac.jrc.ec.europa.eu/content/soil-profile-analytical-database-2) , [ CanNPDB ](https://open.canada.ca/data/en/dataset/6457fad6-b6f5-47a3-9bd1-ad14aea4b9e0) , [ UNSODA ](https://data.nal.usda.gov/dataset/unsoda-20-unsaturated-soil-hydraulic-database-database-and-program-indirect-methods-estimating-unsaturated-hydraulic-properties) , [ SWIG ](https://doi.pangaea.de/10.1594/PANGAEA.885492) , [ HYBRAS ](http://www.cprm.gov.br/en/Hydrology/Research-and-Innovation/HYBRAS-4208.html) and [ HydroS ](http://dx.doi.org/10.4228/ZALF.2003.273) ). Data import steps are available [ ** here ** ](https://github.com/Envirometrix/LandGISmaps/blob/master/training_points/soil/Import_soilWater_variables.R) . Spatial prediction steps are described in detail ** [ here ](https://github.com/Envirometrix/LandGISmaps/tree/master/soil/soil_water) ** . Note: these are actually measured and mapped soil content values; no Pedo-Transfer-Functions have been used (except to fill-in the missing NCSS bulk densities). Available water capacity in mm (derived as a difference between field capacity and wilting point multiplied by layer thickness) per layer is available ** [ here ](https://doi.org/10.5281/zenodo.2629148) ** . Antartica is not included. 

  To access and visualize some of the maps use: ** [ https://landgis.opengeohub.org ](https://landgis.opengeohub.org/) ** 

  If you discover a bug, artifact or inconsistency in the LandGIS maps, or if you have a question please use some of the following channels: 

  *  Technical issues and questions about the code: [ https://github.com/Envirometrix/LandGISmaps/issues ](https://github.com/Envirometrix/LandGISmaps/issues) 
 *  General questions and comments: [ https://disqus.com/home/forums/landgis/ ](https://disqus.com/home/forums/landgis/) 
   All files internally compressed using "COMPRESS=DEFLATE" creation option in GDAL. File naming convention: 

  *  sol = theme: soil, 
 *  watercontent.33kPa = water content (volumetric percent) under field capacity (33 kPa suction), 
 *  usda.4b1c = determination method: laboratory method code, 
 *  m = mean value, 
 *  250m = spatial resolution / block support: 250 m, 
 *  b10..10cm = vertical reference: 10 cm depth below surface, 
 *  1950..2017 = time reference: period 1950-2017, 
 *  v0.1 = version number: 0.1,