function [spkID_,spkTS_,trials_,SU_id_,folder_,FT_SPIKE_]=getSPKID_TS(fidx,opt)
arguments
    fidx (1,1) double {mustBeInteger,mustBeGreaterThanOrEqual(fidx,1)}
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','dual_task','ODR2AFC','VDPAP'})}='neupix'
    opt.keep_trial (1,1) logical = false
    opt.suids (:,1) double = []
    opt.only_delay (1,1) logical = false
    opt.starts (1,1) {mustBeNumeric} = -3   % starting time limit (FR) in seconds
    opt.ends (1,1) {mustBeNumeric} = 11   % end time limit (FR) in seconds
    opt.delay (1,1) double = 6 % delay duration in seconds
end

persistent spkID spkTS trials SU_id folder fidx_ criteria_ FT_SPIKE keep_trial_ only_delay_

if isempty(fidx_)...
        || fidx ~= fidx_ ...
        || ~strcmp(criteria_,opt.criteria) ...
        || opt.keep_trial~=keep_trial_ ...
        || ~isequal(opt.suids,SU_id)...
        || ~opt.only_delay~=only_delay_
    homedir=ephys.util.getHomedir('dtype',opt.type,'type','raw');
    folder=replace(ephys.sessid2path(fidx,'criteria',opt.criteria,'type',opt.type),'\',filesep());
    fpath=dir(fullfile(homedir,folder,'*','FR_All_sess.hdf5'));
    trials=h5read(fullfile(fpath.folder,'FR_All_sess.hdf5'),'/Trials');
    if isempty(opt.suids)
        SU_id=h5read(fullfile(fpath.folder,'FR_All_sess.hdf5'),'/SU_id');
        if strcmp(opt.type, 'dual_task'), SU_id=double(SU_id+fidx*100000); end % dual task data modification
    else
        SU_id=opt.suids;
    end
    %     FR_All=h5read(fullfile(fpath.folder,'FR_All_1000.hdf5'),'/FR_All');
    spkID=[];spkTS=[];
    
    %% Behavior performance parameter controlled data retrival
    if (numel(SU_id)<2) ...
            || (strcmp(opt.criteria,'WT') && sum(trials(:,end-1))<40) ...  % apply well-trained criteria
            || (strcmp(opt.criteria,'Learning') && ~strcmp(opt.type,'neupix') && sum(trials(:,end-1))>=40) ... 
            || (strcmp(opt.criteria,'Learning') && strcmp(opt.type,'neupix') && length(trials)<40) % for DPA learning data use all trials
        disp('Did not meet criteria');
        spkID_=[];spkTS_=[];trials_=trials;SU_id_=SU_id;folder_=folder;return;
    end
    
    cstr=h5info(fullfile(fpath.folder,'spike_info.hdf5')); % probe for available probes
    for prb=1:size(cstr.Groups,1) % concatenate same session data for cross probe function coupling
        prbName=cstr.Groups(prb).Name;
        spkID=cat(1,spkID,h5read(fullfile(fpath.folder,'spike_info.hdf5'),[prbName,'/clusters']));
        spkTS=cat(1,spkTS,h5read(fullfile(fpath.folder,'spike_info.hdf5'),[prbName,'/times']));
    end
    
%     spkID=double(spkID+fidx*100000); % dual task data modification
    susel=ismember(spkID,SU_id); % data cleaning by FR and contam rate criteria
    %TODO optional further cleaning by waveform
    spkID=double(spkID(susel));
    spkTS=double(spkTS(susel));
    
    if ~opt.keep_trial
        FT_SPIKE=[];
    else
        ephys.util.dependency('ft',true,'buz',false); % data path and lib path dependency
        [G,ID]=findgroups(spkID);
        SP=splitapply(@(x) {x}, spkTS, G);
        FT_SPIKE=struct();
        FT_SPIKE.label=arrayfun(@(x) num2str(x),SU_id,'UniformOutput',false);
        FT_SPIKE.timestamp=SP(ismember(ID,SU_id));
        sps=30000;
        cfg=struct();
        if opt.only_delay
            cfg.trl=[trials(:,1)+sps,trials(:,1)+(1+opt.delay)*sps,zeros(size(trials,1),1),trials];
        else
            cfg.trl=[trials(:,1)+opt.starts*sps,trials(:,1)+opt.ends*sps,zeros(size(trials,1),1)+opt.starts*sps,trials];
        end

        cfg.trlunit='timestamps';
        cfg.timestampspersecond=sps;
        FT_SPIKE=ft_spike_maketrials(cfg,FT_SPIKE);
    end
end

spkID_=spkID;
spkTS_=spkTS;
trials_=trials;
SU_id_=SU_id;
folder_=folder;
FT_SPIKE_=FT_SPIKE;
fidx_=fidx;
criteria_=opt.criteria;
keep_trial_=opt.keep_trial;
only_delay_=opt.only_delay;

end
