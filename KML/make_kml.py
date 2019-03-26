# -*- coding: utf-8 -*-
"""
Created on Mon Mar  4 11:12:21 2019

@author: josip
"""

import pandas
from owslib.wms import WebMapService
import simplekml
import xml.etree.ElementTree as ET
import os.path as osp
import fnmatch, re

layer_table_path = 'https://raw.githubusercontent.com/Envirometrix/LandGISmaps/master/tables/LandGIS_tables_landgis_layers.csv'

df = pandas.read_table(layer_table_path,sep=',')
df = df.loc[df.layer_public_download==1,:]

wms = WebMapService('https://geoserver.opengeohub.org/landgisgeoserver/wms', version='1.3.0')
wms_layers = list(wms.contents)
wms_xml = ET.fromstring(wms.getServiceXML())

folder_style_radio = simplekml.Style()
folder_style_radio.liststyle.listitemtype = simplekml.ListItemType.radiofolder

link_style_hidden = simplekml.Style()
link_style_hidden.liststyle.listitemtype = simplekml.ListItemType.checkhidechildren

#%%
def month_to_number(month):
    months = dict(jan=1, feb=2, mar=3, apr=4, may=5, jun=6, jul=7, aug=8, sep=9, oct=10, nov=11, dec=12, annual=13, annualdiff=14)
    return months.get(month,0)

def find_month(desc):
    months = dict(jan=1, feb=2, mar=3, apr=4, may=5, jun=6, jul=7, aug=8, sep=9, oct=10, nov=11, dec=12, annual=13, annualdiff=14)
    for month in months.keys():
        if month in re.split(r'[\.\_]+',desc):
            return month
    return desc
    
    
def time_designation(time_string):    
    m = re.match(r'^-?\d+$', time_string.strip())
    if m:        
        return {'prop': 'newtimestamp', 'args':(time_string,)}
    
    m = re.match(r'^(\d{4})\.\.(\d{4})$', time_string)
    if m:        
        return {'prop':'newtimespan', 'args':('{}-1-1'.format(m.group(1)), '{}-12-31'.format(m.group(2)))}
    
    raise Exception('add_time_designation: unknown time_string format: {}'.format(time_string))
        
def get_legend_link(layer_name):
    ns = {'ns': 'http://www.opengis.net/wms'}
    elems = wms_xml.findall(".//ns:Layer[ns:Name='{}']/ns:Style/ns:LegendURL/ns:OnlineResource".format(layer_name),ns)
    if len(elems) != 1:
        return None
    href = elems[0].attrib['{http://www.w3.org/1999/xlink}href']
    href = href.replace("height=20", "height=10")
    return href

def setup_timeref(kml_feature, td):
    if td is None:
        return
    if td['prop'] == 'newtimestamp':
        kml_feature.timestamp.when = td['args'][0]
    if td['prop'] == 'newtimespan':
        kml_feature.timespan.begin = td['args'][0]
        kml_feature.timespan.end = td['args'][1]    
        
def link(href, text):
    return "<a href={}>{}</a>".format(href, text)

def link_layer(r):
    # dtm_slope_merit.dem_m
    layer_href = 'https://landgis.opengeohub.org/#/?base=Stamen%20(OpenStreetMap)&center=39.0000,25.0000&zoom=4&opacity=80&layer={}'
    layer_href = layer_href.format(r.layer_filename_shortname)
    return link(layer_href, r.layer_title_description)

def setup_legend(screen):
    screen.overlayxy = simplekml.OverlayXY(x=1,y=1,xunits=simplekml.Units.fraction,
                                       yunits=simplekml.Units.fraction)
    screen.screenxy = simplekml.ScreenXY(x=15,y=15,xunits=simplekml.Units.insetpixels,
                                         yunits=simplekml.Units.insetpixels)
    '''
    screen.size.x = -1
    screen.size.y = -1
    screen.size.xunits = simplekml.Units.fraction
    screen.size.yunits = simplekml.Units.fraction
    '''
    
def setup_network_link(parent, name, layer_name, when=None, description=None, 
                       td=None):
    # Folder to contain network link and legend as screenoverlay
    fld = parent.newfolder(name=name)
    
    # NetworkLink
    netlink = fld.newnetworklink()
    netlink.name = name
    #netlink.style = link_style_hidden
    if description is not None:
        fld.description = description
    #netlink.visibility = 0
    #netlink.open = 0
    netlink.link.href = 'https://geoserver.opengeohub.org/landgisgeoserver/wms/kml?layers={}'.format(layer_name)
    if when is not None:
        netlink.timestamp.when = when
    setup_timeref(netlink, td)
    
    # Legend
    legend_link = get_legend_link(layer_name)
    if legend_link is not None:
        screen = fld.newscreenoverlay(name='Legend')
        screen.icon.href = legend_link
        setup_legend(screen)
    
    fld.visibility = 0
    fld.open = 0
    fld.style = link_style_hidden
        
        
#%%
def make_kml(output_kml, output_format='kmz'):
    
    kml = simplekml.Kml(open=1, name='LandGIS: Open Land Data')
    kml.document.description = link("http://opengeohub.org/about-landgis", 'Read more ...')
    

    
    # Spatial layers
    kml_fld=kml.newfolder(name = 'Spatial layers')
    for i,r in df.iterrows():   # i,r = next(df.iterrows())
        if r.layer_display_type[:2] not in ('2D'):
            continue
        try:
            layer_name = '{}:{}'.format(r.layer_distribution_folder, osp.splitext(r.layer_filename_pattern)[0])
            layer_title = r.layer_title
            time_string = layer_name.split('_')[-2]
    
            layer_desc = '{}</br>{}'.format(link_layer(r), time_string)
            
            # Put TimeStamp or TimeSpan
            td = time_designation(time_string)
            
        except Exception as e:
            print("Error while processing {}: {}".format(layer_name, e))
        else:
            setup_network_link(kml_fld, layer_title, layer_name, description=layer_desc,
                               td=td)
    # 3D Layers
    for i,r in df.loc[df.layer_display_type.apply(lambda x: x[:2]=='3D')].iterrows():   
        # i,r = next(df.loc[df.layer_display_type.apply(lambda x: x[:2]=='3D')].iterrows())
        try:
            layer_group_name = '{}:{}'.format(r.layer_distribution_folder, osp.splitext(r.layer_filename_pattern)[0])
            layers = fnmatch.filter(wms_layers, layer_group_name.replace('*..*','*'))
            if len(layers)==0:
                continue
    
            time_string = layer_group_name.split('_')[-2]
            
            layer_desc = '{}</br>{}'.format(link_layer(r),time_string)        
            kml_fld_lay = kml_fld.newfolder(name = r.layer_title, visibility=0, description=layer_desc, open=0)
            kml_fld_lay.style = folder_style_radio
            
            setup_timeref(kml_fld_lay, time_designation(time_string))        
            
            layer_list = [(x, x.split('_')[-3].split('..')[1]) for x in layers]
            layer_list = sorted(layer_list, key=lambda x: int(x[1].replace('cm','')))
                   
            for layer_name, depth_string in layer_list: # layer_name=layers[0]                                                      
                setup_network_link(kml_fld_lay, depth_string, layer_name)
                
        except Exception as e:
            print("Error while processing {}: {}".format(layer_name, e))
        
            
    
    # Time span layers
    kml_fld = kml.newfolder(name = 'Time span layers')  # new folder 
    for i,r in df.loc[df.layer_display_type.apply(lambda x: x[:2] in ('TS','SS'))].iterrows():   
        # i,r = next(df.loc[df.layer_display_type.apply(lambda x: x[:2]=='TS')].iterrows())
        layer_type = r.layer_display_type[:2]
        try:
            # Find all layers from wms
            layer_group_name = '{}:{}'.format(r.layer_distribution_folder, osp.splitext(r.layer_filename_pattern)[0])
            layers = fnmatch.filter(wms_layers, layer_group_name)        
            if layer_type=='TS':
                layer_list = [(x, x.split('_')[-2]) for x in layers]
                layer_list = sorted(layer_list, key=lambda x: int(x[1].replace('BC','-')))    
            elif layer_type == 'SS':
                layer_list = [(x, find_month(x.split('_')[2])) for x in layers]            
                layer_list = sorted(layer_list, key=lambda x: month_to_number(x[1]))
                
    
            layer_title = r.layer_title
            
            kml_fld_lay = kml_fld.newfolder(name = layer_title, visibility=0, open=0)
            kml_fld_lay.timespan = simplekml.TimeSpan(layer_list[0][1].replace('BC','-'), layer_list[-1][1].replace('BC','-'))
            kml_fld_lay.style = folder_style_radio
            
            if layer_type == 'TS':
                layer_desc = '{}</br>{} .. {}'.format(link_layer(r), layer_list[0][1], layer_list[-1][1])
            elif layer_type == 'SS':
                layer_desc = '{}</br>{}'.format(link_layer(r), layer_group_name.split('_')[-2])                     
            kml_fld_lay.description=layer_desc
            
            for layer_name, time_string in layer_list:                    
                if layer_type == 'TS':
                    td = time_designation(time_string.replace('BC','-'))                
                elif layer_type == 'SS':
                    td = None
    
                setup_network_link(kml_fld_lay, time_string, layer_name, td=td)
                
    
        except Exception as e:
            print("Error while processing {}: {}".format(layer_name, e))    
    
            
    # Logo in ScreenOverlay
    screen = kml.newscreenoverlay(name='OpenGeoHub')
    screen.icon.href = 'https://opengeohub.org/themes/gavias_edubiz/logo.png'
    screen.overlayxy = simplekml.OverlayXY(x=0, y=0, xunits=simplekml.Units.fraction, yunits=simplekml.Units.fraction)
    screen.screenxy = simplekml.ScreenXY(x=0, y=0,  xunits=simplekml.Units.fraction, yunits=simplekml.Units.fraction)
    # screen.description = link('http://opengeohub.org/about-landgis', 'LandGis')
    
    if output_format=='kmz':
        kml.savekmz(output_kml)
    else:
        kml.save(output_kml)
            
    
    
if __name__=='__main__':
    make_kml('LandGIS.kmz')
    
    # for testing
    # make_kml('LandGIS.kml','kml')
    
