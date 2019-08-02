Fraction of Absorbed Photosynthetically Active Radiation (FAPAR) at 250 m monthly for period 2014-2017 based on COPERNICUS land products
=========================================================================================================================================

   Long-term monthly Fraction of Absorbed Photosynthetically Active Radiation (FAPAR) median value at 250 m based on the time-series of [ COPERNICUS FAPAR ](https://land.copernicus.eu/global/products/fapar) . Derived using the data.table package and quantile function in R. Processing steps are available [ ** here ** ](https://github.com/Envirometrix/LandGISmaps/tree/master/input_layers/Copernicus_vito) . Antartica is not included. 

  To access and visualize maps use: ** [ https://landgis.opengeohub.org ](https://landgis.opengeohub.org) ** 

  If you discover a bug, artifact or inconsistency in the LandGIS maps, or if you have a question please use some of the following channels: 

  *  Technical issues and questions about the code: [ https://github.com/Envirometrix/LandGISmaps/issues ](https://github.com/Envirometrix/LandGISmaps/issues) 
 *  General questions and comments: [ https://disqus.com/home/forums/landgis/ ](https://disqus.com/home/forums/landgis/) 
   All files internally compressed using "COMPRESS=DEFLATE" creation option in GDAL. File naming convention: 

  *  veg = theme: vegetation, 
 *  fapar = Fraction of Absorbed Photosynthetically Active Radiation, 
 *  proba.v.oct = determination method: PROBA-V products, month October, 
 *  d = median value, 
 *  250m = spatial resolution / block support: 250 m, 
 *  s0..0cm = vertical reference: land surface, 
 *  2014..2017 = time reference: from 2014 to 2017, 
 *  v1.0 = version number: 1.0,