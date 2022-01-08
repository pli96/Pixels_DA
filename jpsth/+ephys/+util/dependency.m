
function dependency(opt)
arguments
    opt.buz (1,1) logical = true;
    opt.ft (1,1) logical = true;
end
if ispc
    if opt.buz
        addpath('K:\Lib\buzcode\buzcode\io')
        addpath('K:\Lib\buzcode\buzcode\utilities\')
        addpath('K:\Lib\buzcode\buzcode\analysis\spikes\correlation\')
        addpath('K:\Lib\buzcode\buzcode\analysis\spikes\functionalConnectionIdentification\')
        addpath('K:\Lib\buzcode\buzcode\visualization\')
        addpath('K:\Lib\buzcode\buzcode\externalPackages\FMAToolbox\General\');
        addpath('K:\Lib\buzcode\buzcode\externalPackages\FMAToolbox\Helpers\');
    end
    if opt.ft
        addpath(fullfile('K:','Lib','npy-matlab-master','npy-matlab'))
        addpath(fullfile('K:','Lib','fieldtrip-20200320'))
        ft_defaults
    end
else
    if opt.buz
        addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/buzcode/io')
        addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/buzcode/utilities/')
        addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/buzcode/analysis/spikes/correlation/')
        addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/buzcode/analysis/spikes/functionalConnectionIdentification/')
        addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/buzcode/visualization/')
        addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/buzcode/externalPackages/FMAToolbox/General/');
        addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/buzcode/externalPackages/FMAToolbox/Helpers/');
    end
    if opt.ft
        addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/npy-matlab/npy-matlab')
        addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/fieldtrip-master')
        ft_defaults
    end
end
