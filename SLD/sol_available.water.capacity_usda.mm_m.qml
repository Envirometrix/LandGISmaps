<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.6.1-Noosa" hasScaleBasedVisibilityFlag="0" minScale="1e+8" maxScale="0" styleCategories="AllStyleCategories">
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
    <rasterrenderer classificationMin="0" classificationMax="560" opacity="1" type="singlebandpseudocolor" band="1" alphaBand="-1">
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
        <colorrampshader clip="0" colorRampType="INTERPOLATED" classificationMode="1">
          <colorramp type="cpt-city" name="[source]">
            <prop k="inverted" v="0"/>
            <prop k="rampType" v="cpt-city"/>
            <prop k="schemeName" v="gmt/GMT_drywet"/>
            <prop k="variantName" v=""/>
          </colorramp>
          <item value="0" label="0" alpha="255" color="#eede64"/>
          <item value="93.352" label="93.4" alpha="255" color="#eec764"/>
          <item value="186.648" label="187" alpha="255" color="#b4ee87"/>
          <item value="280" label="280" alpha="255" color="#32eeeb"/>
          <item value="373.352" label="373" alpha="255" color="#0c78ee"/>
          <item value="466.648" label="467" alpha="255" color="#2601b7"/>
          <item value="560" label="560" alpha="255" color="#083371"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation saturation="0" colorizeStrength="100" colorizeBlue="128" colorizeOn="0" colorizeRed="255" grayscaleMode="0" colorizeGreen="128"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
