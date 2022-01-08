function norm_fr_=get_norm_fr_map(opt)
arguments
    opt.onepath (1,:) char = '' % process one session under the given non-empty path
    opt.curve (1,1) logical = false % Norm. FR curve
    opt.per_sec_stats (1,1) logical = false % calculate COM using per-second mean as basis for normalized firing rate, default is coss-delay mean
    opt.decision (1,1) logical = false % return statistics of decision period, default is delay period
    opt.rnd_half (1,1) logical = false % for bootstrap variance test
    opt.keep_sust (1,1) logical = false % use sustained coding neuron
    opt.selidx (1,1) logical = false % calculate COM of selectivity index
    opt.cell_type (1,:) char {mustBeMember(opt.cell_type,{'any_s1','any_s2','any_nonmem','ctx_sel','ctx_trans'})} = 'ctx_trans' % select (sub) populations
    opt.delay (1,1) double = 6 % delay duration
    opt.partial (1,:) char {mustBeMember(opt.partial,{'full','early3in6','late3in6','partial','before','after'})}='full' % for TCOM correlation between 3s and 6s trials
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','ODR2AFC','dual_task','VDPAP'})}='neupix'
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
end
persistent norm_fr onepath_ delay_ selidx_ decision_ rnd_half_ curve_ type_ criteria_

if isempty(onepath_), onepath_='';end
if isempty(norm_fr) || ~strcmp(opt.onepath, onepath_) || opt.delay~=delay_ || opt.selidx~=selidx_ || opt.decision~=decision_ || opt.rnd_half~=rnd_half_ || opt.curve~=curve_ || opt.type~=type_ || opt.criteria~=criteria_
    homedir=ephys.util.getHomedir('dtype',opt.type,'type','raw'); % ~/DataSum directory
    if ~strcmp(opt.type,'ODR2AFC')
        meta_str=ephys.util.load_meta('type',opt.type,'criteria',opt.criteria,'delay',opt.delay);
    elseif strcmp(opt.type,'ODR2AFC') && strcmp(opt.partial,'full')
        load(fullfile(homedir,'..','xcorr','deleted_meta.mat'),'meta');
        meta_str=meta;
    elseif strcmp(opt.type,'ODR2AFC') && strcmp(opt.partial,'partial')
        load(fullfile(homedir,'..','xcorr','meta_43to46.mat'),'meta_43to46');
        meta_str=meta_43to46;
    end
    fl=dir(fullfile(homedir,'**','FR_All_250.hdf5'));
    norm_fr=struct();
    for ii=1:size(fl,1)
        if strlength(opt.onepath)==0
            dpath=regexp(fl(ii).folder,'(?<=DataSum/)(.*)(?=/)','match','once'); 
            fpath=fullfile(fl(ii).folder,fl(ii).name);
        else
            dpath=regexp(opt.onepath,'(?<=DataSum/).*','match','once');
            filepath=dir(fullfile(opt.onepath,'*','FR_All_250.hdf5'));
            fpath=fullfile(filepath.folder,filepath.name);
        end
        fpath=replace(fpath,'\',filesep());
        pc_stem=replace(dpath,'/','\');
        sesssel=startsWith(meta_str.allpath,pc_stem);
        if ~any(sesssel), continue;end
        fr=h5read(fpath,'/FR_All');
        if strcmp(opt.type,'neupix') || strcmp(opt.type,'AIOPTO'), fr=permute(fr,[1 3 2]); end % DPA-LN / AIOPTO data modification
        trial=h5read(fpath,'/Trials');
        if strcmp(opt.type,'AIOPTO'), trial=markLPerf(trial); end % AIOPTO mark LN/WT 
        suid=h5read(fpath,'/SU_id');
        if strcmp(opt.type, 'dual_task'), suid=suid+ii*100000; end % dual task data modification

        if strcmp(opt.type,'ODR2AFC')
            switch opt.cell_type
                case 'any_s1'
                    mcid1=meta_str.allcid(ismember(meta_str.mem_type.',1:2) & sesssel.'& IsCortex(meta_str.reg_tree(1,:)).' & IsGreyAndLevel7(meta_str.reg_tree(1,:)).');
                    mcid2=[];
                case 'any_s2'
                    mcid1=[];
                    mcid2=meta_str.allcid(ismember(meta_str.mem_type.',3:4) & sesssel.'& IsCortex(meta_str.reg_tree(1,:)).' & IsGreyAndLevel7(meta_str.reg_tree(1,:)).');
                case 'any_nonmem'
                    mcid1=meta_str.allcid(meta_str.mem_type.'==0 & sesssel.'& IsCortex(meta_str.reg_tree(1,:)).' & IsGreyAndLevel7(meta_str.reg_tree(1,:)).');
                    mcid2=[];
                case 'ctx_sel'
                    mcid1=meta_str.allcid(ismember(meta_str.mem_type.',1:2) & sesssel.'& IsThirteen(meta_str.reg_tree(1,:)).');
                    mcid2=meta_str.allcid(ismember(meta_str.mem_type.',3:4) & sesssel.'& IsThirteen(meta_str.reg_tree(1,:)).');
                case 'ctx_trans'
                    mcid1=meta_str.allcid(meta_str.mem_type.'==2 & sesssel.' & IsCortex(meta_str.reg_tree(1,:)).' & IsGreyAndLevel7(meta_str.reg_tree(1,:)).'); % L prefer 
                    mcid2=meta_str.allcid(meta_str.mem_type.'==4 & sesssel.' & IsCortex(meta_str.reg_tree(1,:)).' & IsGreyAndLevel7(meta_str.reg_tree(1,:)).'); % R prefer
            end
        end
            msel1=find(ismember(suid,mcid1));
            msel2=find(ismember(suid,mcid2));
            if isempty(msel1) && isempty(msel2)
                if strlength(opt.onepath)==0
                    continue
                else
                    break
                end
            end
            sessid=ephys.path2sessid(pc_stem,'type',opt.type,'criteria',opt.criteria);
        
            % 因为从fr_250.hdf5 中提取的FR和trial都是原始未经处理的，要挑出PerOver80的
            if strcmp(pc_stem,'M6_20201106_g0') || strcmp(pc_stem,'M6_20201102_g0') || strcmp(pc_stem,'M11_20201031_g1') % for these three recordings, only delete first 29 trials
                fr=fr(30:size(fr,1),:,:);
                trial=trial(30:size(trial,1),:);
            else
                fr=fr(31:size(fr,1),:,:);
                trial=trial(31:size(trial,1),:);
            end
            
            % 首先删除miss trial
            n=1;
            for i=1:size(trial,1)
                if trial(i,7)~=-1
                    trial_new(n,:)=trial(i,:);
                    fr_new(n,:,:)=fr(i,:,:);
                    n=n+1;
                    %else if trial(i,7)==-1
                    % break
                end
            end
            
            % 只留Performance达到80%的session (连续30个Trial达到80%）
            win=30;
            j=1;
            x=1;
            while j <= size(trial_new,1)-29
                temp=trial_new(j:j+29,:);
                count=0;
                for i=1:30
                    if (temp(i,5)==4 & temp(i,7)==1) || (temp(i,5)==8 & temp(i,7)==1) || (temp(i,5)==16 & temp(i,7)==1) ||...
                            (temp(i,5)==12 & temp(i,7)==2) || (temp(i,5)==20 & temp(i,7)==2) || (temp(i,5)==24 & temp(i,7)==2)
                        count=count+1; % number of correct trials
                    end
                end
                
                if count>=24
                    trial_Per80(x:x+29,:)=trial_new(j:j+29,:);
                    fr_Per80(x:x+29,:,:)=fr_new(j:j+29,:,:);
                    x=x+30; %当Per大于80%时，跳到30个trial后再开始；否则，跳到下个trial开始
                    j=j+30;
                else
                    
                    j=j+1;
                end
            end
            
            if size(trial_Per80,1)<90
                warning('trial_Per80 is less than 90 !!!');
            end
            
            % select trials
            s1sel=find(ismember(trial_Per80(:,5), [4 8 16]) & trial_Per80(:,7)==1); % left correct trials
            s2sel=find(ismember(trial_Per80(:,5), [12 20 24]) & trial_Per80(:,7)==2); % right correct trials
            e1sel=find(ismember(trial_Per80(:,5), [4 8 16]) & trial_Per80(:,7)==2); % left error trials
            e2sel=find(ismember(trial_Per80(:,5), [12 20 24]) & trial_Per80(:,7)==1); % right error trials

            sess=['s',num2str(sessid)];
%             if sum(trial(:,9))<40,continue;end % meta data obtained from processed welltrained dataset
            if opt.rnd_half
                for ff=["s1a","s2a","s1b","s2b","e1a","e2a","e1b","e2b"]
                    norm_fr.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                end
                if opt.curve
                    for ff=["s1acurve","s2acurve","s1aanticurve","s2aanticurve",...
                            "s1bcurve","s2bcurve","s1banticurve","s2banticurve",...
                            "e1acurve","e2acurve","e1aanticurve","e2aanticurve",...
                            "e1bcurve","e2bcurve","e1banticurve","e2banticurve"]
                        norm_fr.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                    end
                end

                s1a=randsample(s1sel,floor(numel(s1sel)./2));
                s1b=s1sel(~ismember(s1sel,s1a));

                s2a=randsample(s2sel,floor(numel(s2sel)./2));
                s2b=s2sel(~ismember(s2sel,s2a));

                e1a=randsample(e1sel,floor(numel(e1sel)./2));
                e1b=e1sel(~ismember(e1sel,e1a));

                e2a=randsample(e2sel,floor(numel(e2sel)./2));
                e2b=e2sel(~ismember(e2sel,e2a));

                if nnz(s1a)>2 && nnz(s1b)>2 && nnz(s2a)>2 && nnz(s2b)>2 && nnz(e1a)>2 && nnz(e1b)>2 && nnz(e2a)>2 && nnz(e2b)>2
                    norm_fr=per_su_normFR(sess,suid,msel1,fr_Per80,s1a,s2a,norm_fr,'s1a',opt);
                    norm_fr=per_su_normFR(sess,suid,msel1,fr_Per80,s1b,s2b,norm_fr,'s1b',opt);
                    norm_fr=per_su_normFR(sess,suid,msel2,fr_Per80,s2a,s1a,norm_fr,'s2a',opt);
                    norm_fr=per_su_normFR(sess,suid,msel2,fr_Per80,s2b,s1b,norm_fr,'s2b',opt);
                    norm_fr=per_su_normFR(sess,suid,msel1,fr_Per80,e1a,e2a,norm_fr,'e1a',opt);
                    norm_fr=per_su_normFR(sess,suid,msel1,fr_Per80,e1b,e2b,norm_fr,'e1b',opt);
                    norm_fr=per_su_normFR(sess,suid,msel2,fr_Per80,e2a,e1a,norm_fr,'e2a',opt);
                    norm_fr=per_su_normFR(sess,suid,msel2,fr_Per80,e2b,e1b,norm_fr,'e2b',opt);
                end
            else 
                if opt.curve
                    for ff=["s1curve","s2curve","e1curve","e2curve",...
                            "s1anticurve","s2anticurve","e1anticurve","e2anticurve"]
                        norm_fr.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                    end
                end
               norm_fr=per_su_normFR(sess,suid,msel1,fr_Per80,s1sel,s2sel,norm_fr,'s1',opt);
               norm_fr=per_su_normFR(sess,suid,msel2,fr_Per80,s2sel,s1sel,norm_fr,'s2',opt);
               norm_fr=per_su_normFR(sess,suid,msel1,fr_Per80,e1sel,e2sel,norm_fr,'e1',opt);
               norm_fr=per_su_normFR(sess,suid,msel2,fr_Per80,e2sel,e1sel,norm_fr,'e2',opt);
            end
            clear fr_new trial_new fr_Per80 trial_Per80        
    end
end
norm_fr_=norm_fr;
delay_ =opt.delay;
selidx_=opt.selidx;
decision_=opt.decision;
rnd_half_=opt.rnd_half;
curve_=opt.curve;
type_=opt.type;
criteria_=opt.criteria;
end


%% function To get normalized FR
function norm_fr=per_su_normFR(sess,suid,msel,fr,pref_sel,nonpref_sel,norm_fr,samp,opt)% input raw FR; baseline window; correct trial; error trial;
for su=reshape(msel,1,[])
    if opt.delay==5 && strcmp(opt.partial,'full') && strcmp(opt.type,'ODR2AFC') % ODR2AFC full delay
        stats_window=25:44;
        base_window=25:44;
    end
    % mean & std
    baselineFR=mean(fr(:,su,base_window));
    std=std2(fr(:,su,base_window));
    % preffered & non-preferred FR
    prefmat=squeeze(fr(pref_sel,su,:));
    npmat=squeeze(fr(nonpref_sel,su,:));
    % 
    mm=smooth(squeeze(mean(fr(pref_sel,su,:))),5).';
    mm_pref=mm(stats_window)-baselineFR;
    
    curve=(fr(pref_sel,su,stats_window)-baselineFR)./std;
    anticurve=(fr(nonpref_sel,su,stats_window)-baselineFR)./std;

    if opt.curve
        norm_fr.(sess).([samp,'curve'])(suid(su))=curve;
        if exist('anticurve','var')
            norm_fr.(sess).([samp,'anticurve'])(suid(su))=anticurve;
        end
    end
end
end


function out=IsCortex(input)
load(fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code','align','reg_ccfid_map.mat'));
for i=1:size(input,2)
    if any(strcmp(reg2tree(input{1,i}),'CTX'))
        out(i,1)=1;
    else out(i,1)=0;
    end
end
end


function out=IsGreyAndLevel7(input)
load(fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code','align','reg_ccfid_map.mat'));
for i=1:size(input,2)
    tree=reg2tree(input{1,i});
    if size(tree,2)>=7
        level(i,1)=1;
    else level(i,1)=0;
    end
    %grey matter 567-CH(cerebrum) 343-BS(brain-stem); CTX 属于CH;
    if ismember(['CH'],tree) || ismember(['BS'],tree)
        temp(i,1)=1;
    else temp(i,1)=0;
    end
    if temp(i) == 1 && level(i) == 1 % 要求该pair两个神经元都是grey且都是第七级及以上
        out(i,1)=1;
    else out(i,1)=0;
    end
end
end


function out=IsThirteen(input)
wanted=["ACA" "AI" "AON" "DP" "EPd" "HIP" "ILA" "MO" "ORB" "PIR" "PL" "SS" "TT"];
out=ismember(string(input),wanted);
end



