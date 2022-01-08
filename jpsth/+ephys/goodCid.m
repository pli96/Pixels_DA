function cid=goodCid(folder,opt)
arguments
    folder (1,:) char
    opt.FR_th (1,1) double = 1.0
end
fl=dir(fullfile(folder, '*', 'events.hdf5'));
cid=[];
for onefile=fl'
    SU_id=plotOneDir(onefile.folder,opt);
    imecnum=onefile.folder(1,strfind(onefile.folder,'imec')+4);
    SU_id=double(SU_id)+str2num(imecnum)*10000;
    cid=cat(1,cid,SU_id);
end
end


function [cluster_ids]=plotOneDir(rootpath, opt)
sps=30000;
metaf=ls(fullfile(rootpath,'*.meta'));
metaf=deblank(metaf);
fh=fopen(metaf);
ts=textscan(fh,'%s','Delimiter',{'\n'});
nSample=str2double(replace(ts{1}{startsWith(ts{1},'fileSizeBytes')},'fileSizeBytes=',''));
spkNThresh=nSample/385/sps/2*opt.FR_th;
clusterInfo = readtable(fullfile(rootpath,'cluster_info.tsv'),'FileType','text','Delimiter','tab');
waveformGood=strcmp(clusterInfo{:,4},'good');
freqGood=clusterInfo{:,10}>spkNThresh;
cluster_ids = table2array(clusterInfo(waveformGood & freqGood,1));
end