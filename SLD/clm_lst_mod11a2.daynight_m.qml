<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.2.3-Bonn" hasScaleBasedVisibilityFlag="0" minScale="1e+08" maxScale="0">
  <pipe>
    <rasterrenderer classificationMax="1336.09" classificationMin="-40.5137" opacity="1" alphaBand="-1" band="1" type="singlebandpseudocolor">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>StdDev</limits>
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
            <prop k="schemeName" v="grass/bcyr"/>
            <prop k="variantName" v=""/>
          </colorramp>
          <item alpha="255" color="#0000ff" value="-40.5137" label="-40.51"/>
          <item alpha="255" color="#00ffff" value="418.30831321" label="418.3"/>
          <item alpha="255" color="#ffff00" value="877.26798679" label="877.3"/>
          <item alpha="255" color="#ff0000" value="1336.09" label="1336"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation saturation="0" colorizeStrength="100" colorizeGreen="128" colorizeOn="0" grayscaleMode="0" colorizeRed="255" colorizeBlue="128"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
