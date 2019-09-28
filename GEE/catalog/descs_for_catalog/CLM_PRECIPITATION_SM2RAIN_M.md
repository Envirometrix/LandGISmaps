## Monthly precipitation in mm at 1 km resolution based on SM2RAIN-ASCAT 2007-2018, IMERGE, CHELSA Climate and WorldClim


   Monthly precipitation in mm at 1 km resolution based on SM2RAIN-ASCAT 2007-2018 ( [ https://doi.org/10.5281/zenodo.2615278 ](https://doi.org/10.5281/zenodo.2615278) ). [ Downscaled to 1 km resolution using gdalwarp ](https://github.com/Envirometrix/LandGISmaps/tree/master/input_layers/clim1km) (cubic splines) and an average between WorldClim ( [ http://biogeo.ucdavis.edu/data/worldclim/v2.0/ ](http://biogeo.ucdavis.edu/data/worldclim/v2.0/) ), CHELSA Climate ( [ https://www.wsl.ch/lud/chelsa/data/climatologies/prec/ ](https://www.wsl.ch/lud/chelsa/data/climatologies/prec/) ) and IMERGE monthly product (ftp://jsimpson.pps.eosdis.nasa.gov/NRTPUB/imerg/gis/ see files e.g. "3B-MO-L.GIS.IMERG.20180601.V05B.tif"). 3x higher weight is given to the SM2RAIN-ASCAT data since it assumed to be more accurate. Processing steps are available [ **here** ](https://github.com/Envirometrix/LandGISmaps/tree/master/input_layers/clim1km) . Antartica is not included. 

  To access and visualize maps use: [ **https://openlandmap.org** ](https://openlandmap.org) 

  If you discover a bug, artifact or inconsistency in the LandGIS maps, or if you have a question please use some of the following channels: 

  *  Technical issues and questions about the code: [ https://github.com/Envirometrix/LandGISmaps/issues ](https://github.com/Envirometrix/LandGISmaps/issues) 
 *  General questions and comments: [ https://disqus.com/home/forums/landgis/ ](https://disqus.com/home/forums/landgis/) 
   All files internally compressed using "COMPRESS=DEFLATE" creation option in GDAL. File naming convention: 

  *  clm = theme: climate, 
 *  precipitation = variable: precipitation, 
 *  sm2rain.oct = determination method: SM2RAIN-ASCAT long-term average values for October, 
 *  m = mean value, 
 *  1km = spatial resolution / block support: 1 km, 
 *  s0..0cm = vertical reference: land surface, 
 *  2007..2018 = time reference: from 2007 to 2018, 
 *  v0.2 = version number: 0.2,