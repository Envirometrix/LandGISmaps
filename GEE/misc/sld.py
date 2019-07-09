
import pandas
import os.path as osp

layer_table_path = 'https://docs.google.com/spreadsheets/d/1ZmFa2R9mfiMxoOOP_ISAF6Ca5QMFJYL54pV-b_4zHTU/export?gid=30363016&format=csv'
layer_table = pandas.read_csv(layer_table_path,sep=',',dtype={'layer_unique_number':str})

r = layer_table.iloc[0]

layer_name = '{}:{}'.format(r.layer_distribution_folder, osp.splitext(r.layer_filename_pattern)[0])

sld_href = 'https://geoserver.opengeohub.org/landgisgeoserver/wms?Service=WMS&Request=GetStyles&layers={}'.format(layer_name)
