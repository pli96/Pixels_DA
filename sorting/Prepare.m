%% WAVEFORM %%
s1s=30000;
FR_Th=1.0;

addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/neuropixel-utils')
addpath(genpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/Kilosort3'))
channelMapFile='/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/neuropixel-utils/map_files/neuropixPhase3B2_kilosortChanMap.mat';
CD=lwd;
fl=dir([CD '/cluster_info.tsv']);

errors=cell(0);

for onefile=fl'
    rootpath=onefile.folder;
    try
        if isfile([rootpath '/waveform.mat'])
            fstr=load([rootpath '/waveform.mat']);
            if size(fstr.waveform,2)==4
                fprintf('Exist file %s, skipped\n\n',fl.folder)
                continue
            end
        end
        disp(rootpath)
        
        tic
        
        metaf=ls(fullfile(rootpath,'*.ap.meta'));
        metaf=deblank(metaf);
        fh=fopen(metaf);
        ts=textscan(fh,'%s','Delimiter',{'\n'});
        nSample=str2double(replace(ts{1}{startsWith(ts{1},'fileSizeBytes')},'fileSizeBytes=',''));
        spkNThresh=nSample/385/s1s/2*FR_Th;
        clusterInfo = readtable(fullfile(rootpath,'cluster_info.tsv'),'FileType','text','Delimiter','tab');
        waveformGood=strcmp(clusterInfo{:,4},'good');
        freqGood=clusterInfo{:,10}>spkNThresh;
        cluster_ids = table2array(clusterInfo(waveformGood & freqGood,1));
        
        if numel(cluster_ids)>0
            waveform=cell(0,4);
            ks=Neuropixel.KiloSortDataset(rootpath,'channelMap',channelMapFile);
            ks.load();
            
            for cidx=1:numel(cluster_ids)
                try
                    snippetSetTet = ks.getWaveformsFromRawData('cluster_ids',cluster_ids(cidx),'num_waveforms', 100, 'best_n_channels', 4, 'car', true, ...
                        'subtractOtherClusters', false,'window', [-30 60]);
                    
                    snippetSetBest = ks.getWaveformsFromRawData('cluster_ids',cluster_ids(cidx),'num_waveforms', 500, 'best_n_channels', 1, 'car', true, ...
                        'subtractOtherClusters', false,'window', [-30 60]);
                    
                    waveform{end+1,1}=rootpath;
                    waveform{end,2}=cluster_ids(cidx);
                    waveform{end,3}=snippetSetTet.data;
                    waveform{end,4}=mean(snippetSetBest.data,3);
                catch ME
                    errors{end+1}=sprintf('%s %d waveform error',onefile.folder,cidx);
                end
                %                 if to_plot
                %                     fh=figure();
                %                     plot(cell2mat(arrayfun(@(x) mean(squeeze(snippetSet.data(x,:,:))'), 1:4,'UniformOutput',false)));
                %                     pause
                %                     close(fh);
                %                 end
            end
        end
        save([rootpath '/waveform.mat'],'waveform');
        toc
    catch ME
        errors{end+1}=onefile.folder;
    end
    
end
missing_disk=cell(0);
all_wfstats=cell(0);

for onefile=fl'  
    rootpath=onefile.folder;
    if ~isfile(fullfile(rootpath,'wf_stats.hdf5'))
        metaf=ls(fullfile(rootpath,'*.ap.meta'));
        metaf=deblank(metaf);
        fh=fopen(metaf);
        ts=textscan(fh,'%s','Delimiter',{'\n'});
        nSample=str2double(replace(ts{1}{startsWith(ts{1},'fileSizeBytes')},'fileSizeBytes=',''));
        spkNThresh=nSample/385/s1s/2*FR_Th;
        clusterInfo = readtable(fullfile(rootpath,'cluster_info.tsv'),'FileType','text','Delimiter','tab');
        waveformGood=strcmp(clusterInfo{:,4},'good');
        freqGood=clusterInfo{:,10}>spkNThresh;
        freq=clusterInfo{:,10}/spkNThresh; %thresh happens to be 1.0 Hz
        cluster_ids = table2array(clusterInfo(waveformGood & freqGood,1));
        if isempty(cluster_ids)
            continue
        end
        wfpath=rootpath;
        if isfile(fullfile(wfpath,'waveform.mat'))
            wf_fstr=load(fullfile(wfpath,'waveform.mat'));
            wf_all=wf_fstr.waveform;
            if numel(wf_all)<4
                continue
            end
            
            folder_wf_stats=[];
            
            for cid=cluster_ids'
                wfidx=find([wf_all{:,2}]==cid);
                if isempty(wfidx)
                    continue
                end
                wfStat=process_wf(wf_all{wfidx,4});
                folder_wf_stats(end+1,:)=[cid,freq(clusterInfo{:,1}==cid),wfStat];
                all_wfstats(end+1,:)={rootpath,folder_wf_stats(end,:)};
            end
            save(fullfile(rootpath,'wf_stats.mat'),'folder_wf_stats');
            syncH5=fullfile(rootpath,'wf_stats.hdf5');
            h5create(syncH5,'/wf',size(folder_wf_stats),'Datatype','double')
            h5write(syncH5,'/wf',folder_wf_stats)
        else
            missing_disk{end+1}=rootpath;
        end
    end
end

%% Transfer sorting result  
sep_path = split(lwd,'/');
savepath = fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel', sep_path{7,1}, 'DataSum');

for onefile=fl'
    rootpath=onefile.folder;
    folder=split(rootpath,'/');
    if ~isfolder(fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
        mkdir(fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']));
    end
    if ~isfolder(fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned'],'.phy'))
        mkdir(fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned'],'.phy'));
    end    
%     copyfile(fullfile(rootpath,'.phy'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned'],'.phy'))
    copyfile(fullfile(rootpath,'*.ap.meta'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
    copyfile(fullfile(rootpath,'cluster_info.tsv'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
%     copyfile(fullfile(rootpath,'events.hdf5'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
%     copyfile(fullfile(rootpath,'selectivity.hdf5'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
    copyfile(fullfile(rootpath,'spike_clusters.npy'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
%     copyfile(fullfile(rootpath,'spike_info'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
    copyfile(fullfile(rootpath,'spike_times.npy'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
%     copyfile(fullfile(rootpath,'su_id2reg.csv'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
%     copyfile(fullfile(rootpath,'wf_stats.hdf5'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
%     copyfile(fullfile(rootpath,'wf_stats.mat'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
    copyfile(fullfile(rootpath,'waveform.mat'),fullfile(savepath,folder{8,1},[folder{9,1},'_cleaned']))
    
end


%%
function out=process_wf(wf)
% Extracellular Spike Waveform Dissociates Four Functionally Distinct Cell Classes in Primate Cortex
% Current Biology 2019 Earl K. Miller,Markus Siegel
% excluded waveforms that satisfied any of three criteria for atypical shape:
% (1) the amplitude of the main trough was smaller than the subsequent positive
% peak (n = 41), (2) the trace was noisy, defined as > = 6 local maxima of magnitude > = 0.01 (n = 38), (3) there was one or more local
% maxima in the period between the main trough and the subsequent peak (n = 35).
    
%criteria 1    
if max(wf)>-min(wf)
    out=[-1,0,0];
    return
end
%criteria 2
[lc_pk,~]=findpeaks(wf,'MinPeakProminence',-0.05*min(wf));
if numel(lc_pk)>=6
    findpeaks(wf,'MinPeakProminence',-0.05*min(wf));
    out=[-2,0,0];
    return
end
%criteria 3
[~,t_ts]=min(wf);
[~,p_ts]=max(wf(t_ts+1:end));
if p_ts>3
    [lc_pk,~]=findpeaks(wf(t_ts:(t_ts+p_ts-1)),'MinPeakProminence',-0.05*min(wf));
end
if isempty(p_ts) || (p_ts<=3) || (~isempty(lc_pk))
    out=[-3,0,0];
    return
end
%trough_peak dist
wf=spline(1:91,wf,1:0.03:91);
scale=max(abs(wf));
wf=wf./scale;
[~,troughTS]=min(wf);
[~,deltaTS]=max(wf((troughTS+1):end));%to late peak

%fwhm
lcross=find(wf<-0.5,1);
rcross=find(wf(troughTS:end)>-0.5,1)+troughTS;
if numel(lcross)==1 && numel(rcross)==1
    fwhm=rcross-lcross;
    out=[0,deltaTS,fwhm];
    return
else
    out=[-4,0,0];
    return
end

end
