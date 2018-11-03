<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>sol_organic.carbon.stock_msa.kgm2_m</sld:Name>
            <sld:Description>Soil organic carbon stock in kg / m2</sld:Description>
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
                            <sld:ColorMapEntry color="#fffc93" label="0" opacity="1.0" quantity="0"/>
                            <sld:ColorMapEntry color="#fee5ac" label="2" opacity="1.0" quantity="2"/>
                            <sld:ColorMapEntry color="#fcbba1" label="4" opacity="1.0" quantity="4"/>
                            <sld:ColorMapEntry color="#fc9272" label="13.7" opacity="1.0" quantity="7"/>
                            <sld:ColorMapEntry color="#fb6a4a" label="12" opacity="1.0" quantity="12"/>
                            <sld:ColorMapEntry color="#ef3b2c" label="22.8" opacity="1.0" quantity="20"/>
                            <sld:ColorMapEntry color="#cb181d" label="28" opacity="1.0" quantity="28"/>
                            <sld:ColorMapEntry color="#a50f15" label="35" opacity="1.0" quantity="35"/>
                            <sld:ColorMapEntry color="#67000d" label="45" opacity="1.0" quantity="45"/>
                            <sld:ColorMapEntry color="#360000" label="65" opacity="1.0" quantity="65"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
