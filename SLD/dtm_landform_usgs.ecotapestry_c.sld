<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>dtm_landform_usgs.ecotapestry_c</sld:Name>
            <sld:Description>Landform classes</sld:Description>
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
                            <sld:ColorMapEntry color="#7d2ddf" label="usgs.ecotapestry.breaks.foothills" opacity="1.0" quantity="1"/>
                            <sld:ColorMapEntry color="#e1dfe7" label="usgs.ecotapestry.flat.plains" opacity="1.0" quantity="2"/>
                            <sld:ColorMapEntry color="#0c4bd4" label="usgs.ecotapestry.high.mountains.deep.canyons" opacity="1.0" quantity="3"/>
                            <sld:ColorMapEntry color="#e7777a" label="usgs.ecotapestry.hills" opacity="1.0" quantity="4"/>
                            <sld:ColorMapEntry color="#5dea83" label="usgs.ecotapestry.low.hills" opacity="1.0" quantity="5"/>
                            <sld:ColorMapEntry color="#e43463" label="usgs.ecotapestry.low.mountains" opacity="1.0" quantity="6"/>
                            <sld:ColorMapEntry color="#0ded15" label="usgs.ecotapestry.smooth.plains" opacity="1.0" quantity="7"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
