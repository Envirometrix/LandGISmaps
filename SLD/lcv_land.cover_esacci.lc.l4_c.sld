<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>lcv_land.cover_esacci.lc.l4_c</sld:Name>
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
                            <sld:ColorMapEntry color="#ffff64" label="Cropland rainfed" opacity="1.0" quantity="10"/>
                            <sld:ColorMapEntry color="#ffff64" label="Cropland rainfed - Herbaceous cover" opacity="1.0" quantity="11"/>
                            <sld:ColorMapEntry color="#ffff00" label="Cropland rainfed - Tree or shrub cover" opacity="1.0" quantity="12"/>
                            <sld:ColorMapEntry color="#aaf0f0" label="Cropland irrigated or post-flooding" opacity="1.0" quantity="20"/>
                            <sld:ColorMapEntry color="#dcf064" label="Mosaic cropland (&gt;50%) / natural vegetation (tree/shrub/herbaceous cover) (&lt;50%)" opacity="1.0" quantity="30"/>
                            <sld:ColorMapEntry color="#c8c864" label="Mosaic natural vegetation (tree/shrub/herbaceous cover) (&gt;50%) / cropland (&lt;50%) " opacity="1.0" quantity="40"/>
                            <sld:ColorMapEntry color="#006400" label="Tree cover broadleaved evergreen closed to open (&gt;15%)" opacity="1.0" quantity="50"/>
                            <sld:ColorMapEntry color="#00a000" label="Tree cover  broadleaved  deciduous  closed to open (&gt;15%)" opacity="1.0" quantity="60"/>
                            <sld:ColorMapEntry color="#00a000" label="Tree cover  broadleaved  deciduous  closed (&gt;40%)" opacity="1.0" quantity="61"/>
                            <sld:ColorMapEntry color="#aac800" label="Tree cover  broadleaved  deciduous  open (15-40%)" opacity="1.0" quantity="62"/>
                            <sld:ColorMapEntry color="#003c00" label="Tree cover  needleleaved  evergreen  closed to open (&gt;15%)" opacity="1.0" quantity="70"/>
                            <sld:ColorMapEntry color="#003c00" label="Tree cover  needleleaved  evergreen  closed (&gt;40%)" opacity="1.0" quantity="71"/>
                            <sld:ColorMapEntry color="#005000" label="Tree cover  needleleaved  evergreen  open (15-40%)" opacity="1.0" quantity="72"/>
                            <sld:ColorMapEntry color="#285000" label="Tree cover  needleleaved  deciduous  closed to open (&gt;15%)" opacity="1.0" quantity="80"/>
                            <sld:ColorMapEntry color="#285000" label="Tree cover  needleleaved  deciduous  closed (&gt;40%)" opacity="1.0" quantity="81"/>
                            <sld:ColorMapEntry color="#286400" label="Tree cover  needleleaved  deciduous  open (15-40%)" opacity="1.0" quantity="82"/>
                            <sld:ColorMapEntry color="#788200" label="Tree cover  mixed leaf type (broadleaved and needleleaved)" opacity="1.0" quantity="90"/>
                            <sld:ColorMapEntry color="#8ca000" label="Mosaic tree and shrub (&gt;50%) / herbaceous cover (&lt;50%)" opacity="1.0" quantity="100"/>
                            <sld:ColorMapEntry color="#be9600" label="Mosaic herbaceous cover (&gt;50%) / tree and shrub (&lt;50%)" opacity="1.0" quantity="110"/>
                            <sld:ColorMapEntry color="#966400" label="Shrubland" opacity="1.0" quantity="120"/>
                            <sld:ColorMapEntry color="#966400" label="Shrubland evergreen" opacity="1.0" quantity="121"/>
                            <sld:ColorMapEntry color="#966400" label="Shrubland deciduous" opacity="1.0" quantity="122"/>
                            <sld:ColorMapEntry color="#ffb432" label="Grassland" opacity="1.0" quantity="130"/>
                            <sld:ColorMapEntry color="#ffdcd2" label="Lichens and mosses" opacity="1.0" quantity="140"/>
                            <sld:ColorMapEntry color="#ffebaf" label="Sparse vegetation (tree/shrub/herbaceous cover) (&lt;15%)" opacity="1.0" quantity="150"/>
                            <sld:ColorMapEntry color="#ffc864" label="Sparse tree (&lt;15%)" opacity="1.0" quantity="151"/>
                            <sld:ColorMapEntry color="#ffd278" label="Sparse shrub (&lt;15%)" opacity="1.0" quantity="152"/>
                            <sld:ColorMapEntry color="#ffebaf" label="Sparse herbaceous cover (&lt;15%)" opacity="1.0" quantity="153"/>
                            <sld:ColorMapEntry color="#00785a" label="Tree cover flooded fresh or brakish water" opacity="1.0" quantity="160"/>
                            <sld:ColorMapEntry color="#009678" label="Tree cover flooded saline water" opacity="1.0" quantity="170"/>
                            <sld:ColorMapEntry color="#00dc82" label="Shrub or herbaceous cover flooded fresh/saline/brakish water" opacity="1.0" quantity="180"/>
                            <sld:ColorMapEntry color="#c31400" label="Urban areas" opacity="1.0" quantity="190"/>
                            <sld:ColorMapEntry color="#fff5d7" label="Bare areas" opacity="1.0" quantity="200"/>
                            <sld:ColorMapEntry color="#dcdcdc" label="Consolidated bare areas" opacity="1.0" quantity="201"/>
                            <sld:ColorMapEntry color="#fff5d7" label="Unconsolidated bare areas" opacity="1.0" quantity="202"/>
                            <sld:ColorMapEntry color="#0046c8" label="Water bodies" opacity="1.0" quantity="210"/>
                            <sld:ColorMapEntry color="#ffffff" label="Permanent snow and ice" opacity="1.0" quantity="220"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
