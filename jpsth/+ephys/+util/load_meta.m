%TODO Waveform based SU filter

function out=load_meta(opt)
arguments
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','ODR2AFC','dual_task','VDPAP'})}='neupix'
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
    opt.filter_waveform (1,1)
    opt.delay (1,1) double = 6
end
persistent meta_str currtype criteria

fprintf('Delay time is: %d seconds \n', opt.delay);

if isempty(meta_str) || ~strcmp(opt.type,currtype) || ~strcmp(opt.criteria,criteria)
    homedir=ephys.util.getHomedir('dtype', opt.type);
    if strcmp(opt.type,'neupix') || strcmp(opt.type,'MY')
        if ~strcmp(opt.criteria,'Learning')
            fpath=fullfile(homedir,sprintf('transient_%d.hdf5',opt.delay)); % File generated from ~/neuropixel/code/per_sec/per_sec_stats.py
            meta_str.trial_counts=h5read(fpath,'/trial_counts');
            meta_str.wrs_p=h5read(fpath,'/wrs_p');
            meta_str.selec=h5read(fpath,'/selectivity');
            meta_str.allpath=deblank(h5read(fpath,'/path'));
            meta_str.allcid=h5read(fpath,'/cluster_id');
            meta_str.reg_tree=deblank(h5read(fpath,'/reg_tree'));
            meta_str.good_waveform=h5read(fpath,'/wf_good');
            [meta_str.mem_type,meta_str.per_bin]=ephys.get_mem_type(meta_str.wrs_p,meta_str.selec);
            currtype=opt.type;
        else
            fpath=fullfile(homedir,'transientLN_6_sum.hdf5');
            ccftree=deblank(h5read(fpath,'/reg_tree'));
            meta_str.reg_tree=ccftree';
            HEM=h5read(fullfile(homedir,sprintf('selectivity%d_LN.hdf5',opt.delay)),sprintf('/transient%d',opt.delay));
            HEM=HEM';
            meta_str.mem_type=hem2memtype(HEM,opt.delay);
            fullpath=deblank(h5read(fpath,'/path'));
            fullpath=split(fullpath,'\');
            meta_str.allpath=fullpath(:,3);
            meta_str.allcid=h5read(fpath,'/cluster_id');
            meta_str.good_waveform=h5read(fpath,'/wf_good');
            meta_str.per_bin=h5read(fullfile(homedir,sprintf('selectivity%d_LN.hdf5',opt.delay)),sprintf('/transient%d',opt.delay));
            currtype=opt.type;
        end

    elseif strcmp(opt.type,'ODR2AFC')
        info=load(fullfile(homedir,'InfoToLPY.mat'));
        reg=strrep(info.reg,'Unlabeled','');
        meta_str.reg_tree=reg';
        meta_str.allcid=info.cluster_id;
        fullpath=deblank(info.path);
        meta_str.allpath=regexp(fullpath,'.*(?=\\.*)','match','once');
        ZHA=info.sus_trans';
        meta_str.mem_type=zha2memtype(ZHA);
        currtype=opt.type;

    elseif strcmp(opt.type,'dual_task')
        % Separate by distractor
%         ccftree=regexp(h5read(fullfile(homedir,'Selectivity_0925.hdf5'),'/reg'),'(\w|\\|-)*','match','once');
%         meta_str.reg_tree=ccftree(3:8,:);
%         trial_type=["distractorNo","distractorGo","distractorNoGo"];
%         for typeID=1:3
%             Pvalue=h5read(fullfile(homedir,'Selectivity_0925.hdf5'),sprintf('/Pvalue_%s',trial_type(typeID)));
%             meta_str.mem_type(:,typeID)=distractor2mem(Pvalue);
%         end
%         meta_str.allcid=h5read(fullfile(homedir,'Selectivity_0925.hdf5'),'/cluster_id');
%         meta_str.allpath=regexp(h5read(fullfile(homedir,'Selectivity_0925.hdf5'),'/path'),'(\w|\\|-)*','match','once');
%         currtype=opt.type;

        % Separate by sample
%         fpath=fullfile(homedir,'Selectivity_0907.hdf5');
%         ccftree=deblank(h5read(fpath,'/reg'));
%         ccftree=ccftree';
%         meta_str.reg_tree=ccftree(3:8,:);
%         HEM=h5read(fpath,'/sust_trans_noPermutaion');
%         HEM=HEM';
%         meta_str.mem_type=hem2memtype(HEM,opt.delay);
%         fullpath=deblank(h5read(fpath,'/path'));
%         meta_str.allpath=regexp(fullpath,'.*(?=\\.*)','match','once');
%         meta_str.allcid=h5read(fpath,'/cluster_id');
%         currtype=opt.type;

        % Separate by both sample & distractor
        fpath=fullfile(homedir,'Selectivity_1108.hdf5');
        ccftree=deblank(h5read(fpath,'/reg'));
        ccftree=ccftree';
        meta_str.reg_tree=ccftree(3:8,:);
        fullpath=deblank(h5read(fpath,'/path'));
        meta_str.allpath=regexp(fullpath,'.*(?=\\.*)','match','once');
        meta_str.allcid=h5read(fpath,'/cluster_id');
        HEM=h5read(fpath,'/sust_trans_noPermutaion');
        HEM=HEM';
        meta_str.mem_type=distractorNEW(HEM);
        currtype=opt.type;
    else
        ccftree=deblank(h5read('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/AI-opto/xcorr/Selectivity_AIopto_0419.hdf5','/reg'));
        meta_str.reg_tree=ccftree(3:8,:);
        meta_str.mem_type=hem2memtype(h5read('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/AI-opto/xcorr/Selectivity_AIopto_0419.hdf5','/sus_trans_noPermutaion'));
        fullpath=deblank(h5read('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/AI-opto/xcorr/Selectivity_AIopto_0419.hdf5','/path'));
        meta_str.allpath=regexp(fullpath,'.*(?=\\.*)','match','once');
        meta_str.allcid=h5read('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/AI-opto/xcorr/Selectivity_AIopto_0419.hdf5','/cluster_id');
        currtype=opt.type;
    end
    criteria=opt.criteria;
end
out=meta_str;
out.sess=cellfun(@(x) ephys.path2sessid(x,'type',opt.type,'criteria',opt.criteria),out.allpath);
end

function memtype=hem2memtype(HEM,delay)
% 0=NM,1=S1 sust, 2=S1 trans, 3=S2 sust, 4=S2 trans,-1=switched
delay_pref=max(HEM(end-delay+1:end,:));
memtype=zeros(size(HEM,2),1);
memtype(HEM(1,:)==1 & delay_pref==1)=1;
memtype(HEM(1,:)==1 & delay_pref==2)=3;

memtype(HEM(2,:)==1 & delay_pref==1)=2;
memtype(HEM(2,:)==1 & delay_pref==2)=4;

memtype(HEM(4,:)~=0)=-1;
end

function memtype=distractorNEW(HEM)
% 0=NM,1=D1, 2=S1, 3=D2, 4=S2, 5=SD1, 6=SD2
memtype=zeros(size(HEM,2),1);
delay_pref_distractor=max(HEM(5:12,:));
delay_pref_sample=max(HEM(13:20,:));

memtype(HEM(2,:)==1 & delay_pref_distractor==1)=1;
memtype(HEM(2,:)==1 & delay_pref_distractor==2)=3;

memtype(HEM(2,:)==3 & delay_pref_distractor==1)=1;
memtype(HEM(2,:)==3 & delay_pref_distractor==2)=3;

memtype(HEM(2,:)==2 & delay_pref_sample==1)=2;
memtype(HEM(2,:)==2 & delay_pref_sample==2)=4;

memtype(HEM(2,:)==3 & delay_pref_sample==1)=2;
memtype(HEM(2,:)==3 & delay_pref_sample==2)=4;

memtype(HEM(2,:)==3 & delay_pref_distractor==1 & delay_pref_sample==1)=5;
memtype(HEM(2,:)==3 & delay_pref_distractor==2 & delay_pref_sample==2)=6;

end

function memtype=zha2memtype(ZHA)
% 0=NM,1=L sust, 2=L trans, 3=R sust, 4=R trans,-1=switched
delay_period=ZHA(7:11,:);
memtype=zeros(size(ZHA,2),1);
memtype(sum(delay_period,1)==5 & all(delay_period(:,:)~=2) & all(delay_period(:,:)~=0))=1;
memtype(sum(delay_period,1)==10 & all(delay_period(:,:)~=1) & all(delay_period(:,:)~=0))=3;

memtype(sum(delay_period(:,:)==1)<5 & any(delay_period(:,:)==1) & all(delay_period(:,:)~=2))=2;
memtype(sum(delay_period(:,:)==2)<5 & any(delay_period(:,:)==2) & all(delay_period(:,:)~=1))=4;

memtype(any(delay_period(:,:)==1) & any(delay_period(:,:)==2))=-1;
end

function memtype=distractor2mem(Pvalue)
% 0=NM,1=sust, 2=d1/d2/d3 trans
memtype=zeros(size(Pvalue,1),1);
memtype(all(abs(Pvalue(:,3:4))<0.05/2,2) & all(abs(Pvalue(:,6:7))<0.05/2,2) & all(abs(Pvalue(:,10))<0.05/2,2))=1;
memtype(any(abs(Pvalue(:,3:4))<0.05/2,2) | any(abs(Pvalue(:,6:7))<0.05/2,2) | any(abs(Pvalue(:,10))<0.05/2,2))=2;
end


% Temporary script for waveform sanity check
% meta=ephys.util.load_meta();
% upath=unique(meta.allpath);
% 
% for ii=1:numel(upath)
%     sesssel=strcmp(meta.allpath,upath{ii});
%     wf_good_rate=nnz(meta.good_waveform(sesssel))./nnz(sesssel);
%     rate_stats(ii)=wf_good_rate;
%     fprintf('%d, %.2f, %s\n',ii,wf_good_rate,upath{ii});
% end
