<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>sol_organic.carbon_usda.6a1c_m</sld:Name>
            <sld:Description>Soil organic carbon content in %</sld:Description>
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
                            <sld:ColorMapEntry color="#ffffa0" label="0" opacity="1.0" quantity="0"/>
                            <sld:ColorMapEntry color="#f7fcb9" label="0.5" opacity="1.0" quantity="1"/>
                            <sld:ColorMapEntry color="#d9f0a3" label="1" opacity="1.0" quantity="2"/>
                            <sld:ColorMapEntry color="#addd8e" label="2" opacity="1.0" quantity="4"/>
                            <sld:ColorMapEntry color="#78c679" label="3" opacity="1.0" quantity="6"/>
                            <sld:ColorMapEntry color="#41ab5d" label="5" opacity="1.0" quantity="10"/>
                            <sld:ColorMapEntry color="#238443" label="7.5" opacity="1.0" quantity="15"/>
                            <sld:ColorMapEntry color="#005b29" label="12.5" opacity="1.0" quantity="25"/>
                            <sld:ColorMapEntry color="#004b29" label="20" opacity="1.0" quantity="40"/>
                            <sld:ColorMapEntry color="#012b13" label="30" opacity="1.0" quantity="60"/>
                            <sld:ColorMapEntry color="#00120b" label="60" opacity="1.0" quantity="120"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
