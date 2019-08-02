Global DEM derivatives at 250 m, 1 km and 2 km based on the MERIT DEM
======================================================================

   Layers include: various DEM derivatives computed using SAGA GIS at 250 m and using MERIT DEM (Yamazaki et al., 2017) as input. Antartica is not included. MERIT DEM was first reprojected to 6 global tiles based on the Equi7 grid system (Bauer-Marschallinger et al. 2014) and then these were used to derive all DEM derivatives. To access original DEM tiles please refer to MERIT DEM [ download page ](http://hydro.iis.u-tokyo.ac.jp/~yamadai/MERIT_DEM/) . 

  To access and visualize maps use: ** [ https://landgis.opengeohub.org ](https://landgis.opengeohub.org) ** 

  If you discover a bug, artifact or inconsistency in the LandGIS maps, or if you have a question please use some of the following channels: 

  *  Technical issues and questions about the code: [ https://github.com/Envirometrix/LandGISmaps/issues ](https://github.com/Envirometrix/LandGISmaps/issues) 
 *  General questions and comments: [ https://disqus.com/home/forums/landgis/ ](https://disqus.com/home/forums/landgis/) 
   All files internally compressed using "COMPRESS=DEFLATE" creation option in GDAL. File naming convention: 

  *  dtm = theme: digital terrain models, 
 *  twi = variable: SAGA GIS Topographic Wetness Index, 
 *  merit.dem = determination method: MERIT DEM, 
 *  m = mean value, 
 *  1km = spatial resolution / block support: 1 km, 
 *  s0..0cm = vertical reference: land surface, 
 *  2017 = time reference: year 2017, 
 *  v1.0 = version number: 1.0,