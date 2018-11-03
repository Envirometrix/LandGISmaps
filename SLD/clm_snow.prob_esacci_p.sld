<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>clm_snow.prob_esacci_p</sld:Name>
            <sld:Description>Snow probability</sld:Description>
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
                            <sld:ColorMapEntry color="#ecffbd" label="0" opacity="1.0" quantity="0"/>
                            <sld:ColorMapEntry color="#f8e6f9" label="20" opacity="1.0" quantity="20"/>
                            <sld:ColorMapEntry color="#3af6ff" label="40" opacity="1.0" quantity="40"/>
                            <sld:ColorMapEntry color="#467aff" label="60" opacity="1.0" quantity="60"/>
                            <sld:ColorMapEntry color="#313ed4" label="80" opacity="1.0" quantity="80"/>
                            <sld:ColorMapEntry color="#0008b8" label="100" opacity="1.0" quantity="100"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
