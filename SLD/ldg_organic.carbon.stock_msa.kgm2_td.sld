<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>sol_organic.carbon.stock_msa.kgm2_td</sld:Name>
            <sld:Description>Soil organic carbon stock cumulative difference</sld:Description>
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
                            <sld:ColorMapEntry color="#740001" label="-15" opacity="1.0" quantity="-15"/>
                            <sld:ColorMapEntry color="#b80d29" label="-10" opacity="1.0" quantity="-10"/>
                            <sld:ColorMapEntry color="#f15262" label="-5" opacity="1.0" quantity="-5"/>
                            <sld:ColorMapEntry color="#f7f7f7" label="0" opacity="1.0" quantity="0"/>
                            <sld:ColorMapEntry color="#b8e186" label="5" opacity="1.0" quantity="5"/>
                            <sld:ColorMapEntry color="#4dac26" label="10" opacity="1.0" quantity="10"/>
                            <sld:ColorMapEntry color="#066709" label="15" opacity="1.0" quantity="15"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
