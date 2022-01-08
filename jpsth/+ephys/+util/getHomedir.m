function homedir=getHomedir(opt)
arguments
    opt.type (1,:) char {mustBeMember(opt.type,{'sums','raw'})} = 'sums'
    opt.dtype (1,:) char {mustBeMember(opt.dtype,{'neupix','AIOPTO','MY','dual_task','ODR2AFC'})}='neupix'
    
end
if strcmp(opt.dtype,'neupix') ||  strcmp(opt.dtype,'MY')
    if ispc
        if strcmp(opt.type,'sums')
            homedir = fullfile('K:','code','per_sec');
        elseif strcmp(opt.type,'raw')
            homedir = fullfile('K:','neupix','SPKINFO');
        end
    elseif isunix
        if strcmp(opt.type,'sums')
            homedir = fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel','neupix','xcorr');
        elseif strcmp(opt.type,'raw')
            homedir = fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel','neupix','DataSum');
        end
    end
elseif strcmp(opt.dtype,'dual_task')
    if strcmp(opt.type,'sums')
        homedir = fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel','dual_task','xcorr');
    elseif strcmp(opt.type,'raw')
        homedir = fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel','dual_task','DataSum');
    end
elseif strcmp(opt.dtype,'ODR2AFC')
    if strcmp(opt.type,'sums')
        homedir = fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel','ODR2AFC_90PerOver80','xcorr');
    elseif strcmp(opt.type,'raw')
        homedir = fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel','ODR2AFC_90PerOver80','DataSum');
    end
else
    if ispc
        if strcmp(opt.type,'sums')
            homedir = fullfile('K:','neupix','AIOPTO','META');
        elseif strcmp(opt.type,'raw')
            homedir = fullfile('K:','neupix','AIOPTO','RECDATA');
        end
    elseif isunix
        if strcmp(opt.type,'sums')
            homedir = fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel','AI-opto','xcorr');
        elseif strcmp(opt.type,'raw')
            homedir = fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel','AI-opto','DataSum');
        end
    end
    
end
