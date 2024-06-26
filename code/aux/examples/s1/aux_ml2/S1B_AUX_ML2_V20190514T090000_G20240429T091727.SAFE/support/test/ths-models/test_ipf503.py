import os
import json
import sys
import numpy as np
from s1tools.sarhspredictor.load_quach_2020_keras_model import load_quach2020_model_v2
from s1tools.sarhspredictor.predict_with_quach2020_on_ocn_using_keras import main_level_1
from logbook import Logger, StreamHandler

StreamHandler(sys.stdout).push_application()

log = Logger('test')
aux_json = os.path.join(os.path.dirname(__file__), "..", "..", "..", "data", "s1b-aux-ml2.json")
with open(aux_json, "r") as fd:
   data = json.load(fd)["Models"]["TotalHS"]
    
ths_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "data", data["Dir"])


def test_quach2020_model_wv2():
    model_filename = os.path.join(ths_path, data["wv2"]["h5"])
    heteroskedastic_2017 = load_quach2020_model_v2(model_filename)
    ff = 's1b-wv2-ocn-vv-20210901t015119-20210901t015122-028498-036693-002.nc'
    ff = os.path.join(os.path.dirname(__file__), ff)
    output_datatset = main_level_1(ff, heteroskedastic_2017, log)
    assert np.allclose(output_datatset['swh'].values, [1.5778441])
    assert np.allclose(output_datatset['swh_uncertainty'].values, [0.17868048])


def test_quach2020_model_wv1():
    model_filename = os.path.join(ths_path, data["wv1"]["h5"])
    heteroskedastic_2017 = load_quach2020_model_v2(model_filename)
    ff = 's1b-wv1-ocn-vv-20190515t001333-20190515t001336-016247-01e941-001.nc'
    ff = os.path.join(os.path.dirname(__file__), ff)
    output_datatset = main_level_1(ff, heteroskedastic_2017, log)
    assert np.allclose(output_datatset['swh'].values, [1.2301074])
    assert np.allclose(output_datatset['swh_uncertainty'].values, [0.3187795])
