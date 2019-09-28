Long-term MODIS LST day-time and night-time temperatures, sd and differences at 1 km based on the 2000–2017 time series
========================================================================================================================

   Layers include: Land Surface Temperature daytime monthly median value 2000–2017, Land Surface Temperature daytime monthly sd value 2000–2017, Land Surface Temperature daytime monthly day-night difference 2000–2017. Derived using the [ data.table package and quantile function in R ](https://github.com/Envirometrix/LandGISmaps/tree/master/input_layers/MOD11A2) . For more info about the MODIS LST product see: https://lpdaac.usgs.gov/dataset\_discovery/modis/modis\_products\_table/mod11a2\_v006. Antartica is not included. 

  To access and visualize maps use: ** [ https://landgis.opengeohub.org ](https://landgis.opengeohub.org) ** 

  If you discover a bug, artifact or inconsistency in the LandGIS maps, or if you have a question please use some of the following channels: 

  *  Technical issues and questions about the code: [ https://github.com/Envirometrix/LandGISmaps/issues ](https://github.com/Envirometrix/LandGISmaps/issues) 
 *  General questions and comments: [ https://disqus.com/home/forums/landgis/ ](https://disqus.com/home/forums/landgis/) 
   All files internally compressed using "COMPRESS=DEFLATE" creation option in GDAL. File naming convention: 

  *  clm = theme: climate, 
 *  lst = variable: land surface temperature, 
 *  mod11a2.oct.day = determination method: MOD11A2 product, day time values for October, 
 *  d = median value / sd = standard deviation / u.975 = aggregation/statistics method: 97.5% probability upper quantile, 
 *  1km = spatial resolution / block support: 1 km, 
 *  s0..0cm = vertical reference: land surface, 
 *  2000..2017 = time reference: from 2000 to 2017, 
 *  v1.0 = version number: 1.0,