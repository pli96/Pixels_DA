%% Generate FR_All_*.hdf5 file
function pixFlatFR(opt)
arguments
    opt.binsize (1,1) double = 1.0
    opt.writefile (1,1) logical = false
    opt.rootdir (1,:) char = '/OceanStor100D/home/lichengyu_lab/lipy/neuropixel'    % input DataSum directory
    opt.overwrite (1,1) logical = false
    opt.starts (1,1) {mustBeNumeric} = -3   % starting time limit in seconds
    opt.ends (1,1) {mustBeNumeric} = 11   % end time limit in seconds
end

%% external lib dependency
addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/jpsth')
addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/fieldtrip-master')
ft_defaults

%% constant
sps=30000; % sample per second

%% input from YCY's time-aligned spike file
flist=dir(fullfile(opt.rootdir,'**','spike_info.hdf5'));
for i=1:length(flist)
    fprintf('=== %d of %d ===\n',i,length(flist))
    if isfile(fullfile(flist(i).folder,sprintf('FR_All_%d.hdf5',opt.binsize*1000))) && ~opt.overwrite
        disp(strjoin({'skiped',flist(i).folder}));
        continue
    end
    
    %% per session behavioral data
    trials=h5read(fullfile(flist(i).folder,'events.hdf5'),'/trials')';
    trials=behav.procPerf(trials,'mode','all');
%     trials=h5read(fullfile(flist(i).folder,'events.hdf5'),'/trialsRescued');
%     trials=behav.procPerf_LJWv1(trials,'mode','all');
    if isempty(trials), continue,  end
    
    %% select SUs with low contam rate, high FR and good waveform, for all probes
    cstr=h5info(fullfile(flist(i).folder,flist(i).name));
    sep_path=split(flist(i).folder, '/');
    fr_good=ephys.goodCid(fullfile(opt.rootdir, sep_path{end-1,1})); % Good firing rate
    fr_wf_good=ephys.waveform.goodWaveform(fullfile(opt.rootdir, sep_path{end-1,1}),'presel',fr_good); %Good waveform
    if isempty(fr_wf_good)
        fprintf('Missing good waveform in: \n %s \n',flist(i).folder);
%         keyboard()
%         continue
    end
    spkID=[];spkTS=[];
    for prb=1:size(cstr.Groups,1)
        prbName=cstr.Groups(prb).Name;
        spkID=cat(1,spkID,h5read(fullfile(flist(i).folder,flist(i).name),[prbName,'/clusters']));
        spkTS=cat(1,spkTS,h5read(fullfile(flist(i).folder,flist(i).name),[prbName,'/times']));
    end
    susel=ismember(spkID,fr_good);
    spkID=double(spkID(susel));
    spkTS=double(spkTS(susel));
    suids=unique(spkID);
    
    %% split trials with external lib
    FT_SPIKE=struct();
    
    FT_SPIKE.label=strtrim(cellstr(num2str(suids)));
    FT_SPIKE.timestamp=cell(1,numel(suids));
    for su=1:numel(suids)
        FT_SPIKE.timestamp{su}=spkTS(spkID==suids(su))';
    end
    %  continuous format F T struct file
    cfg=struct();
    cfg.trl=[trials(:,1)+opt.starts*sps,trials(:,1)+opt.ends*sps,zeros(size(trials,1),1)+opt.starts*sps,trials];
    cfg.trlunit='timestamps';
    cfg.timestampspersecond=sps;
    
    FT_SPIKE=ft_spike_maketrials(cfg,FT_SPIKE);
    
    cfg=struct();
    cfg.binsize=opt.binsize;
    cfg.keeptrials='yes';
    FT_PSTH=ft_spike_psth(cfg, FT_SPIKE);
 
    %% export result as file
    if opt.writefile
        FR_File=fullfile(flist(i).folder,sprintf('FR_All_%d.hdf5',opt.binsize*1000));
        if exist(FR_File,'file')
            delete(FR_File)
        end
        h5create(FR_File,'/FR_All',size(FT_PSTH.trial),'Datatype','double')
        h5write(FR_File,'/FR_All',FT_PSTH.trial)
        h5create(FR_File,'/Trials',size(FT_PSTH.trialinfo),'Datatype','double')
        h5write(FR_File,'/Trials',FT_PSTH.trialinfo)
        h5create(FR_File,'/SU_id',size(suids),'Datatype','double')
        h5write(FR_File,'/SU_id',suids)
        h5create(FR_File,'/WF_good',size(suids),'Datatype','int8')
        h5write(FR_File,'/WF_good',int8(ismember(suids,fr_wf_good)))
    else 
        keyboard()% for devp
    end
end
end

