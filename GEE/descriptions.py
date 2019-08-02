#%%
from gee_upload import layer_table, layer_metadata, read_zenodo_desc, gee_layer_resolution
from pathlib import Path
from markdownify import markdownify as mdf
import urllib

try:
    thisfile = __file__
except:
    thisfile = '/content/LandGISmaps/GEE/descriptions.py'
dst_folder = Path(thisfile).parent.joinpath('catalog').joinpath('descriptions') 

#%%
def get_all_descriptions():
    '''
    Download all descriptions and save it in html and markdown format
    '''

    for irow, row in layer_table.iterrows():
        print(irow, row.layer_unique_number, row.layer_download_url, end='')
        desc_url = row.layer_download_url

        if 'zenodo' in desc_url:
            desc_html = read_zenodo_desc(desc_url)
            dst_html = dst_folder.joinpath(row.layer_gee_id+'_zenodo.html')
            dst_html.write_text(desc_html)
            print('... from zenodo', end='')
        else:
            desc_html = urllib.request.urlopen(desc_url).read().decode('utf8')
            dst_html = dst_folder.joinpath(row.layer_gee_id+'_download.html')
            print('... from layer_download_url', end='')

        desc_md = mdf(desc_html).strip()
        dst_md = dst_html.with_suffix('.md')
        dst_md.write_text(desc_md)            
        
        if type(row.layer_metadata_url)!=float and row.layer_metadata_url.strip() != '':
            try:
                desc_html = urllib.request.urlopen(row.layer_metadata_url.strip()).read().decode('utf8')
                dst_html = dst_folder.joinpath(row.layer_gee_id+'_metadata.html')
                print ('... from layer_metadata_url')

                desc_md = mdf(desc_html).strip()
                dst_md = dst_html.with_suffix('.md')
                dst_md.write_text(desc_md)
            except:
                print()
        else:
            print()
        

def get_all_thumbnails():
    bbox = "-10,30,30,70"

    for irow, row in layer_table.iterrows():
        print(irow, row.layer_unique_number, row.layer_download_url)
        md = layer_metadata(row.layer_unique_number)

        url = '{}/reflect?layers={}&format=image/png8&width=256&height=256&bbox={}'.format(
            md['wms_server'], md['wms_layer_name'], bbox)

        image = urllib.request.urlopen(url).read()
        
        dst_image = dst_folder.parent.joinpath('thumbs').joinpath(md['gee_id']+'.png')
        dst_image.write_bytes(image)



if __name__=='__main__':
    # get_all_descriptions()
    get_all_thumbnails()
