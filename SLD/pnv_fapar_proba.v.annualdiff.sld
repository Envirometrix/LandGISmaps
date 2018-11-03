<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>pnv_fapar_proba.v.annualdiff</sld:Name>
            <sld:Description>Difference between potential and actual FAPAR</sld:Description>
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
                            <sld:ColorMapEntry color="#00ff00" label="-150" opacity="1.0" quantity="-150"/>
                            <sld:ColorMapEntry color="#80ff80" label="-75" opacity="1.0" quantity="-75"/>
                            <sld:ColorMapEntry color="#ffffff" label="0" opacity="1.0" quantity="0"/>
                            <sld:ColorMapEntry color="#ff8080" label="75" opacity="1.0" quantity="75"/>
                            <sld:ColorMapEntry color="#ff0000" label="150" opacity="1.0" quantity="150"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
