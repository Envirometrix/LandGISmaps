<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis hasScaleBasedVisibilityFlag="0" version="3.2.3-Bonn" minScale="1e+08" maxScale="0">
  <pipe>
    <rasterrenderer classificationMax="120" classificationMin="0" type="singlebandpseudocolor" opacity="1" alphaBand="-1" band="1">
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
          <colorramp name="[source]" type="cpt-city">
            <prop k="inverted" v="0"/>
            <prop k="rampType" v="cpt-city"/>
            <prop k="schemeName" v="cb/seq/YlGn_09"/>
            <prop k="variantName" v=""/>
          </colorramp>
          <item value="0" label="0" color="#ffffa0" alpha="255"/>
          <item value="1" label="0.5" color="#f7fcb9" alpha="255"/>
          <item value="2" label="1" color="#d9f0a3" alpha="255"/>
          <item value="4" label="2" color="#addd8e" alpha="255"/>
          <item value="6" label="3" color="#78c679" alpha="255"/>
          <item value="10" label="5" color="#41ab5d" alpha="255"/>
          <item value="15" label="7.5" color="#238443" alpha="255"/>
          <item value="25" label="12.5" color="#005b29" alpha="255"/>
          <item value="40" label="20" color="#004b29" alpha="255"/>
          <item value="60" label="30" color="#012b13" alpha="255"/>
          <item value="120" label="60" color="#00120b" alpha="255"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation colorizeOn="0" colorizeStrength="100" colorizeRed="255" colorizeBlue="128" saturation="0" colorizeGreen="128" grayscaleMode="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
