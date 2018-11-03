<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>clm_lst_mod11a2.daynight_m</sld:Name>
            <sld:Description>Difference MODIS LST day-night</sld:Description>
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
                            <sld:ColorMapEntry color="#0000ff" label="-40.51" opacity="1.0" quantity="-40.5137"/>
                            <sld:ColorMapEntry color="#00ffff" label="418.3" opacity="1.0" quantity="418.30831321"/>
                            <sld:ColorMapEntry color="#ffff00" label="877.3" opacity="1.0" quantity="877.26798679"/>
                            <sld:ColorMapEntry color="#ff0000" label="1336" opacity="1.0" quantity="1336.09"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
