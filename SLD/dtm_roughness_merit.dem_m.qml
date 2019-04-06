<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" maxScale="0" version="3.4.4-Madeira" hasScaleBasedVisibilityFlag="0" minScale="1e+8">
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
    <rasterrenderer band="1" alphaBand="-1" type="singlebandpseudocolor" opacity="1" classificationMin="0" classificationMax="2000">
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
        <colorrampshader colorRampType="INTERPOLATED" classificationMode="2" clip="0">
          <colorramp type="gradient" name="[source]">
            <prop k="color1" v="43,131,186,255"/>
            <prop k="color2" v="215,25,28,255"/>
            <prop k="discrete" v="0"/>
            <prop k="rampType" v="gradient"/>
            <prop k="stops" v="0.001;230,245,228,255:0.414933;255,187,131,255"/>
          </colorramp>
          <item value="0" label="0" color="#2b83ba" alpha="255"/>
          <item value="200" label="200" color="#ece8cd" alpha="255"/>
          <item value="400" label="400" color="#f2d9b6" alpha="255"/>
          <item value="600" label="600" color="#f9cb9e" alpha="255"/>
          <item value="800" label="800" color="#ffbd87" alpha="255"/>
          <item value="1000" label="1000" color="#faa474" alpha="255"/>
          <item value="1200" label="1200" color="#f38863" alpha="255"/>
          <item value="1400" label="1400" color="#ec6c51" alpha="255"/>
          <item value="1600" label="1600" color="#e5503f" alpha="255"/>
          <item value="1800" label="1800" color="#de342d" alpha="255"/>
          <item value="2000" label="2000" color="#d7191c" alpha="255"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation saturation="0" colorizeStrength="100" colorizeRed="255" colorizeBlue="128" grayscaleMode="0" colorizeGreen="128" colorizeOn="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
