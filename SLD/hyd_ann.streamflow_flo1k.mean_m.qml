<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis maxScale="0" minScale="1e+8" hasScaleBasedVisibilityFlag="0" version="3.8.0-Zanzibar" styleCategories="AllStyleCategories">
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
    <rasterrenderer opacity="1" alphaBand="-1" type="singlebandpseudocolor" classificationMax="5" band="1" classificationMin="0">
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
        <colorrampshader colorRampType="INTERPOLATED" clip="0" classificationMode="1">
          <colorramp name="[source]" type="cpt-city">
            <prop k="inverted" v="0"/>
            <prop k="rampType" v="cpt-city"/>
            <prop k="schemeName" v="cb/seq/YlGnBu_09"/>
            <prop k="variantName" v=""/>
          </colorramp>
          <item label="0" color="#ffffff" value="0" alpha="3"/>
          <item label="0.0125" color="#ffffd9" value="0.0125" alpha="255"/>
          <item label="0.0588" color="#edf8b1" value="0.0588276722" alpha="255"/>
          <item label="0.118" color="#c7e9b4" value="0.1176553444" alpha="255"/>
          <item label="0.176" color="#7fcdbb" value="0.1764830166" alpha="255"/>
          <item label="0.235" color="#41b6c4" value="0.2353106888" alpha="255"/>
          <item label="0.294" color="#1d91c0" value="0.2941913112" alpha="255"/>
          <item label="0.353" color="#225ea8" value="0.3530189834" alpha="255"/>
          <item label="0.412" color="#2e43ba" value="0.4118466556" alpha="255"/>
          <item label="0.471" color="#0e349c" value="0.4706743278" alpha="255"/>
          <item label="0.53" color="#0b297d" value="0.529502" alpha="255"/>
          <item label="1.041" color="#270063" value="1.041" alpha="255"/>
          <item label="5" color="#1b0037" value="5" alpha="255"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeOn="0" saturation="0" colorizeGreen="128" colorizeBlue="128" colorizeRed="255" colorizeStrength="100" grayscaleMode="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
