<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis maxScale="0" version="3.2.3-Bonn" minScale="1e+08" hasScaleBasedVisibilityFlag="0">
  <pipe>
    <rasterrenderer alphaBand="-1" classificationMax="380" type="singlebandpseudocolor" band="1" opacity="1" classificationMin="0">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Exact</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <rastershader>
        <colorrampshader clip="0" colorRampType="INTERPOLATED" classificationMode="1">
          <colorramp type="cpt-city" name="[source]">
            <prop v="0" k="inverted"/>
            <prop v="cpt-city" k="rampType"/>
            <prop v="grass/bcyr" k="schemeName"/>
            <prop v="" k="variantName"/>
          </colorramp>
          <item alpha="255" value="0" label="0" color="#ecffbd"/>
          <item alpha="255" value="25" label="25" color="#ffff00"/>
          <item alpha="255" value="90" label="90" color="#3af6ff"/>
          <item alpha="255" value="180" label="180" color="#467aff"/>
          <item alpha="255" value="280" label="280" color="#313eff"/>
          <item alpha="255" value="380" label="380" color="#0008ff"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation colorizeGreen="128" colorizeOn="0" saturation="0" colorizeBlue="128" grayscaleMode="0" colorizeRed="255" colorizeStrength="100"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
