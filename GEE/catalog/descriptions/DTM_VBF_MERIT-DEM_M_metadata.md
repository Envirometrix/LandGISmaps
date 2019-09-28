html   Module Multiresolution Index of Valley Bottom Flatness (MRVBF) / SAGA-GIS Module Library Documentation (v2.1.4)   [![Logo](./icons/logo.png)](http://saga-gis.org/) SAGA-GIS Module Library Documentation (v2.1.4)
==============================================

  [Modules A-Z](a2z.html) [Contents](index.html) [Terrain Analysis - Morphometry](./ta_morphometry.html)    Module Multiresolution Index of Valley Bottom Flatness (MRVBF)
==============================================================

 Calculation of the 'multiresolution index of valley bottom flatness' (MRVBF) and the complementary 'multiresolution index of the ridge top flatness' (MRRTF).   
  
References:  
- Gallant, J.C., Dowling, T.I. (2003): 'A multiresolution index of valley bottom flatness for mapping depositional areas', Water Resources Research, 39/12:1347-1359  


  * Author: (c) 2006 by O.Conrad
 * Specification: grid
 * Menu: Terrain Analysis|Morphometry
  ### Parameters

   NameTypeIdentifierDescriptionConstraints InputElevationGrid (input)DEM-- OutputMRVBFGrid (output)MRVBF--  MRRTFGrid (output)MRRTF-- OptionsInitial Threshold for SlopeFloating pointT\_SLOPE-Minimum: 0.000000  
Maximum: 100.000000  
Default: 16.000000  Threshold for Elevation Percentile (Lowness)Floating pointT\_PCTL\_V-Minimum: 0.000000  
Maximum: 1.000000  
Default: 0.400000  Threshold for Elevation Percentile (Upness)Floating pointT\_PCTL\_R-Minimum: 0.000000  
Maximum: 1.000000  
Default: 0.350000  Shape Parameter for SlopeFloating pointP\_SLOPE-Default: 4.000000  Shape Parameter for Elevation PercentileFloating pointP\_PCTL-Default: 3.000000  Update ViewsBooleanUPDATE-Default: 1  ClassifyBooleanCLASSIFY-Default: 0  Maximum Resolution (Percentage)Floating pointMAX\_RESMaximum resolution as percentage of the diameter of the DEM.Minimum: 0.000000  
Maximum: 100.000000  
Default: 100.000000  ### Command-line

  Usage: **saga\_cmd ta\_morphometry 8** -DEM <str> [-MRVBF <str>] [-MRRTF <str>] [-T\_SLOPE <str>] [-T\_PCTL\_V <str>] [-T\_PCTL\_R <str>] [-P\_SLOPE <str>] [-P\_PCTL <str>] [-UPDATE <str>] [-CLASSIFY <str>] [-MAX\_RES <str>] -DEM:<str> Elevation Grid (input) -MRVBF:<str> MRVBF Grid (output) -MRRTF:<str> MRRTF Grid (output) -T\_SLOPE:<str> Initial Threshold for Slope Floating point Minimum: 0.000000 Maximum: 100.000000 Default: 16.000000 -T\_PCTL\_V:<str> Threshold for Elevation Percentile (Lowness) Floating point Minimum: 0.000000 Maximum: 1.000000 Default: 0.400000 -T\_PCTL\_R:<str> Threshold for Elevation Percentile (Upness) Floating point Minimum: 0.000000 Maximum: 1.000000 Default: 0.350000 -P\_SLOPE:<str> Shape Parameter for Slope Floating point Default: 4.000000 -P\_PCTL:<str> Shape Parameter for Elevation Percentile Floating point Default: 3.000000 -UPDATE:<str> Update Views Boolean Default: 1 -CLASSIFY:<str> Classify Boolean Default: 0 -MAX\_RES:<str> Maximum Resolution (Percentage) Floating point Minimum: 0.000000 Maximum: 100.000000 Default: 100.000000