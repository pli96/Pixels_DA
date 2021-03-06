# -*- coding: utf-8 -*-
"""
Created on Fri Mar 12 08:55:38 2021

@author: Libra
"""

import pandas as pd
import re
import numpy as np


def _get_struct_tree(): #import from Allen CCF v3 file
    tree_file = "/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/allenCCF/structure_tree_safe_2017.csv"
    return pd.read_csv(tree_file,
                          usecols=['id','acronym','depth','structure_id_path',],
                          dtype={'id':'UInt32',
                                 'acronym':'string',
                                 'depth':'UInt8',
                                 'structure_id_path':'string'},
                          index_col='id')


def get_tree_path(regstr): #build up entire region tree from leaf node
    try:
        regidx=_treetbl.iloc[np.where(_treetbl['acronym']==regstr)[0]].index[0]
    except Exception:
        breakpoint()
    reg_depth=_treetbl.loc[regidx,['depth']][0]
    reg_tree_path=_treetbl.loc[regidx,['structure_id_path']][0]
    tree_idces=[int(x) for x in filter(None,reg_tree_path.split(r'/'))][2:]
    tree_str=[_treetbl.loc[x,['acronym']][0] for x in tree_idces]
    return (regidx,reg_depth,tree_idces,tree_str)


# eval during import
_treetbl=_get_struct_tree()