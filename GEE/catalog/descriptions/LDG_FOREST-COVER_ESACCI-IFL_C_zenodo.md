Tree-covered and intact forest landscapes BC1000, 1995, 2000, 2005, 2010, 2013, 2016 at 250 m
==============================================================================================

   Based on the [ UNEP historic forest cover map ](http://www.unep-wcmc.org/resources-and-data/generalised-original-and-current-forest) , ESA land cover time series and [ intact forest landscape (IFL 2000, 2013 and 2016) data ](http://www.intactforests.org/data.ifl.html) . Processing steps are described in detail ** [ here ](https://github.com/Envirometrix/LandGISmaps/tree/master/soil/LDN) ** . Antartica is not included. 

  To access and visualize maps use: ** [ https://landgis.opengeohub.org ](https://landgis.opengeohub.org) ** 

  If you discover a bug, artifact or inconsistency in the LandGIS maps, or if you have a question please use some of the following channels: 

  *  Technical issues and questions about the code: [ https://github.com/Envirometrix/LandGISmaps/issues ](https://github.com/Envirometrix/LandGISmaps/issues) 
 *  General questions and comments: [ https://disqus.com/home/forums/landgis/ ](https://disqus.com/home/forums/landgis/) 
   All files internally compressed using "COMPRESS=DEFLATE" creation option in GDAL. File naming convention: 

  *  ldg = theme: land degradation, 
 *  forest.cover = variable: forest / tree cover, 
 *  esacci.ifl = determination method: combination of ESA land cover and IFL maps, 
 *  c = factor, 
 *  250m = spatial resolution / block support: 250 m, 
 *  s0..0cm = vertical reference: land surface, 
 *  1995 = time reference: year 1995, 
 *  v0.1 = version number: 0.1,