Soil texture classes (USDA system) for 6 soil depths (0, 10, 30, 60, 100 and 200 cm) at 250 m
==============================================================================================

   Soil texture classes (USDA system) for 6 standard soil depths (0, 10, 30, 60, 100 and 200 cm) at 250 m. Derived from predicted soil texture fractions using the soiltexture package in R. Processing steps are described in detail ** [ here ](https://github.com/Envirometrix/LandGISmaps/tree/master/soil) ** . Antartica is not included. 

  To access and visualize maps use: ** [ https://landgis.opengeohub.org ](https://landgis.opengeohub.org) ** 

  If you discover a bug, artifact or inconsistency in the LandGIS maps, or if you have a question please use some of the following channels: 

  *  Technical issues and questions about the code: [ https://github.com/Envirometrix/LandGISmaps/issues ](https://github.com/Envirometrix/LandGISmaps/issues) 
 *  General questions and comments: [ https://disqus.com/home/forums/landgis/ ](https://disqus.com/home/forums/landgis/) 
   All files internally compressed using "COMPRESS=DEFLATE" creation option in GDAL. File naming convention: 

  *  sol = theme: soil, 
 *  texture.class = variable: soil texture class, 
 *  usda = determination method: USDA texture triangle, 
 *  c = factor, 
 *  250m = spatial resolution / block support: 250 m, 
 *  b10..10cm = vertical reference: 10 cm depth below surface, 
 *  1950..2017 = time reference: period 1950-2017, 
 *  v0.2 = version number: 0.2,