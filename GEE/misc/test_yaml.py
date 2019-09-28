#%%
import yaml
from collections import OrderedDict    

class literal(str): pass
def literal_presenter(dumper, data):
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
yaml.add_representer(literal, literal_presenter)
def ordered_dict_presenter(dumper, data):
    return dumper.represent_dict(data.items())
yaml.add_representer(OrderedDict, ordered_dict_presenter)

d_temp = OrderedDict(l=literal('hi\nif x = y:\n print z\n'))
d = OrderedDict(yaml=literal(yaml.dump(d_temp)))
print(yaml.dump(d))
print(yaml.dump(d_temp))

#%%