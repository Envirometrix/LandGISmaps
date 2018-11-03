<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>prob_YlOrRd_0_35</sld:Name>
            <sld:Description>Probability 0-35</sld:Description>
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
                            <sld:ColorMapEntry color="#fecc5c" label="8.75" opacity="1.0" quantity="8.75"/>
                            <sld:ColorMapEntry color="#fd8d3c" label="17.5" opacity="1.0" quantity="17.5"/>
                            <sld:ColorMapEntry color="#f03b20" label="26.2" opacity="1.0" quantity="26.25"/>
                            <sld:ColorMapEntry color="#bd0026" label="35" opacity="1.0" quantity="35"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
