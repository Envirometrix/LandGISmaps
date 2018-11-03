<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.2.3-Bonn" hasScaleBasedVisibilityFlag="0" minScale="1e+08" maxScale="0">
  <pipe>
    <rasterrenderer classificationMax="7" classificationMin="1" opacity="1" alphaBand="-1" band="1" type="singlebandpseudocolor">
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
          <colorramp name="[source]" type="random">
            <prop k="count" v="7"/>
            <prop k="hueMax" v="359"/>
            <prop k="hueMin" v="0"/>
            <prop k="rampType" v="random"/>
            <prop k="satMax" v="240"/>
            <prop k="satMin" v="100"/>
            <prop k="valMax" v="240"/>
            <prop k="valMin" v="200"/>
          </colorramp>
          <item alpha="255" color="#7d2ddf" value="1" label="usgs.ecotapestry.breaks.foothills"/>
          <item alpha="255" color="#e1dfe7" value="2" label="usgs.ecotapestry.flat.plains"/>
          <item alpha="255" color="#0c4bd4" value="3" label="usgs.ecotapestry.high.mountains.deep.canyons"/>
          <item alpha="255" color="#e7777a" value="4" label="usgs.ecotapestry.hills"/>
          <item alpha="255" color="#5dea83" value="5" label="usgs.ecotapestry.low.hills"/>
          <item alpha="255" color="#e43463" value="6" label="usgs.ecotapestry.low.mountains"/>
          <item alpha="255" color="#0ded15" value="7" label="usgs.ecotapestry.smooth.plains"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation saturation="0" colorizeStrength="100" colorizeGreen="128" colorizeOn="0" grayscaleMode="0" colorizeRed="255" colorizeBlue="128"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
