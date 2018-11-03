<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.2.3-Bonn" hasScaleBasedVisibilityFlag="0" minScale="1e+08" maxScale="0">
  <pipe>
    <rasterrenderer classificationMax="15" classificationMin="1" opacity="1" alphaBand="-1" band="1" type="singlebandpseudocolor">
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
            <prop k="count" v="15"/>
            <prop k="hueMax" v="359"/>
            <prop k="hueMin" v="0"/>
            <prop k="rampType" v="random"/>
            <prop k="satMax" v="240"/>
            <prop k="satMin" v="255"/>
            <prop k="valMax" v="240"/>
            <prop k="valMin" v="255"/>
          </colorramp>
          <item alpha="255" color="#04fd2e" value="1" label="usgs.ecotapestry.acid.plutonics"/>
          <item alpha="255" color="#7302fc" value="2" label="usgs.ecotapestry.acid.volcanic"/>
          <item alpha="255" color="#fbc00c" value="3" label="usgs.ecotapestry.basic.plutonics"/>
          <item alpha="255" color="#9e9ea0" value="4" label="usgs.ecotapestry.basic.volcanics"/>
          <item alpha="255" color="#f102a6" value="5" label="usgs.ecotapestry.carbonate.sedimentary.rock"/>
          <item alpha="255" color="#2f7703" value="6" label="usgs.ecotapestry.evaporite"/>
          <item alpha="255" color="#011af4" value="7" label="usgs.ecotapestry.ice.and.glaciers"/>
          <item alpha="255" color="#fd3b0a" value="8" label="usgs.ecotapestry.intermediate.plutonics"/>
          <item alpha="255" color="#00f47a" value="9" label="usgs.ecotapestry.intermediate.volcanics"/>
          <item alpha="255" color="#c905ff" value="10" label="usgs.ecotapestry.metamorphics"/>
          <item alpha="255" color="#e5f80e" value="11" label="usgs.ecotapestry.mixed.sedimentary.rock"/>
          <item alpha="255" color="#079cf2" value="12" label="usgs.ecotapestry.pyroclastics"/>
          <item alpha="255" color="#f1c3f8" value="13" label="usgs.ecotapestry.siliciclastic.sedimentary"/>
          <item alpha="255" color="#16f30a" value="14" label="usgs.ecotapestry.unconsolidated.sediment"/>
          <item alpha="255" color="#4209ff" value="15" label="usgs.ecotapestry.undefined"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation saturation="0" colorizeStrength="100" colorizeGreen="128" colorizeOn="0" grayscaleMode="0" colorizeRed="255" colorizeBlue="128"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
