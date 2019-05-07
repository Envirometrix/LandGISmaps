<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" version="3.4.4-Madeira" minScale="1e+08" hasScaleBasedVisibilityFlag="0" maxScale="0">
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
    <rasterrenderer opacity="1" band="1" type="singlebandpseudocolor" classificationMin="0" classificationMax="120" alphaBand="-1">
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
        <colorrampshader colorRampType="INTERPOLATED" classificationMode="1" clip="0">
          <colorramp name="[source]" type="cpt-city">
            <prop v="0" k="inverted"/>
            <prop v="cpt-city" k="rampType"/>
            <prop v="grass/bcyr" k="schemeName"/>
            <prop v="" k="variantName"/>
          </colorramp>
          <item color="#ffffff" alpha="255" value="0" label="0"/>
          <item color="#8383ff" alpha="255" value="1" label="1"/>
          <item color="#00ffff" alpha="255" value="39.996" label="40"/>
          <item color="#ffff00" alpha="255" value="80.004" label="80"/>
          <item color="#ff0000" alpha="255" value="120" label="120"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeRed="255" colorizeOn="0" saturation="0" colorizeGreen="128" colorizeBlue="128" grayscaleMode="0" colorizeStrength="100"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
