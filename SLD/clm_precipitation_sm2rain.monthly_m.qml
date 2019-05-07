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
    <rasterrenderer opacity="1" band="1" type="singlebandpseudocolor" classificationMin="0" classificationMax="450" alphaBand="-1">
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
            <prop v="ncl/precip_11lev" k="schemeName"/>
            <prop v="" k="variantName"/>
          </colorramp>
          <item color="#ffffff" alpha="255" value="0" label="0"/>
          <item color="#edfac2" alpha="255" value="37.485" label="37.5"/>
          <item color="#cdffcd" alpha="255" value="75.015" label="75"/>
          <item color="#99f0b2" alpha="255" value="112.5" label="112"/>
          <item color="#53bd9f" alpha="255" value="149.985" label="150"/>
          <item color="#32a696" alpha="255" value="187.515" label="188"/>
          <item color="#3296b4" alpha="255" value="225" label="225"/>
          <item color="#0570b0" alpha="255" value="262.485" label="262"/>
          <item color="#05508c" alpha="255" value="300.015" label="300"/>
          <item color="#0a1f96" alpha="255" value="337.5" label="338"/>
          <item color="#2c0246" alpha="255" value="374.985" label="375"/>
          <item color="#6a2c5a" alpha="255" value="412.515" label="413"/>
          <item color="#6a2c5a" alpha="255" value="450" label="450"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeRed="255" colorizeOn="0" saturation="0" colorizeGreen="128" colorizeBlue="128" grayscaleMode="0" colorizeStrength="100"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
