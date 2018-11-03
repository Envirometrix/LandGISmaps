<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>dtm_slope_merit.dem_m</sld:Name>
            <sld:Description>Slope in radians</sld:Description>
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
                            <sld:ColorMapEntry color="#fcffa4" label="0" opacity="1.0" quantity="0"/>
                            <sld:ColorMapEntry color="#f5f992" label="1.27" opacity="1.0" quantity="1.27452"/>
                            <sld:ColorMapEntry color="#f2f27d" label="2.55" opacity="1.0" quantity="2.54904"/>
                            <sld:ColorMapEntry color="#f2ea69" label="3.82" opacity="1.0" quantity="3.82356"/>
                            <sld:ColorMapEntry color="#f4e156" label="5.1" opacity="1.0" quantity="5.098015"/>
                            <sld:ColorMapEntry color="#f6d746" label="6.37" opacity="1.0" quantity="6.372535"/>
                            <sld:ColorMapEntry color="#f8cd37" label="7.65" opacity="1.0" quantity="7.647055"/>
                            <sld:ColorMapEntry color="#fac42a" label="8.92" opacity="1.0" quantity="8.921575"/>
                            <sld:ColorMapEntry color="#fbba1f" label="10.2" opacity="1.0" quantity="10.196095"/>
                            <sld:ColorMapEntry color="#fcb014" label="11.5" opacity="1.0" quantity="11.470615"/>
                            <sld:ColorMapEntry color="#fca60c" label="12.7" opacity="1.0" quantity="12.74507"/>
                            <sld:ColorMapEntry color="#fb9d07" label="14" opacity="1.0" quantity="14.01959"/>
                            <sld:ColorMapEntry color="#fa9407" label="15.3" opacity="1.0" quantity="15.29411"/>
                            <sld:ColorMapEntry color="#f98b0b" label="16.6" opacity="1.0" quantity="16.56863"/>
                            <sld:ColorMapEntry color="#f78212" label="17.8" opacity="1.0" quantity="17.84315"/>
                            <sld:ColorMapEntry color="#f47918" label="19.1" opacity="1.0" quantity="19.11767"/>
                            <sld:ColorMapEntry color="#f1711f" label="20.4" opacity="1.0" quantity="20.392125"/>
                            <sld:ColorMapEntry color="#ed6925" label="21.7" opacity="1.0" quantity="21.666645"/>
                            <sld:ColorMapEntry color="#e9612b" label="22.9" opacity="1.0" quantity="22.941165"/>
                            <sld:ColorMapEntry color="#e45a31" label="24.2" opacity="1.0" quantity="24.215685"/>
                            <sld:ColorMapEntry color="#df5337" label="25.5" opacity="1.0" quantity="25.490205"/>
                            <sld:ColorMapEntry color="#d94d3d" label="26.8" opacity="1.0" quantity="26.764725"/>
                            <sld:ColorMapEntry color="#d34743" label="28" opacity="1.0" quantity="28.039245"/>
                            <sld:ColorMapEntry color="#cc4248" label="29.3" opacity="1.0" quantity="29.3137"/>
                            <sld:ColorMapEntry color="#c63d4d" label="30.6" opacity="1.0" quantity="30.58822"/>
                            <sld:ColorMapEntry color="#bf3952" label="31.9" opacity="1.0" quantity="31.86274"/>
                            <sld:ColorMapEntry color="#b73557" label="33.1" opacity="1.0" quantity="33.13726"/>
                            <sld:ColorMapEntry color="#b0315b" label="34.4" opacity="1.0" quantity="34.41178"/>
                            <sld:ColorMapEntry color="#a82e5f" label="35.7" opacity="1.0" quantity="35.6863"/>
                            <sld:ColorMapEntry color="#a02a63" label="37" opacity="1.0" quantity="36.960755"/>
                            <sld:ColorMapEntry color="#982766" label="38.2" opacity="1.0" quantity="38.235275"/>
                            <sld:ColorMapEntry color="#902568" label="39.5" opacity="1.0" quantity="39.509795"/>
                            <sld:ColorMapEntry color="#88226a" label="40.8" opacity="1.0" quantity="40.784315"/>
                            <sld:ColorMapEntry color="#801f6c" label="42.1" opacity="1.0" quantity="42.058835"/>
                            <sld:ColorMapEntry color="#781c6d" label="43.3" opacity="1.0" quantity="43.333355"/>
                            <sld:ColorMapEntry color="#71196e" label="44.6" opacity="1.0" quantity="44.607875"/>
                            <sld:ColorMapEntry color="#69166e" label="45.9" opacity="1.0" quantity="45.88233"/>
                            <sld:ColorMapEntry color="#61136e" label="47.2" opacity="1.0" quantity="47.15685"/>
                            <sld:ColorMapEntry color="#59106e" label="48.4" opacity="1.0" quantity="48.43137"/>
                            <sld:ColorMapEntry color="#510e6c" label="49.7" opacity="1.0" quantity="49.70589"/>
                            <sld:ColorMapEntry color="#490b6a" label="51" opacity="1.0" quantity="50.98041"/>
                            <sld:ColorMapEntry color="#400a67" label="52.3" opacity="1.0" quantity="52.25493"/>
                            <sld:ColorMapEntry color="#380962" label="53.5" opacity="1.0" quantity="53.529385"/>
                            <sld:ColorMapEntry color="#2f0a5b" label="54.8" opacity="1.0" quantity="54.803905"/>
                            <sld:ColorMapEntry color="#260c51" label="56.1" opacity="1.0" quantity="56.078425"/>
                            <sld:ColorMapEntry color="#1e0c45" label="57.4" opacity="1.0" quantity="57.352945"/>
                            <sld:ColorMapEntry color="#160b39" label="58.6" opacity="1.0" quantity="58.627452"/>
                            <sld:ColorMapEntry color="#10092d" label="59.9" opacity="1.0" quantity="59.901959"/>
                            <sld:ColorMapEntry color="#0a0722" label="61.2" opacity="1.0" quantity="61.1764725"/>
                            <sld:ColorMapEntry color="#050417" label="62.5" opacity="1.0" quantity="62.4509795"/>
                            <sld:ColorMapEntry color="#02020c" label="63.7" opacity="1.0" quantity="63.725493"/>
                            <sld:ColorMapEntry color="#000004" label="65" opacity="1.0" quantity="65"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
