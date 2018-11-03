<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.2.3-Bonn" hasScaleBasedVisibilityFlag="0" minScale="1e+08" maxScale="0">
  <pipe>
    <rasterrenderer classificationMax="145" classificationMin="115" opacity="1" alphaBand="-1" band="1" type="singlebandpseudocolor">
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
        <colorrampshader colorRampType="INTERPOLATED" clip="0" classificationMode="2">
          <colorramp name="[source]" type="cpt-city">
            <prop k="inverted" v="1"/>
            <prop k="rampType" v="cpt-city"/>
            <prop k="schemeName" v="grass/bcyr"/>
            <prop k="variantName" v=""/>
          </colorramp>
          <item alpha="255" color="#ff0000" value="115" label="115"/>
          <item alpha="255" color="#ffc000" value="122.5" label="122.5"/>
          <item alpha="0" color="#ffffff" value="128" label="128"/>
          <item alpha="255" color="#80ff80" value="130" label="130"/>
          <item alpha="255" color="#00c0ff" value="137.5" label="137.5"/>
          <item alpha="255" color="#0000ff" value="145" label="145"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation saturation="0" colorizeStrength="100" colorizeGreen="128" colorizeOn="0" grayscaleMode="0" colorizeRed="255" colorizeBlue="128"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
