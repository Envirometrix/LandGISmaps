<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.4.0-Madeira" minScale="1e+08" hasScaleBasedVisibilityFlag="0" maxScale="0" styleCategories="AllStyleCategories">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <customproperties>
    <property value="false" key="WMSBackgroundLayer"/>
    <property value="false" key="WMSPublishDataSourceUrl"/>
    <property value="0" key="embeddedWidgets/count"/>
    <property value="Value" key="identify/format"/>
  </customproperties>
  <pipe>
    <rasterrenderer classificationMax="65" type="singlebandpseudocolor" classificationMin="0" band="1" opacity="1" alphaBand="-1">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <rastershader>
        <colorrampshader classificationMode="1" clip="0" colorRampType="INTERPOLATED">
          <colorramp type="gradient" name="[source]">
            <prop k="color1" v="255,245,240,255"/>
            <prop k="color2" v="103,0,13,255"/>
            <prop k="discrete" v="0"/>
            <prop k="rampType" v="gradient"/>
            <prop k="stops" v="0.13;254,224,210,255:0.26;252,187,161,255:0.39;252,146,114,255:0.52;251,106,74,255:0.65;239,59,44,255:0.78;203,24,29,255:0.9;165,15,21,255"/>
          </colorramp>
          <item alpha="255" label="0" value="0" color="#fffc93"/>
          <item alpha="255" label="2" value="2" color="#fee5ac"/>
          <item alpha="255" label="4" value="4" color="#fcbba1"/>
          <item alpha="255" label="13.7" value="7" color="#fc9272"/>
          <item alpha="255" label="12" value="12" color="#fb6a4a"/>
          <item alpha="255" label="22.8" value="20" color="#ef3b2c"/>
          <item alpha="255" label="28" value="28" color="#cb181d"/>
          <item alpha="255" label="35" value="35" color="#a50f15"/>
          <item alpha="255" label="45" value="45" color="#67000d"/>
          <item alpha="255" label="65" value="65" color="#360000"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation saturation="0" colorizeGreen="128" colorizeStrength="100" colorizeRed="255" colorizeBlue="128" colorizeOn="0" grayscaleMode="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
