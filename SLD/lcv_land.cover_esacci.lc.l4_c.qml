<?xml version="1.0" ?>
<qgis>
    <pipe>
        <rasterrenderer band="1" opacity="1" type="singlebandpseudocolor">
            <rasterTransparency/>
            <rastershader>
                <colorrampshader colorRampType="INTERPOLATED">
                    <item alpha="255" color="#ffff64" label="Cropland rainfed" value="10"/>
                    <item alpha="255" color="#ffff64" label="Cropland rainfed - Herbaceous cover" value="11"/>
                    <item alpha="255" color="#ffff00" label="Cropland rainfed - Tree or shrub cover" value="12"/>
                    <item alpha="255" color="#aaf0f0" label="Cropland irrigated or post-flooding" value="20"/>
                    <item alpha="255" color="#dcf064" label="Mosaic cropland (&gt;50%) / natural vegetation (tree/shrub/herbaceous cover) (&lt;50%)" value="30"/>
                    <item alpha="255" color="#c8c864" label="Mosaic natural vegetation (tree/shrub/herbaceous cover) (&gt;50%) / cropland (&lt;50%) " value="40"/>
                    <item alpha="255" color="#006400" label="Tree cover broadleaved evergreen closed to open (&gt;15%)" value="50"/>
                    <item alpha="255" color="#00a000" label="Tree cover  broadleaved  deciduous  closed to open (&gt;15%)" value="60"/>
                    <item alpha="255" color="#00a000" label="Tree cover  broadleaved  deciduous  closed (&gt;40%)" value="61"/>
                    <item alpha="255" color="#aac800" label="Tree cover  broadleaved  deciduous  open (15-40%)" value="62"/>
                    <item alpha="255" color="#003c00" label="Tree cover  needleleaved  evergreen  closed to open (&gt;15%)" value="70"/>
                    <item alpha="255" color="#003c00" label="Tree cover  needleleaved  evergreen  closed (&gt;40%)" value="71"/>
                    <item alpha="255" color="#005000" label="Tree cover  needleleaved  evergreen  open (15-40%)" value="72"/>
                    <item alpha="255" color="#285000" label="Tree cover  needleleaved  deciduous  closed to open (&gt;15%)" value="80"/>
                    <item alpha="255" color="#285000" label="Tree cover  needleleaved  deciduous  closed (&gt;40%)" value="81"/>
                    <item alpha="255" color="#286400" label="Tree cover  needleleaved  deciduous  open (15-40%)" value="82"/>
                    <item alpha="255" color="#788200" label="Tree cover  mixed leaf type (broadleaved and needleleaved)" value="90"/>
                    <item alpha="255" color="#8ca000" label="Mosaic tree and shrub (&gt;50%) / herbaceous cover (&lt;50%)" value="100"/>
                    <item alpha="255" color="#be9600" label="Mosaic herbaceous cover (&gt;50%) / tree and shrub (&lt;50%)" value="110"/>
                    <item alpha="255" color="#966400" label="Shrubland" value="120"/>
                    <item alpha="255" color="#966400" label="Shrubland evergreen" value="121"/>
                    <item alpha="255" color="#966400" label="Shrubland deciduous" value="122"/>
                    <item alpha="255" color="#ffb432" label="Grassland" value="130"/>
                    <item alpha="255" color="#ffdcd2" label="Lichens and mosses" value="140"/>
                    <item alpha="255" color="#ffebaf" label="Sparse vegetation (tree/shrub/herbaceous cover) (&lt;15%)" value="150"/>
                    <item alpha="255" color="#ffc864" label="Sparse tree (&lt;15%)" value="151"/>
                    <item alpha="255" color="#ffd278" label="Sparse shrub (&lt;15%)" value="152"/>
                    <item alpha="255" color="#ffebaf" label="Sparse herbaceous cover (&lt;15%)" value="153"/>
                    <item alpha="255" color="#00785a" label="Tree cover flooded fresh or brakish water" value="160"/>
                    <item alpha="255" color="#009678" label="Tree cover flooded saline water" value="170"/>
                    <item alpha="255" color="#00dc82" label="Shrub or herbaceous cover flooded fresh/saline/brakish water" value="180"/>
                    <item alpha="255" color="#c31400" label="Urban areas" value="190"/>
                    <item alpha="255" color="#fff5d7" label="Bare areas" value="200"/>
                    <item alpha="255" color="#dcdcdc" label="Consolidated bare areas" value="201"/>
                    <item alpha="255" color="#fff5d7" label="Unconsolidated bare areas" value="202"/>
                    <item alpha="255" color="#0046c8" label="Water bodies" value="210"/>
                    <item alpha="255" color="#ffffff" label="Permanent snow and ice" value="220"/>
                </colorrampshader>
            </rastershader>
        </rasterrenderer>
        <brightnesscontrast/>
        <huesaturation/>
        <rasterresampler/>
    </pipe>
    <blendMode>0</blendMode>
</qgis>
