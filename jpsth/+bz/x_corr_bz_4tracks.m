CodePath='/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/';
HomePath='/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/dual_task/';

addpath(fullfile(CodePath,'npy-matlab','npy-matlab'))
addpath(fullfile(CodePath,'xcorr'))
addpath(fullfile(CodePath,'buzcode'))

prefix='1012';
range=[a,b];
load(fullfile(HomePath,'session_list.mat'))

ephys.util.dependency('ft',false);

for i=range(1):range(2)    
    tic
    folder=session{i};  
    disp(folder) 
    if ~isfile(fullfile(HomePath,'xcorr', sprintf('%s_BZ_XCORR_duo_f%d%s.mat',prefix,fidx,suffix)))
        [spkID,spkTS,~,~,folder]=ephys.getSPKID_TS(fidx,'criteria',opt.criteria);
        mono=bz.sortSpikeIDz(spkTS,spkID);
        save(fullfile(HomePath,'xcorr', sprintf('%s_BZ_XCORR_duo_f%d%s.mat',prefix,fidx,suffix)),'mono','-v7.3','folder')
    else
        load(fullfile(HomePath,'xcorr',sprintf('bz%s',prefix),sprintf('BZ_XCORR_duo_f%d.mat',i)),'mono')
    end
    for n=1:size(mono.sig_con,1)
        sig_con{i,1}(n,:)=[mono.completeIndex(mono.sig_con(n,1),2),mono.completeIndex(mono.sig_con(n,2),2)];
    end
    toc
    clear mono
end

save(fullfile(HomePath,sprintf('conn_bz_%d_%d.mat',range(1),range(2))),'sig_con','range')

return






%% Function
function [spkTS,spkId]=pre_process(sessionIdx,Sessionfolder,HomePath)
folder=dir(fullfile(HomePath,'DataSum',Sessionfolder,'*','FR_All_250ms.hdf5'));
trial=h5read(fullfile(folder(1,1).folder,'FR_All_250ms.hdf5'),'/Trials');
cluster_ids=[];
for f=1:size(folder,1)
    cluster_ids_temp=[];
    cluster_ids_temp=h5read(fullfile(folder(f,1).folder,'FR_All_250ms.hdf5'),'/SU_id')+sessionIdx*100000;
    cluster_ids=[cluster_ids;cluster_ids_temp+10000*str2num(regexp(folder(f).folder,'(?<=imec)(\d)','match','once'))];   
end

spkTS=[];
spkId=[];
for f=1:size(folder,1)
    spkId_temp=[];
    spkId_temp=double(readNPY(fullfile(folder(f,1).folder,'spike_clusters.npy'))+sessionIdx*100000);
    spkId=[spkId;spkId_temp+10000*str2num(regexp(folder(f).folder,'(?<=imec)(\d)','match','once'))];
    
    spkTS_temp=[];
    spkTS_temp=double(h5read(fullfile(folder(f,1).folder,'spike_times.hdf5'),'/spkTS'));
    n=folder(f,1).folder;
    spkTS=[spkTS;spkTS_temp];
end
spk_bad=~ismember(spkId,cluster_ids);
spkTS(spk_bad)=[];
spkId(spk_bad)=[];

end


function x_corr_bz(fidx,prefix,opt)
arguments
    fidx (1,1) double
    prefix (1,:) char = 'BZWT'
    opt.debug (1,1) logical = false
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
    opt.negccg (1,1) logical = false
end
ephys.util.dependency('ft',false);
if isfile(sprintf('%s_BZ_XCORR_duo_f%d.mat',prefix,fidx))
    disp('File exist'); if isunix, quit(0); else, return; end
end
disp(fidx);
bz.util.pause(fidx,'xcorrpause');
[spkID,spkTS,~,~,folder]=ephys.getSPKID_TS(fidx,'criteria',opt.criteria);
if isempty(spkID)
    if isunix, quit(0); else, return; end
end
mono=bz.sortSpikeIDz(spkTS,spkID,'negccg',opt.negccg); % adapted from English, Buzsaki, 2017
if opt.debug && false
    bz.util.plotCCG
end
if opt.negccg && strcmp(opt.criteria,'Learning'),   suffix='_Inhibitory_Learning';
elseif opt.negccg,                                  suffix='_Inhibitory';
elseif strcmp(opt.criteria,'Learning'),             suffix='_Learning';
else,                                               suffix='';
end

save(sprintf('%s_BZ_XCORR_duo_f%d%s.mat',prefix,fidx,suffix),'mono','-v7.3','folder')
if isunix, quit(0); else, return; end
end

