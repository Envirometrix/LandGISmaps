<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>clm_precipitation_imerge</sld:Name>
            <sld:Description>Monthly precipitation in mm/month</sld:Description>
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
                            <sld:ColorMapEntry color="#ffff00" label="25" opacity="1.0" quantity="25"/>
                            <sld:ColorMapEntry color="#3af6ff" label="90" opacity="1.0" quantity="90"/>
                            <sld:ColorMapEntry color="#467aff" label="180" opacity="1.0" quantity="180"/>
                            <sld:ColorMapEntry color="#313eff" label="280" opacity="1.0" quantity="280"/>
                            <sld:ColorMapEntry color="#0008ff" label="380" opacity="1.0" quantity="380"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
