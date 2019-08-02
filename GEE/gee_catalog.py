#%%
from gee_upload import layer_table, layer_metadata, read_zenodo_desc, gee_layer_resolution
from gee_upload import init_ee
from collections import OrderedDict
import os.path as osp
from pathlib import Path

# literal for yaml
class literal(str): pass

try:
    thisfile = __file__
except:
    thisfile = '/content/LandGISmaps/GEE/gee_catalog.py'

catalog_fld = Path(thisfile).parent.joinpath('catalog')
yaml_fld = catalog_fld.joinpath('yamls')
#%%
def get_gee_vis(md):
    import urllib
    from bs4 import BeautifulSoup
    
    url = md['properties' ]['sld_link']
    
    sld = urllib.request.urlopen(url).read().decode('utf8')

    src = BeautifulSoup(sld,'xml')  
    cme = src.find_all('ColorMapEntry')
    min = float(cme[0]['quantity'])
    max = float(cme[-1]['quantity'])
    palette = list(map(lambda x: x['color'].strip('#'), cme))
    return dict(min=[min], max=[max], palette=palette)

def get_gee_classes(md):
    import urllib
    from bs4 import BeautifulSoup

    url = md['properties' ]['sld_link']    
    sld = urllib.request.urlopen(url).read().decode('utf8')
    src = BeautifulSoup(sld,'xml')  
    cme = src.find_all('ColorMapEntry')

    classes = list(map(lambda x: {
        'value': x['quantity'], 
        'description':x['label'],
        'color': x['color'].strip('#')}, cme))

    return classes

def to_yaml(root):
    import yaml
    
    def literal_presenter(dumper, data):
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')

    yaml.add_representer(literal, literal_presenter)

    def ordered_dict_presenter(dumper, data):
        return dumper.represent_dict(data.items())

    yaml.add_representer(OrderedDict, ordered_dict_presenter)

    return yaml.dump(root, default_flow_style=False)

def save_yaml(root):
    gee_id = root['id']
    text = to_yaml(root)
    dst_file = yaml_fld.joinpath(gee_id+'.yaml')
    dst_file.write_text(text)



#%%
def gee_catalog_root(lun):

    from markdownify import markdownify as mdf
    import io
    from pprint import pprint

    
    # Nemogu ga natjerat da radi ... probat sa ovim packagem:
    # OK, sada radi samo za neke literale daje "|-" a za neke samo "|"
    #### https://pypi.org/project/ruamel.yaml/
    #### https://stackoverflow.com/questions/6432605/any-yaml-libraries-in-python-that-support-dumping-of-long-strings-as-block-liter
    

    md = layer_metadata(lun)
    pr = md['properties']
    row = md['row']
    bbox = "-10,30,30,70"

    root = OrderedDict(id=md['gee_id'])

    # dataset
    dataset = OrderedDict()
    root['dataset'] = dataset
    # Parent dataset properties ?
    dataset['title'] = "OpenLandMap " + pr['title']
    dataset['coverage'] = OrderedDict(extent="GLOBAL") #TODO Check how to get real extent    
    dataset['user_uploaded'] = True
    dataset['thumbnailUrl'] ='{}/reflect?layers={}&format=image/png8&width=256&height=256&bbox={}'.format(
        md['wms_server'], md['wms_layer_name'], bbox)
     
    desc_file = catalog_fld.joinpath('descs_for_catalog').joinpath(md['gee_id']+'.md')
    if desc_file.exists():
        desc_md = desc_file.read_text()
    else:
        if 'zenodo' in row['layer_download_url']:
            desc_html = read_zenodo_desc(row['layer_download_url'])
        else:
            desc_html = pr['description']
        desc_md = mdf(desc_html).strip()

    dataset['description'] = literal(desc_md)
    #dataset['footer'] = literal('footer')   #TODO: fix
    dataset['term_of_use'] = literal('[{}]({})'.format(row['layer_data_license'], row['layer_data_license_url']))
    dataset['citations'] = ['"{}\n[{}]({})"'.format(
        row['layer_citation_title'], row['layer_citation_doi'], row['layer_download_url'])]
    dataset['productTags'] = pr['product_tags'].split(',')
    dataset['sourceTags'] = [row['layer_organization']]
    dataset['providers'] = [{'name': row['layer_organization']}] # 'link': 'https://opengeohub.org'}]
    
    # visualizations
    vis = dict(displayName = pr['title'])
    vis['imageVisualization']=dict(global_vis=get_gee_vis(md))
    viss = io.StringIO()
    pprint([vis], viss)
    viss = viss.getvalue().replace("'",'"')
    dataset['visualizations'] = literal(viss)
        
    #imageCollection
    imgcol = OrderedDict()    
    imgcol['x_resolution'] = gee_layer_resolution(row['layer_distribution_folder'])
    
    #TODO: 3D, TS, SS 
    if md['type_spatial'] == '2D':
        # Only image section is needed and no cadence, but I'll keep variable name imgcol
        root['image'] = imgcol

        #bands
        band = OrderedDict(id=row['layer_variable_generic_name'], 
                    description=row['layer_title'], 
                    units=row['layer_units'])
        band['estimated_min_value'] = vis['imageVisualization']['global_vis']['min'][0]
        band['estimated_max_value'] = vis['imageVisualization']['global_vis']['max'][0]        
        band['classes'] = get_gee_classes(md)

        imgcol['bands'] = [band]
    elif md['type_spatial'] == 'TS':
        root['imageCollection'] = imgcol
        # cadence         
        if md['year_start'] is not None:
            imgcol['cadence'] = OrderedDict(interval = int(md['year_end'])-int(md['year_start'])+1, unit='YEAR')

    return root

    

#%%
def gee_catalog_pnv():
#%%
    lun = '7.1'
    root = gee_catalog_root(lun)
    save_yaml(root)



#%%
    


def gee_catalog_2D():
    
    table_2d = layer_table.loc[layer_table.layer_display_type.apply(lambda x: x.split('_')[0])=='2D']

    for i,r in table_2d.iterrows():
        
        gee_id = r['layer_gee_id']
        print(i,gee_id)

        yml = gee_catalog_root(r['layer_unique_number'])
        with open(osp.join('/content/LandGISmaps/GEE/catalog/test_2D',gee_id+'.yaml.txt'),'w') as fid:
            fid.write(yml)

#%%