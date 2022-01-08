# -*- coding: utf-8 -*-
"""
Created on Sun Mar 21 13:47:56 2021

@author: zx
"""

# -*- coding: utf-8 -*-


import shlex
import subprocess
import os

from numpy import split

# import time


def run(command):
    try:
        result = subprocess.check_output(shlex.split(command), stderr=subprocess.STDOUT)
        return 0, result
    except subprocess.CalledProcessError as e:
        return e.returncode, e.output


def runInDir(path, cleaned=False):
    os.chdir(path)
    #    status=1
    #    count=0
    #    while (status!=0):
    #        count+=1
    #        print(count)
    if cleaned:
        status, out = run(
            '/OceanStor100D/home/lichengyu_lab/zhangxiaoxing/MATLABR2020b/bin/matlab -noFigureWindows -batch "lwd=pwd();cleaned=true;run /OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/zxSort3.m"'
        )
    else:
        status, out = run(
            '/OceanStor100D/home/lichengyu_lab/zhangxiaoxing/MATLABR2020b/bin/matlab -noFigureWindows -batch "lwd=pwd();cleaned=false;run /OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/zxSort3.m"'
        )
    print(out)
    
    projectName = path.split('/')[6]

    if status == 0:
        # time.sleep(60)
        cwd = os.getcwd()
        if not cleaned:
            os.chdir(cwd + "_cleaned")
        import sys

        sys.path.insert(1, "/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/")
        # import sync
        import zxPhy
        # import parseDPAFR

        # trials = sync.runsync(projectName)
        zxPhy.runPhy()
        # parseDPAFR.runParse()
    else:
        return out,[]

    if cleaned:
        status, result1 = run(
        '/OceanStor100D/home/lichengyu_lab/zhangxiaoxing/MATLABR2020b/bin/matlab -noFigureWindows -batch "lwd=pwd();cleaned=true;run /OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/zxWaveform3.m"'
        )
    else:
        status, result1 = run(
        '/OceanStor100D/home/lichengyu_lab/zhangxiaoxing/MATLABR2020b/bin/matlab -noFigureWindows -batch "lwd=pwd();cleaned=false;run /OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/zxWaveform3.m"'
        )

    if cleaned:
        status, result2 = run(
        '/OceanStor100D/home/lichengyu_lab/zhangxiaoxing/MATLABR2020b/bin/matlab -noFigureWindows -batch "lwd=pwd();cleaned=true;run /OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/Prepare.m"'
        )
    else:
        status, result2 = run(
        '/OceanStor100D/home/lichengyu_lab/zhangxiaoxing/MATLABR2020b/bin/matlab -noFigureWindows -batch "lwd=pwd();cleaned=false;run /OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/Prepare.m"'
        )

    # return out,trials,result1,result2
    return out,result1,result2



def alignInDir(path, cleaned=False):
    os.chdir(path)

    if cleaned:
        status, out = run(
            '/OceanStor100D/home/lichengyu_lab/zhangxiaoxing/MATLABR2020b/bin/matlab -noFigureWindows -batch "lwd=pwd();cleaned=true;run /OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/preprocess.m"'
        )
    else:
        status, out = run(
            '/OceanStor100D/home/lichengyu_lab/zhangxiaoxing/MATLABR2020b/bin/matlab -noFigureWindows -batch "lwd=pwd();cleaned=false;run /OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/preprocess.m"'
        )
    print(out)

    if status == 0:
        import sys
        sys.path.insert(1, "/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/per_sec/")
        import per_sec_stats_gen
        delay=6
        per_sec_stats_gen.gen_align_files()
        error_files = per_sec_stats_gen.gen_selectivity_stats(delay, debug=False)
    else:
        return (out,[]) 

    return (out,error_files)



def alignInDir_dual(path, cleaned=False):
    os.chdir(path)

    if cleaned:
        status, out = run(
            '/OceanStor100D/home/lichengyu_lab/zhangxiaoxing/MATLABR2020b/bin/matlab -noFigureWindows -batch "lwd=pwd();cleaned=true;run /OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/preprocess.m"'
        )
    else:
        status, out = run(
            '/OceanStor100D/home/lichengyu_lab/zhangxiaoxing/MATLABR2020b/bin/matlab -noFigureWindows -batch "lwd=pwd();cleaned=false;run /OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/sorting/preprocess.m"'
        )
    print(out)
    
    return out
