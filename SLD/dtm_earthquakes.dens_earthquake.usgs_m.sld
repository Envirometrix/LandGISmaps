<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>dtm_earthquakes.dens_earthquake.usgs_m</sld:Name>
            <sld:Description>Earthquakes density</sld:Description>
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
                            <sld:ColorMapEntry color="#fff5f0" label="0" opacity="1.0" quantity="0"/>
                            <sld:ColorMapEntry color="#fee0d2" label="84.5" opacity="1.0" quantity="84.5"/>
                            <sld:ColorMapEntry color="#fcbba1" label="169" opacity="1.0" quantity="169"/>
                            <sld:ColorMapEntry color="#fc9272" label="254" opacity="1.0" quantity="253.5"/>
                            <sld:ColorMapEntry color="#fb6a4a" label="338" opacity="1.0" quantity="338"/>
                            <sld:ColorMapEntry color="#ef3b2c" label="422" opacity="1.0" quantity="422.5"/>
                            <sld:ColorMapEntry color="#cb181d" label="507" opacity="1.0" quantity="507"/>
                            <sld:ColorMapEntry color="#a50f15" label="585" opacity="1.0" quantity="585"/>
                            <sld:ColorMapEntry color="#67000d" label="650" opacity="1.0" quantity="650"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
