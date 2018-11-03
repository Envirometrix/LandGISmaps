<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>dtm_lithology_usgs.ecotapestry_c</sld:Name>
            <sld:Description>Rock types</sld:Description>
            <sld:Title/>
            <sld:FeatureTypeStyle>
                <sld:Name/>
                <sld:Rule>
                    <sld:RasterSymbolizer>
                        <sld:Geometry>
                            <ogc:PropertyName>grid</ogc:PropertyName>
                        </sld:Geometry>
                        <sld:Opacity>1</sld:Opacity>
                        <sld:ColorMap>
                            <sld:ColorMapEntry color="#04fd2e" label="usgs.ecotapestry.acid.plutonics" opacity="1.0" quantity="1"/>
                            <sld:ColorMapEntry color="#7302fc" label="usgs.ecotapestry.acid.volcanic" opacity="1.0" quantity="2"/>
                            <sld:ColorMapEntry color="#fbc00c" label="usgs.ecotapestry.basic.plutonics" opacity="1.0" quantity="3"/>
                            <sld:ColorMapEntry color="#9e9ea0" label="usgs.ecotapestry.basic.volcanics" opacity="1.0" quantity="4"/>
                            <sld:ColorMapEntry color="#f102a6" label="usgs.ecotapestry.carbonate.sedimentary.rock" opacity="1.0" quantity="5"/>
                            <sld:ColorMapEntry color="#2f7703" label="usgs.ecotapestry.evaporite" opacity="1.0" quantity="6"/>
                            <sld:ColorMapEntry color="#011af4" label="usgs.ecotapestry.ice.and.glaciers" opacity="1.0" quantity="7"/>
                            <sld:ColorMapEntry color="#fd3b0a" label="usgs.ecotapestry.intermediate.plutonics" opacity="1.0" quantity="8"/>
                            <sld:ColorMapEntry color="#00f47a" label="usgs.ecotapestry.intermediate.volcanics" opacity="1.0" quantity="9"/>
                            <sld:ColorMapEntry color="#c905ff" label="usgs.ecotapestry.metamorphics" opacity="1.0" quantity="10"/>
                            <sld:ColorMapEntry color="#e5f80e" label="usgs.ecotapestry.mixed.sedimentary.rock" opacity="1.0" quantity="11"/>
                            <sld:ColorMapEntry color="#079cf2" label="usgs.ecotapestry.pyroclastics" opacity="1.0" quantity="12"/>
                            <sld:ColorMapEntry color="#f1c3f8" label="usgs.ecotapestry.siliciclastic.sedimentary" opacity="1.0" quantity="13"/>
                            <sld:ColorMapEntry color="#16f30a" label="usgs.ecotapestry.unconsolidated.sediment" opacity="1.0" quantity="14"/>
                            <sld:ColorMapEntry color="#4209ff" label="usgs.ecotapestry.undefined" opacity="1.0" quantity="15"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
