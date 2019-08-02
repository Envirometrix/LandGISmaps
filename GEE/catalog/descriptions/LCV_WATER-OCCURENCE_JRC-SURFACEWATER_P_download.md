html    Global Surface Water - Data Access     body { padding-left: 5px; padding-right: 10px; overflow-x: hidden; font-family: Calibri,Candara,Segoe,Segoe UI,Optima,Arial,sans-serif; } h1, h2, h3, h4, h5 { color: #2e74b5; } h5 { font-size: 15px; font-style: italic; } .tileDownloadBoundsTitle { padding-bottom: 5px; } .logoContainer { padding-bottom: 160px; } .jrcLogoBtmFull { background: #0065a2; width: 98%; height: 61px; position: absolute; margin-top: 95px; padding-right: 10px; } .jrcLogoGroup { position: absolute; font-size: 25px; top: 71px; left: 235px; color: #0065a2; } .jrcLogoPageTitle { color: white; font-size: 25px; margin-left: 220px; margin-top: 16px; } .mapTileDownloadContainer { width: 685px; height: 267px; display: block; position: relative; } .mapTileDownloadBaseLayer { position: absolute; left:0; right:0; } .box { width: 100%;height: 80px; position: relative; border: 1px solid #BBB; background: #dff0faad;margin-top: 5px; } .ribbon { position: absolute; left: -5px; top: -5px; z-index: 1; overflow: hidden; width: 75px; height: 75px; text-align: right; } .ribbon span { font-size: 10px; font-weight: bold; color: #FFF; text-transform: uppercase; text-align: center; line-height: 20px; transform: rotate(-45deg); -webkit-transform: rotate(-45deg); width: 100px; display: block; background: #79A70A; background: linear-gradient(#F70505 0%, #8F0808 100%); box-shadow: 0 3px 10px -5px rgba(0, 0, 0, 1); position: absolute; top: 19px; left: -21px; } .ribbon span::before { content: ""; position: absolute; left: 0px; top: 100%; z-index: -1; border-left: 3px solid #8F0808; border-right: 3px solid transparent; border-bottom: 3px solid transparent; border-top: 3px solid #8F0808; } .ribbon span::after { content: ""; position: absolute; right: 0px; top: 100%; z-index: -1; border-left: 3px solid transparent; border-right: 3px solid #8F0808; border-bottom: 3px solid transparent; border-top: 3px solid #8F0808; }    var BASE\_URL = 'https://storage.googleapis.com/global-surface-water/downloads2/'; var FILES = ['occurrence/occurrence', 'change/change', 'seasonality/seasonality', 'recurrence/recurrence', 'transitions/transitions', 'extent/extent']; //var FILES = ['occurrence/occurrence', 'change/change', 'seasonality/seasonality', 'recurrence/recurrence','extent/extent']; function set\_paths(x, y) { var lat = Math.abs(y) + ((y < 0) ? 'S' : 'N'); var lon = Math.abs(x) + ((x < 0) ? 'W' : 'E'); var lines = ['<p>', '<div class="tileDownloadBoundsTitle">Granule with top-left corner at ' + lon + ', ' + lat + ':</div>']; for (var i = 0 ; i < FILES.length; ++i) { var url = [BASE\_URL, FILES[i], '\_', lon, '\_', lat,'\_v1\_1.tif'].join(''); var dataset\_name = FILES[i].split("/")[0]; if (dataset\_name == "seasonality") { dataset\_name = "Seasonality 2018"; } if (dataset\_name == "extent") { dataset\_name = "Maximum extent"; } lines.push('<div class="url"><b>' + dataset\_name.charAt(0).toUpperCase() + dataset\_name.slice(1) + ": " + '</b><a href="' + url + '">' + url + '</a></div>'); } lines.push('</p>'); document.getElementById("tilepaths").innerHTML = lines.join(''); }; $(function() { $(".tile").on("click", function() { $(".tile").removeClass("selected"); $(this).addClass("selected"); }); });   (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){ (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o), m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m) })(window,document,'script','https://www.google-analytics.com/analytics.js','ga'); ga('create', 'UA-88527603-1', 'auto'); ga('send', 'pageview');    [](http://ec.europa.eu/)Joint Research CentreGlobal Surface Water - Data Access  NEW LAYERS The new dataset 1984-2018 is available to download
==================================================

  License
-------

  All data here is produced under the Copernicus Programme and is provided free of charge, without restriction of use. For the full license information see the [Copernicus Regulation](http://www.copernicus.eu/main/data-access/). 

  Publications, models and data products that make use of these datasets must include proper acknowledgement, including citing datasets and the journal article as in the following citation. 

 Citation
--------

  Jean-Francois Pekel, Andrew Cottam, Noel Gorelick, Alan S. Belward, High-resolution mapping of global surface water and its long-term changes. Nature 540, 418-422 (2016). (doi:10.1038/nature20584) 

  If you are using the data as a layer in a published map, please include the following attribution text: 'Source: EC JRC/Google' 

 Data Users Guide
----------------

  For a description of all of the datasets and details on how to use the data please see the [Data Users Guide](https://storage.cloud.google.com/global-surface-water/downloads_ancillary/DataUsersGuidev2018.pdf). 

 Delivery Mechanisms
-------------------

  All of the datasets that comprise the Global Surface Water 1984-2018 are being made freely available using the following delivery mechanisms: Global Surface Water Explorer, Data Download, Google Earth Engine and Web Map Services. These are described in the following sections. 

 ### Global Surface Water Explorer

  The Global Surface Water Explorer is a simple web-mapping tool that shows all of the water datasets and allows users to navigate the globe visualizing the water datasets without installing any software. It also allows users to view the complete history of water detections over the 35-year period by clicking on the map. The tool is intended as a data viewer and does not provide any analytical features - if you would like to do your own analysis on the data then access the data using Data Download or Google Earth Engine. [Explore the map](https://global-surface-water.appspot.com/map). 

 ### Data Download

  Currently all of the mapped datasets are available to download (i.e. occurrence, change, seasonality, recurrence, transitions and maximum extent). The water history datasets and metadata datasets will be made available in the near future. 

 #### Download process

 ##### Individual 10°x10° files

  The Global Surface Water data are available to download in tiles 10°x10° from the map shown below. Click on the tile to show a list of the available datasets. Each one of these datasets is a hyperlink to the *.tif file. 

  ![](gsw/images/water-occurrence-map.png)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ##### Full dataset

  The full global surface water datasets can be downloaded by using [this Python 2 script](https://storage.cloud.google.com/global-surface-water/downloads_ancillary/downloadWaterDatasets2018.zip) or using [this Python 3 script](/gsw/downloadWaterData_PythonV3.py) . The zip file contains the Python script and a set of instructions for using it. 

 #### Supporting files

 ##### Symbology

  Each of the downloadable files contains a colormap which will display the files in desktop GIS tools (such as QGIS or ArcGIS) using the symbology that has been used in the Global Surface Water Explorer. However, these colormaps do not contain the labels for the values. These can be added to the files by using the following symbology files. For instructions on how to use these files see the 'Using Symbology Files' section of the [Data Users Guide](https://storage.cloud.google.com/global-surface-water/downloads_ancillary/DataUsersGuidev2018.pdf). 

  DatasetQGISArcGIS Occurrence[occurrence.qml](https://storage.googleapis.com/global-surface-water/downloads_ancillary/occurrence.qml)[occurrence.tif.lyr](https://storage.googleapis.com/global-surface-water/downloads_ancillary/occurrence.tif.lyr) Occurrence change intensity[change.qml](https://storage.googleapis.com/global-surface-water/downloads_ancillary/change.qml)[change.tif.lyr](https://storage.googleapis.com/global-surface-water/downloads_ancillary/change.tif.lyr) Seasonality[seasonality.qml](https://storage.googleapis.com/global-surface-water/downloads_ancillary/seasonality.qml)[seasonality.tif.lyr](https://storage.googleapis.com/global-surface-water/downloads_ancillary/seasonality.tif.lyr) Recurrence[recurrence.qml](https://storage.googleapis.com/global-surface-water/downloads_ancillary/recurrence.qml)[recurrence.tif.lyr](https://storage.googleapis.com/global-surface-water/downloads_ancillary/recurrence.tif.lyr) Transitions[transitions.qml](https://storage.googleapis.com/global-surface-water/downloads_ancillary/transitions.qml)[transitions.tif.lyr](https://storage.googleapis.com/global-surface-water/downloads_ancillary/transitions.tif.lyr) Maximum water extent[extent.qml](https://storage.googleapis.com/global-surface-water/downloads_ancillary/extent.qml)[extent.tif.lyr](https://storage.googleapis.com/global-surface-water/downloads_ancillary/extent.tif.lyr)  There are also symbology files where the above palettes are unsuitable for users with deuteranopia colour-blindness:

  DatasetQGISArcGIS Occurrence change intensity[change\_deuteranopia.qml](https://storage.googleapis.com/global-surface-water/downloads_ancillary/change_deuteranopia.qml)[change\_deuteranopia.tif.lyr](https://storage.googleapis.com/global-surface-water/downloads_ancillary/change_deuteranopia.tif.lyr) Transitions[transitions\_deuteranopia.qml](https://storage.googleapis.com/global-surface-water/downloads_ancillary/transitions_deuteranopia.qml)[transitions\_deuteranopia.tif.lyr](https://storage.googleapis.com/global-surface-water/downloads_ancillary/transitions_deuteranopia.tif.lyr)  There are no symbology files for the monthly or the yearly water history as files are encoded and must be decoded before they can be mapped.

 ##### Metadata

 The downloadable files do not contain any metadata information and so it is provided here for each of the datasets. You may need to right click and Download Linked file.

  DatasetISO 19139 Metadata file Occurrence[occurrence.xml](https://storage.cloud.google.com/global-surface-water/downloads_ancillary/occurrence2018.xml) Occurrence change intensity[change.xml](https://storage.cloud.google.com/global-surface-water/downloads_ancillary/change2018.xml) Seasonality[seasonality.xml](https://storage.cloud.google.com/global-surface-water/downloads_ancillary/seasonality2018.xml) Recurrence[recurrence.xml](https://storage.cloud.google.com/global-surface-water/downloads_ancillary/recurrence2018.xml) Transitions[transitions.xml](https://storage.cloud.google.com/global-surface-water/downloads_ancillary/transitions2018.xml) Maximum water extent[extent.xml](https://storage.cloud.google.com/global-surface-water/downloads_ancillary/extent2018.xml)  ### Google Earth Engine

 Tutorials for using the Global Surface Water Dataset in Google Earth Engine are [available here](https://developers.google.com/earth-engine/tutorial_global_surface_water_01).

 #### Asset ids

 The data can also be accessed and used in the Google Earth Engine platform - for more information see [here](https://earthengine.google.com/). The following asset ids are used in Google Earth Engine:

  DatasetAsset ID 1984-2015New Asset ID 1984-2018 (soon available) Map layersJRC/GSW1\_0/GlobalSurfaceWaterJRC/GSW1\_1/GlobalSurfaceWater Yearly SeasonalityJRC/GSW1\_0/YearlyHistoryJRC/GSW1\_1/YearlyHistory Monthly HistoryJRC/GSW1\_0/MonthlyHistoryJRC/GSW1\_1/MonthlyHistory Monthly RecurrenceJRC/GSW1\_0/MonthlyRecurrenceJRC/GSW1\_1/MonthlyRecurrence MetadataJRC/GSW1\_0/MetadataJRC/GSW1\_1/Metadata  ### Web Map Services

 The Global Surface Water data can also be used within other websites or GIS clients by using what are called 'Web Map Services'. These services provide a direct link to the cached images that are used in the Global Surface Water Explorer and are the best option if you simply want to map the data and produce cartographic products. They are not suitable for analysis as the data are represented only as RGB images.

 #### Desktop GIS

  * In ArcGIS for Desktop:
 * In the ArcCatalog Window, click on GIS Servers and then double click on Add WMTS Servers
 * In the URL box, enter: https://storage.googleapis.com/global-surface-water/downloads\_ancillary/WMTS\_Global\_Surface\_WaterV2.xml and click OK
 * Expand the 'Global Surface Water on storage.googleapis.com' item and drag any of the layers onto the map
   * In QGIS:
 * In the Manage Layers toolbar, click on Add WMS/WMTS Layer
 * Click New and enter a name(Global Surface Water) and URL (https://storage.googleapis.com/global-surface-water/downloads\_ancillary/WMTS\_Global\_Surface\_WaterV2.xml)
 * Click OK and click Connect - select a layer to add to the map
  #### Websites

 The Web Map Services can also be used within websites using any Javascript Mapping API that supports tiled layer types. The examples below show you how to create and add the transitions layer in Leaflet v1.0 and then ArcGIS Javascript API v3.18. The layer type can be one of: transitions, occurrence, change, seasonality, recurrence or extent.

 **Leaflet:**   
  var transitions = new L.tileLayer("https://storage.googleapis.com/global-surface-water/tiles2018/transitions/{z}/{x}/{y}.png", { format: "image/png", maxZoom: 13, errorTileUrl : "https://storage.googleapis.com/global-surface-water/downloads\_ancillary/blank.png", attribution: "2016 EC JRC/Google" }); map.addLayer(transitions);  **ArcGIS Javascript API:**   
  var transitions = new WebTiledLayer("https://storage.googleapis.com/global-surface-water/tiles2018/transitions/{level}/{col}/{row}.png", { "copyright" : '2016 EC JRC/Google' }); map.addLayer(transitions);  #### ArcGIS Online

 The Web Map Services are available in the [ESRI ArcGIS Online platform](http://www.arcgis.com/home/item.html?id=5d65be95ccc341d587896a81794021bf) as a set of WMTS layers. To see a list of the datasets, search for 'GSW'.

 Contact
-------

 If you have any feedback on the Global Surface Water data please contact: [jrc-surfacewater@ec.europa.eu](mailto:jrc-surfacewater@ec.europa.eu)