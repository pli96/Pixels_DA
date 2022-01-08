# -*- coding: utf-8 -*-
"""
Created on Thu Oct 24 21:56:58 2019

@author: DELL
"""

import os 
import pyKilosort3

outs = [] 
results1 = []
results2 = []
sessions = []

# os.chdir('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/VDPAP/')
homedir = '/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/sorting/'
todoList = []
for root, dirs, files in os.walk(homedir):
    for file in files:
        if file.endswith('.ap.bin'):
            todoList.append(os.path.join(root))

sortedList = []
for root, dirs, files in os.walk(homedir):
    for file in files:
        if file.endswith('params.py'):
            sortedList.append(os.path.join(root))

# input problematic track path here if any
problemTrack = 'M02_20220105_g0_imec3'
# skip sorted tracks
pathList=list(filter(lambda a: a not in sortedList, todoList))
# skip problematic tracks
pathList=[x for x in pathList if problemTrack not in x]

for path in pathList:
    print(path)
#     out, session, result1, result2 = pyKilosort3.runInDir(path,cleaned=True)
    out, result1, result2 = pyKilosort3.runInDir(path,cleaned=True)
    outs.append(out)
#     sessions.append(session)
    results1.append(result1)
    results2.append(result2)

