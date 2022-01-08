
%% This script is responsible for generating following files:
% session_list.mat | session names
% spike_info.hdf5 | cluster id & spike times per session (time alignment)
% FR_All_*.hdf5 | FR_All & SU_id & Trials & WF_good per session w/ different bin sizes

%% external lib dependency
addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/npy-matlab/npy-matlab/')
addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/fieldtrip-master')
addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/jpsth/')



%% Input parameters
opt.rootdir=lwd; % DataSum directory
opt.FR_th=1.0;
opt.starts=-3; % starting time window for calculating FR (pre sample)
opt.ends=11; % ending time window for calculating FR (post sample)


%% CREATE session_list
flist=dir(fullfile(opt.rootdir,'**','events.hdf5'));
session=[];
for i=1:size(flist,1)
    session{i,1} = regexp(flist(i).folder,'(?<=DataSum/)(.*)(?=/)','match','once');
end
session=unique(session);
save(fullfile(opt.rootdir, '..', sprintf('session_list.mat')),'session')




%% Time Alignment 

% DISCRIPTION OF spike_info.hdf5

% /imec*/times : time points after correct
% /imec*/clusters : cluster ID corresponding to the times in /imec*/times
%
% PRINCIPLE:
% using behavioural time point file events.hdf5 in referenceRoute as
% reference time aiming to make corrected behavioural time point equal 
% to the reference time.
%
% NOTICE: Library of npy-matlbab need to be added
% different events.hdf5 file may have differenct trial amounts.

% referenceRoute='/OceanStor100D/home/lichengyu_lab/../DataSum/..';
% % the folder of reference imec recording system, using to index events file.
% unCorrectRoute='/OceanStor100D/home/lichengyu_lab/../DataSum/..';
% % the folder for file need to be corrected
% saveRoute='/OceanStor100D/home/lichengyu_lab/../DataSum/..';
% % folder that save the correct file - spike_info.hdf5


% Find events with minimal trials as reference | Generate spike_info.hdf5

routeinfo = dir(fullfile(lwd,'*'));
SSroute=[];
for routeindex=3:size(routeinfo,1)
    route1=fullfile(routeinfo(routeindex,1).folder,routeinfo(routeindex,1).name);
    if contains(route1,'M81_6_learning_20200909_g0') % problematic session
        continue;
    end
    route1info=dir(route1);
    ii = 0;
    standardroute={};
    for i=3:size(route1info,1)
        if contains(route1info(i,1).name,'cleaned')
            ii=ii+1;
            standardroute{ii,1}=fullfile(route1info(i,1).folder,route1info(i,1).name);
        end
    end
    imecEvt = [];
    if ii >= 2
        for i = 1:ii
            if contains(standardroute{i,1},'imec')
                imecEvt = [imecEvt;str2num(standardroute{i,1}(1,strfind(standardroute{i,1},'imec')+4)),length(h5read(fullfile(standardroute{i,1},'events.hdf5'),'/trials'))];
                if exist(fullfile(standardroute{i,1},'spike_info.hdf5'),'file')
                    delete(fullfile(standardroute{i,1},'spike_info.hdf5'));
                end
            end
        end
        [~,index]=sort(imecEvt(:,2));
        referenceRoute=standardroute{index(1),1};
        saveRoute=referenceRoute;
        unCorrectRoute=standardroute(index(2:end),1);
        timealignmentL(referenceRoute, unCorrectRoute, saveRoute);
        saveRoute=[deblank(saveRoute),'/spike_info.hdf5'];
        SSroute=[SSroute;{saveRoute}];
    else
        % Generate spike_info.hdf5 for single probe session 
        referenceRoute=standardroute{1,1};
        saveRoute=referenceRoute;
        unCorrectRoute=referenceRoute;
        timealignmentL(referenceRoute, unCorrectRoute, saveRoute);
        saveRoute=[deblank(saveRoute),'/spike_info.hdf5'];
        SSroute=[SSroute;{saveRoute}];
        continue
    end
end



%% Calculate firing rate from spike trains | Generate FR_All.hdf5 per session 

ft_defaults
fl=dir(fullfile(lwd,'**','cluster_info.tsv')); 
allBinSize=[1, 0.5, 0.25, 0.1];

for binSize=allBinSize
    ephys.pixFlatFR('binsize',binSize, 'writefile',true, 'rootdir', opt.rootdir,'starts',opt.starts,'ends',opt.ends);
end



%% Functions 

function timealignmentL(referenceRoute, unCorrectRoute, saveRoute)
eventReferenceRoute=fullfile(referenceRoute,'events.hdf5'); 
saveRoute=fullfile(saveRoute,'spike_info.hdf5'); 
if exist(saveRoute,'file')
    delete(saveRoute); 
end
spkTS_reference=double(readNPY(fullfile(referenceRoute,'/spike_times.npy'))); 
imecnum=referenceRoute(1,strfind(referenceRoute,'imec')+4); 
cluster_reference=double(readNPY(fullfile(referenceRoute,'/spike_clusters.npy')))+str2num(imecnum)*10000; 
h5create(saveRoute,['/imec',imecnum,'/times'],size(spkTS_reference));  
h5write(saveRoute,['/imec',imecnum,'/times'],spkTS_reference); 
h5create(saveRoute,['/imec',imecnum,'/clusters'],size(cluster_reference)); 
h5write(saveRoute,['/imec',imecnum,'/clusters'],cluster_reference); 
trials_reference=double(h5read(eventReferenceRoute,'/trials')); 

for i=1:size(unCorrectRoute,1)
    trials=double(h5read(fullfile(unCorrectRoute{i,1},'events.hdf5'),'/trials')); 
    spkTS=double(readNPY(fullfile(unCorrectRoute{i,1},'spike_times.npy'))); 
    spk=[]; % correct spike time stamp 
    imecnum=unCorrectRoute{i,1}(1,strfind(unCorrectRoute{i,1},'imec')+4); 
    tmax=min(size(trials,2),size(trials_reference,2)); 
    for t=1:tmax 
        [~,index]=min(abs(trials_reference(1,:)-trials(1,t))); 
        trials_reference0=trials_reference(1,index); 
        if t==1 
            spk=spkTS(spkTS<trials(1,t+1))-(trials(1,t)-trials_reference0); 
        elseif t<tmax 
            spk=[spk;spkTS(spkTS<trials(1,t+1) & spkTS>=trials(1,t))-(trials(1,t)-trials_reference0)]; 
        else
            spk=[spk;spkTS(spkTS>=trials(1,t))-(trials(1,t)-trials_reference0)];
        end
    end
    cluster=double(readNPY(fullfile(unCorrectRoute{i,1},'spike_clusters.npy')));
    delindex=find(spk<=0);
    spk(delindex,:)=[]; 
    cluster(delindex,:)=[]; 
    cluster=cluster+10000*str2num(imecnum); 
    h5create(saveRoute,['/imec',imecnum,'/times'],size(spk)); 
    h5write(saveRoute,['/imec',imecnum,'/times'],spk); 
    h5create(saveRoute,['/imec',imecnum,'/clusters'],size(cluster));
    h5write(saveRoute,['/imec',imecnum,'/clusters'],cluster);
end
end


