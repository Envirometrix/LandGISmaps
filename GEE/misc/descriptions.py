import pandas
import urllib
from bs4 import BeautifulSoup

layer_table_path = 'https://docs.google.com/spreadsheets/d/1ZmFa2R9mfiMxoOOP_ISAF6Ca5QMFJYL54pV-b_4zHTU/export?gid=30363016&format=csv'
layer_table = pandas.read_csv(layer_table_path,sep=',',dtype={'layer_unique_number':str})
# Only public layers
layer_table = layer_table.loc[layer_table.layer_public_download==1]

#%%
#def layer_description(row):
lun = '1.1'
row = layer_table.loc[layer_table.layer_unique_number==lun].iloc[0]
url = row.layer_download_url

ret = ""
srchtml = urllib.request.urlopen(url).read().decode('utf8')
#%%

src = BeautifulSoup(srchtml,'html.parser')
dst = BeautifulSoup()

h1 = src.h1
rest = list(h1.next_siblings)
dst.append(h1)
# Title
for t in rest:
    if type(t).__name__ == 'Tag':
        if 'panel' in t.get('class',[]):
            break
        if 'alert' in t.get('class',[]):
            break        
        if len(t.find_all('img',class_='inline-orcid'))>0:            
            continue
    
    dst.append(t)

ret = dst.prettify()
#print(ret)
open(r'tmp\desc.html','wt').write(ret)    
#%%
