function sums_conn_str=sums_conn(opt)
arguments
    opt.poolsize (1,1) double {mustBeInteger,mustBePositive}= 2
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','ODR2AFC','dual_task','VDPAP'})}='neupix'
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
    opt.prefix (1,:) char = 'BZWT'
    opt.inhibit (1,1) logical = false
end
addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/jpsth')
homedir=ephys.util.getHomedir('dtype',opt.type,'type','sums');
pool = gcp('nocreate');
if isunix && isempty(pool)
    pool=parpool(opt.poolsize);
end
if strcmp(opt.type,'neupix')
    if strcmp(opt.criteria,'Learning')
        fl=dir(fullfile('bzdata',sprintf('%s_BZ_XCORR_duo_f*_Learning.mat',opt.prefix)));
        sfn='sums_conn_learning.mat';
    else
        if ispc
            fl=dir(fullfile('bzdata',sprintf('%s_BZ_XCORR_duo_f*.mat',opt.prefix)));
        elseif isunix
            fl=dir(fullfile('/media/SSD2','bzdata',sprintf('%s_BZ_XCORR_duo_f*.mat',opt.prefix)));
        end
        if opt.inhibit
            sfn='sums_conn_inhibit.mat';
        else
            sfn='sums_conn.mat';
        end
    end
else
    fl=dir(fullfile(homedir,'BZ_XCORR_duo_f*.mat'));
    sfn='sums_conn.mat';
end
tic
if isunix
    futures=parallel.FevalFuture.empty(numel(fl),0);
    for task_idx = 1:numel(fl)
        futures(task_idx) = parfeval(pool,@sum_one,1,fl(task_idx)); % async significant functional coupling map->reduce
    end
    sums_conn_str=fetchOutputs(futures);
elseif ispc
    for task_idx = 1:numel(fl)
        sums_conn_str(task_idx) = sum_one(fl(task_idx)); % async significant functional coupling map->reduce
    end
end
toc
save(fullfile(homedir,'..',sfn),'sums_conn_str')
end

function out=sum_one(f)
arguments
    f (1,1) struct
end

fstr=load(fullfile(f.folder,f.name));
suid=fstr.mono.completeIndex(:,2);
out.sig_con=suid(fstr.mono.sig_con);
out.folder=fstr.folder;
out.ccg_sc=[];
sigccg=cell2mat(arrayfun(@(x) fstr.mono.ccgR(:,fstr.mono.sig_con(x,1),fstr.mono.sig_con(x,2)),...
    1:size(fstr.mono.sig_con,1),'UniformOutput',false));
for i=1:size(fstr.mono.sig_con,1)
    out.qc(i,:)=bz.good_ccg(sigccg(:,i));
    out.ccg_sc=[out.ccg_sc;sigccg(:,i).'];
end
end



