HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"   GRASS GIS manual: r.convergence      [![GRASS logo](grass_logo.png)](index.html)  NAME
----

 ***r.convergence*** - Calculate convergence index. KEYWORDS
--------

 [raster](https://grass.osgeo.org/grass76/manuals/raster.html), [terrain](https://grass.osgeo.org/grass76/manuals/topic_terrain.html) SYNOPSIS
--------

 **r.convergence**  
 **r.convergence --help**  
 **r.convergence** [-**cs**] **input**=*name* **output**=*name* **window**=*integer* **weights**=*string* [--**overwrite**] [--**help**] [--**verbose**] [--**quiet**] [--**ui**]   ### Flags:

  **-c** Use circular window (default: square) **-s** Add slope convergence (radically slow down calculation time) **--overwrite** Allow output files to overwrite existing files **--help** Print usage summary **--verbose** Verbose module output **--quiet** Quiet module output **--ui** Force launching GUI dialog    ### Parameters:

  **input**=*name* **[required]** Digital elevation model map **output**=*name* **[required]** Output convergence index map **window**=*integer* **[required]** Window size Default: *3* **weights**=*string* **[required]** Method for reducing the impact of the cell due to distance Options: *standard, inverse, power, square, gentle* Default: *standard*    #### Table of contents

  * [OPTIONS](#options)
 * [DESCRIPTION](#description) 
	 + [How convergence index is calculated (3 x 3 window):](#how-convergence-index-is-calculated-(3-x-3-window):)
	 
 * [SEE ALSO](#see-also)
 * [REFERENCES](#references)
 * [AUTHOR](#author)
   OPTIONS
-------

  **-s** Increase convergence if slope value is high. Slope parameter radically slow down computation time, especially if window parameter is high. If slope is used addational modifier is used according to formula: sin(current)*sin(target) + cos(current)*cos(target). if slope of current and target cells are equal. The modifier is 1. If not, the modifier is applied with formula: acos(cos(convergence) * modifier)  **-c** use circular window instead of suqare (default) **input** Digital elevation model. Data can be of any type and any projection. To calculate relief convergnece, r.convergence uses real distance which is recalculated into cell distance, according formula:   
distance\_between\_current\_cell\_and\_traget\_cell/distance\_between\_current\_cell\_and\_nearest\_neighbour\_cell. It is important if convergence is calculated for large areas in LatLong projecton.  **weights** Parameter describing the reduction of the impact of the cell due to its distance, where distance in cells:  * **standard:**no decay * **inverse:**distance modifier is calculated as 1/x * **power:**distance modifier is calculated as 1/(x*x) * **power:**distance modifier is calculated as 1/(x*x) * **gentle:**distance modifier is calculated as 1/((1-x)/(1+x)) 




 **window** window size. Must be odd. For now there is no limits in window size. r.convergence uses window size instead of classical radius for compatibility with other GRASS programs. **output** Map of convergence index. The values ranges from -100 (max divergent, real peaks and ridges) by 0 (planar areas) to 100 (max convergent, real pits and channels). Classical convergence index presented with degrees (-90 to 90) DESCRIPTION
-----------

 ### How convergence index is calculated (3 x 3 window):

  ![](conv.png)  
  Convergence index is a terrain parameter which show the structure of the relief as a set of convergent areas (channels) and divergent areas (ridges). It represents the agreement of aspect direction of surrounding cells with the teoretical matrix direction. Convergence index is mean (or weighted mean if weights are used) aspect difference between real aspect and teoretical maximum divergent direction matrix representing ideal peak (see figure) minus 90 degres. So if there is maximum agreement with divergent matrix the convergence index is (0 - 90) * 10/9 = -100. If there is ideal sink (maximum convergence) the convergence index is (180 -90) * 10/9 = 100. Slope and aspect ere calculated internaly with the same formula as in r.slope.aspect Convergence index is very useful for analysis of lineamets especially represented by rigdes or chanell systems as well as valley recognition tool. SEE ALSO
--------

 * [r.slope.aspect](https://grass.osgeo.org/grass76/manuals/r.slope.aspect.html), [r.param.scale](https://grass.osgeo.org/grass76/manuals/r.param.scale.html), [r.neighbour](https://grass.osgeo.org/grass76/manuals/r.neighbour.html), * REFERENCES
----------

  Claps, P., Fiorentino, M., Oliveto, G., (1994), *Informational entropy of fractal river networks*, Journal of Hydrology, 187(1-2), 145-156 .

  Bauer J., Rohdenburg H., Bork H.-R., (1985), Ein Digitales Reliefmodell als Vorraussetzung fuer ein deterministisches Modell der Wasser- und Stoff-Fluesse, *IN: Bork, H.-R., Rohdenburg, H., Landschaftsgenese und Landschaftsoekologie, Parameteraufbereitung fuer deterministische Gebiets-Wassermodelle, Grundlagenarbeiten zu Analyse von Agrar-Oekosystemen*, 1-15.  Böhner J., Blaschke T., Montanarella, L. (eds.) (2008). SAGA Seconds Out. Hamburger Beiträge zur Physischen Geographie und Landschaftsökologie, 19: 113 s.

 AUTHOR
------

 Jarek Jasiewicz  *Last changed: $Date$*SOURCE CODE
-----------

 Available at: [r.convergence source code](https://github.com/OSGeo/grass-addons/tree/master/grass7/raster/r.convergence) ([history](https://github.com/OSGeo/grass-addons/tree/master/grass7/raster/r.convergence))

   [Main index](index.html) | [Raster index](https://grass.osgeo.org/grass76/manuals/raster.html) | [Topics index](https://grass.osgeo.org/grass76/manuals/topics.html) | [Keywords index](https://grass.osgeo.org/grass76/manuals/keywords.html) | [Graphical index](https://grass.osgeo.org/grass76/manuals/graphical_index.html) | [Full index](https://grass.osgeo.org/grass76/manuals/full_index.html) 

  © 2003-2019 [GRASS Development Team](http://grass.osgeo.org), GRASS GIS 7.6.2svn Reference Manual