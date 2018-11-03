<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>Probability</sld:Name>
            <sld:Description>Ranger 0-50%</sld:Description>
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
                            <sld:ColorMapEntry color="#ffffb2" label="0" opacity="1.0" quantity="0"/>
                            <sld:ColorMapEntry color="#fecc5c" label="12.5" opacity="1.0" quantity="12.5"/>
                            <sld:ColorMapEntry color="#fd8d3c" label="25" opacity="1.0" quantity="25"/>
                            <sld:ColorMapEntry color="#f03b20" label="37.5" opacity="1.0" quantity="37.5"/>
                            <sld:ColorMapEntry color="#bd0026" label="50" opacity="1.0" quantity="50"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
