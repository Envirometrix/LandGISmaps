html   Module Slope, Aspect, Curvature / SAGA-GIS Module Library Documentation (v2.1.4)   [![Logo](./icons/logo.png)](http://saga-gis.org/) SAGA-GIS Module Library Documentation (v2.1.4)
==============================================

  [Modules A-Z](a2z.html) [Contents](index.html) [Terrain Analysis - Morphometry](./ta_morphometry.html)    Module Slope, Aspect, Curvature
===============================

 Calculates the local morphometric terrain parameters slope, aspect and if supported by the chosen method also the curvature. Besides tangential curvature also its horizontal and vertical components (i.e. plan and profile curvature) can be calculated.  
  
References:  
  
Maximum Slope  
- Travis, M.R., Elsner, G.H., Iverson, W.D., Johnson, C.G. (1975):  
 'VIEWIT: computation of seen areas, slope, and aspect for land-use planning',  
 USDA F.S. Gen. Tech. Rep. PSW-11/1975, 70p. Berkeley, California, U.S.A.  
  
Maximum Triangle Slope  
- Tarboton, D.G. (1997):  
 'A new method for the determination of flow directions and upslope areas in grid digital elevation models',  
 Water Resources Research, Vol.33, No.2, p.309-319  
  
Least Squares or Best Fitted Plane  
- Horn, B. K. (1981):  
 'Hill shading and the relectance map',  
 Proceedings of the IEEE, v. 69, no. 1, p. 14-47.  
  
- Beasley, D.B., Huggins, L.F. (1982):  
 'ANSWERS: User's manual',  
 U.S. EPA-905/9-82-001, Chicago, IL. 54pp.  
  
- Costa-Cabral, M., Burges, S.J., (1994):  
 'Digital Elevation Model Networks (DEMON): a model of flow over hillslopes for computation of contributing and dispersal areas',  
 Water Resources Research, v. 30, no. 6, p. 1681-1692.  
  
Fit 2.Degree Polynom  
- Evans, I.S. (1979):  
 'An integrated system of terrain analysis and slope mapping',  
 Final report on grant DA-ERO-591-73-G0040. University of Durham, England.  
  
- Bauer, J., Rohdenburg, H., Bork, H.-R. (1985):  
 'Ein Digitales Reliefmodell als Vorraussetzung fuer ein deterministisches Modell der Wasser- und Stoff-Fluesse',  
 Landschaftsgenese und Landschaftsoekologie, H.10, Parameteraufbereitung fuer deterministische Gebiets-Wassermodelle,  
 Grundlagenarbeiten zu Analyse von Agrar-Oekosystemen, (Eds.: Bork, H.-R. / Rohdenburg, H.), p.1-15  
  
- Heerdegen, R.G., Beran, M.A. (1982):  
 'Quantifying source areas through land surface curvature',  
 Journal of Hydrology, Vol.57  
  
- Olaya, V. (2006):  
 'Basic Land-Surface Parameters',  
 in: Hengl, T., Reuter, H.I. [Eds.]: Geomorphometry: Concepts, Software, Applications. Developments in Soil Science, Elsevier, Vol.33, 141-169.  
  
- Zevenbergen, L.W., Thorne, C.R. (1987):  
 'Quantitative analysis of land surface topography',  
 Earth Surface Processes and Landforms, 12: 47-56.  
  
Fit 3.Degree Polynom  
- R.M. Haralick (1983):  
 'Ridge and valley detection on digital images',  
 Computer Vision, Graphics and Image Processing, Vol.22, No.1, p.28-38  
  


  * Author: O.Conrad (c) 2001
 * Specification: grid
 * Menu: Terrain Analysis|Morphometry
  ### Parameters

   NameTypeIdentifierDescriptionConstraints InputElevationGrid (input)ELEVATION-- OutputSlopeGrid (output)SLOPE--  AspectGrid (output)ASPECT--  General Curvature (*)Grid (optional output)C\_GENE--  Profile Curvature (*)Grid (optional output)C\_PROF--  Plan Curvature (*)Grid (optional output)C\_PLAN--  Tangential Curvature (*)Grid (optional output)C\_TANG--  Longitudinal Curvature (*)Grid (optional output)C\_LONGZevenbergen & Thorne (1987) refer to this as profile curvature-  Cross-Sectional Curvature (*)Grid (optional output)C\_CROSZevenbergen & Thorne (1987) refer to this as plan curvature-  Minimal Curvature (*)Grid (optional output)C\_MINI--  Maximal Curvature (*)Grid (optional output)C\_MAXI--  Total Curvature (*)Grid (optional output)C\_TOTA--  Flow Line Curvature (*)Grid (optional output)C\_ROTO-- OptionsMethodChoiceMETHOD-Available Choices:  
[0] maximum slope (Travis et al. 1975)  
[1] maximum triangle slope (Tarboton 1997)  
[2] least squares fitted plane (Horn 1981, Costa-Cabral & Burgess 1996)  
[3] 6 parameter 2nd order polynom (Evans 1979)  
[4] 6 parameter 2nd order polynom (Heerdegen & Beran 1982)  
[5] 6 parameter 2nd order polynom (Bauer, Rohdenburg, Bork 1985)  
[6] 9 parameter 2nd order polynom (Zevenbergen & Thorne 1987)  
[7] 10 parameter 3rd order polynom (Haralick 1983)  
Default: 6  Slope UnitsChoiceUNIT\_SLOPE-Available Choices:  
[0] radians  
[1] degree  
[2] percent  
Default: 0  Aspect UnitsChoiceUNIT\_ASPECT-Available Choices:  
[0] radians  
[1] degree  
Default: 0 (*) optional  ### Command-line

  Usage: **saga\_cmd ta\_morphometry 0** -ELEVATION <str> [-SLOPE <str>] [-ASPECT <str>] [-C\_GENE <str>] [-C\_PROF <str>] [-C\_PLAN <str>] [-C\_TANG <str>] [-C\_LONG <str>] [-C\_CROS <str>] [-C\_MINI <str>] [-C\_MAXI <str>] [-C\_TOTA <str>] [-C\_ROTO <str>] [-METHOD <str>] [-UNIT\_SLOPE <str>] [-UNIT\_ASPECT <str>] -ELEVATION:<str> Elevation Grid (input) -SLOPE:<str> Slope Grid (output) -ASPECT:<str> Aspect Grid (output) -C\_GENE:<str> General Curvature Grid (optional output) -C\_PROF:<str> Profile Curvature Grid (optional output) -C\_PLAN:<str> Plan Curvature Grid (optional output) -C\_TANG:<str> Tangential Curvature Grid (optional output) -C\_LONG:<str> Longitudinal Curvature Grid (optional output) -C\_CROS:<str> Cross-Sectional Curvature Grid (optional output) -C\_MINI:<str> Minimal Curvature Grid (optional output) -C\_MAXI:<str> Maximal Curvature Grid (optional output) -C\_TOTA:<str> Total Curvature Grid (optional output) -C\_ROTO:<str> Flow Line Curvature Grid (optional output) -METHOD:<str> Method Choice Available Choices: [0] maximum slope (Travis et al. 1975) [1] maximum triangle slope (Tarboton 1997) [2] least squares fitted plane (Horn 1981, Costa-Cabral & Burgess 1996) [3] 6 parameter 2nd order polynom (Evans 1979) [4] 6 parameter 2nd order polynom (Heerdegen & Beran 1982) [5] 6 parameter 2nd order polynom (Bauer, Rohdenburg, Bork 1985) [6] 9 parameter 2nd order polynom (Zevenbergen & Thorne 1987) [7] 10 parameter 3rd order polynom (Haralick 1983) Default: 6 -UNIT\_SLOPE:<str> Slope Units Choice Available Choices: [0] radians [1] degree [2] percent Default: 0 -UNIT\_ASPECT:<str> Aspect Units Choice Available Choices: [0] radians [1] degree Default: 0