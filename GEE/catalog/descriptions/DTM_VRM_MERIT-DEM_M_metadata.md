HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"   GRASS GIS manual: r.vector.ruggedness      [![GRASS logo](grass_logo.png)](index.html)  NAME
----

 ***r.vector.ruggedness*** - Vector Ruggedness Measure KEYWORDS
--------

 SYNOPSIS
--------

 **r.vector.ruggedness**  
 **r.vector.ruggedness --help**  
 **r.vector.ruggedness** [-**p**] **elevation**=*name*[,*name*,...] [**size**=*integer*] **output**=*name*[,*name*,...] [--**overwrite**] [--**help**] [--**verbose**] [--**quiet**] [--**ui**]   ### Flags:

  **-p** Do not run in parallel **--overwrite** Allow output files to overwrite existing files **--help** Print usage summary **--verbose** Verbose module output **--quiet** Quiet module output **--ui** Force launching GUI dialog    ### Parameters:

  **elevation**=*name[,*name*,...]* **[required]** DEM Raster Input Name of input raster map(s) **size**=*integer* Size of neighbourhood Default: *3* **output**=*name[,*name*,...]* **[required]** Vector Ruggedness Index Output Name for output raster map(s)    #### Table of contents

  * [DESCRIPTION](#description)
 * [NOTES](#notes)
 * [EXAMPLE](#example)
 * [REFERENCES](#references)
 * [AUTHOR](#author)
   DESCRIPTION
-----------

 ***r.vector.ruggedness*** represents a measurement of terrain ruggedness based on the methodology conceived by Sappington et al. (2007). The measure is calculated by decomposing slope and aspect into 3-dimensional vectors, and calculating the resultant vector magnitude within a user-specified moving window size, using *r.neighbors*. The user can specify neighborhood size to measure ruggedness across larger landscale scales. Neighborhood operations are performed using a rectangular window shape. NOTES
-----

 This script was adapted from the original Sappington et al. (2007) script. EXAMPLE
-------

  r.vector.ruggedness elevation=srtm wsize=5 output=vrm  REFERENCES
----------

 Sappington, J.M., K.M. Longshore, and D.B. Thomson. 2007. Quantifying Landscape Ruggedness for Animal Habitat Analysis: A case Study Using Bighorn Sheep in the Mojave Desert. Journal of Wildlife Management. 71(5): 1419 -1426. AUTHOR
------

 Steven Pawley *Last changed: $Date$*SOURCE CODE
-----------

 Available at: [r.vector.ruggedness source code](https://github.com/OSGeo/grass-addons/tree/master/grass7/raster/r.vector.ruggedness) ([history](https://github.com/OSGeo/grass-addons/tree/master/grass7/raster/r.vector.ruggedness))

   [Main index](index.html) | [Raster index](https://grass.osgeo.org/grass76/manuals/raster.html) | [Topics index](https://grass.osgeo.org/grass76/manuals/topics.html) | [Keywords index](https://grass.osgeo.org/grass76/manuals/keywords.html) | [Graphical index](https://grass.osgeo.org/grass76/manuals/graphical_index.html) | [Full index](https://grass.osgeo.org/grass76/manuals/full_index.html) 

  © 2003-2019 [GRASS Development Team](http://grass.osgeo.org), GRASS GIS 7.6.2svn Reference Manual