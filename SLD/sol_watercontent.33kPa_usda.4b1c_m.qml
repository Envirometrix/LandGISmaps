<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis maxScale="0" styleCategories="AllStyleCategories" version="3.6.0-Noosa" minScale="1e+8" hasScaleBasedVisibilityFlag="0">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <customproperties>
    <property key="WMSBackgroundLayer" value="false"/>
    <property key="WMSPublishDataSourceUrl" value="false"/>
    <property key="embeddedWidgets/count" value="0"/>
    <property key="identify/format" value="Value"/>
  </customproperties>
  <pipe>
    <rasterrenderer alphaBand="-1" classificationMin="0" opacity="1" classificationMax="52.974" band="1" type="singlebandpseudocolor">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2.4</stdDevFactor>
      </minMaxOrigin>
      <rastershader>
        <colorrampshader colorRampType="INTERPOLATED" classificationMode="1" clip="0">
          <colorramp type="cpt-city" name="[source]">
            <prop k="inverted" v="0"/>
            <prop k="rampType" v="cpt-city"/>
            <prop k="schemeName" v="gmt/GMT_drywet"/>
            <prop k="variantName" v=""/>
          </colorramp>
          <item color="#d29642" label="0" value="0" alpha="255"/>
          <item color="#eec764" label="7.12" value="7.11577757717944" alpha="255"/>
          <item color="#b4ee87" label="16.3" value="16.2841237790484" alpha="255"/>
          <item color="#32eeeb" label="25.5" value="25.4579731899221" alpha="255"/>
          <item color="#0c78ee" label="34.6" value="34.6318226007958" alpha="255"/>
          <item color="#2601b7" label="43.8" value="43.8001688026648" alpha="255"/>
          <item color="#083371" label="53" value="52.9740182135385" alpha="255"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation colorizeOn="0" saturation="0" colorizeRed="255" grayscaleMode="0" colorizeBlue="128" colorizeGreen="128" colorizeStrength="100"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
