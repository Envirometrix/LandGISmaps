from gee_upload import layer_table, layer_metadata

def raster_stats(src_filename, dst_stats):
    import rasterio as rio
    from pyproj import Proj, transform
    import numpy.ma as ma
    import json

    print('STARTED:', dst_stats)

    try:
        with rio.open(src_filename) as ds:
            bb = ds.bounds
            proj = Proj(ds.crs)
            projWGS84 = Proj('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')

            east, south = transform(proj, projWGS84, bb.left, bb.bottom)
            west, north = transform(proj, projWGS84, bb.right, bb.top)
            extent = dict(east = east, west=west, south=south, north=north)

            bands=[]

            for b in range(1, ds.count+1):
                bmins = []
                bmaxs = []
                for ji, window in ds.block_windows(b):
                    #print('--', ji,window)
                    r = ds.read(b, window=window)
                    r = ma.masked_equal(r, ds.nodatavals[b-1])
                    if not r.mask.all():
                        bmins.append(r.min())
                        bmaxs.append(r.max())
                
                bands.append(dict(id=b-1, min=0 if len(bmins)==0 else float(min(bmins)), 
                                max=0 if len(bmaxs)==0 else float(max(bmaxs))))

                #print (bands)
        res = dict(extent=extent, bands=bands)
        dst_stats.write_text(json.dumps(res))
        #open(dst_stats,'w').write(json.dumps(res))
        print('ENDED:', dst_stats)
    except:
        print('ERROR:', dst_stats)

def make_all_stats():
    from pathlib import Path
    from multiprocessing import Pool

    #srcfolder = Path(r'D:\DATA\HAC2019\orthophoto\tiffs10cm')
    outfolder = Path(r'/content/LandGISmaps/GEE/catalog/raster_stats')

    with Pool(processes=6) as pool:
        for lun in layer_table['layer_unique_number']:
            md = layer_metadata(lun)
            src = md['gcs_source_filename']
            dst = (outfolder / md['gee_id']).with_suffix('.json')
            print(src,' --> ',dst)
            pool.apply_async(raster_stats, (src, dst))
        pool.close()
        pool.join()
    #    pool.starmap(raster_stats,[(fn,(outfolder / fn.name).with_suffix('.json')) for fn in srcfolder.glob('*.tif')])
        #for fn in srcfolder.glob('*.tif'):
        #    print(fn)
        #    dstfile = (outfolder / fn.name).with_suffix('.json')


if __name__=='__main__':
    make_all_stats()