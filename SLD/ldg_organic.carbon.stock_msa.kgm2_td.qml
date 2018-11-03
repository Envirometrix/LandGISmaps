<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" minScale="1e+08" maxScale="0" hasScaleBasedVisibilityFlag="0" version="3.4.0-Madeira">
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
    <rasterrenderer type="singlebandpseudocolor" opacity="1" classificationMax="15" alphaBand="-1" band="1" classificationMin="-15">
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
          <colorramp type="gradient" name="[source]">
            <prop v="208,28,139,255" k="color1"/>
            <prop v="77,172,38,255" k="color2"/>
            <prop v="0" k="discrete"/>
            <prop v="gradient" k="rampType"/>
            <prop v="0.25;241,182,218,255:0.5;247,247,247,255:0.75;184,225,134,255" k="stops"/>
          </colorramp>
          <item label="-15" value="-15" alpha="255" color="#740001"/>
          <item label="-10" value="-10" alpha="255" color="#b80d29"/>
          <item label="-5" value="-5" alpha="255" color="#f15262"/>
          <item label="0" value="0" alpha="0" color="#f7f7f7"/>
          <item label="5" value="5" alpha="255" color="#b8e186"/>
          <item label="10" value="10" alpha="255" color="#4dac26"/>
          <item label="15" value="15" alpha="255" color="#066709"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeGreen="128" grayscaleMode="0" colorizeOn="0" colorizeStrength="100" colorizeRed="255" saturation="0" colorizeBlue="128"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
