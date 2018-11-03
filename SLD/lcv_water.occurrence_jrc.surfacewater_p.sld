<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>lcv_water.occurance_jrc.surfacewater_p</sld:Name>
            <sld:Description>Water occurrance probability</sld:Description>
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
                            <sld:ColorMapEntry color="#ffffcc" label="0" opacity="1.0" quantity="0"/>
                            <sld:ColorMapEntry color="#a1dab4" label="3.75" opacity="1.0" quantity="3.75"/>
                            <sld:ColorMapEntry color="#41b6c4" label="7.5" opacity="1.0" quantity="7.5"/>
                            <sld:ColorMapEntry color="#2c7fb8" label="11.2" opacity="1.0" quantity="11.25"/>
                            <sld:ColorMapEntry color="#253494" label="15" opacity="1.0" quantity="15"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
