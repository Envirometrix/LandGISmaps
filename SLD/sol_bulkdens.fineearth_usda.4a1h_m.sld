<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>sol_bulkdens.fineearth_usda.4a1h_m</sld:Name>
            <sld:Description>Soil bulk density fine earth in kg*10 per m3</sld:Description>
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
                            <sld:ColorMapEntry color="#5e3c99" label="5" opacity="1.0" quantity="5"/>
                            <sld:ColorMapEntry color="#b2abd2" label="50" opacity="1.0" quantity="50"/>
                            <sld:ColorMapEntry color="#f7e0b2" label="95" opacity="1.0" quantity="95"/>
                            <sld:ColorMapEntry color="#fdb863" label="140" opacity="1.0" quantity="140"/>
                            <sld:ColorMapEntry color="#e63b01" label="185" opacity="1.0" quantity="185"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
