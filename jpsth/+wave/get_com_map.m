%TODO Error trial
function com_str_=get_com_map(opt)
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
    opt.laser (1,:) char {mustBeMember(opt.laser,{'on','off','any'})} = 'any' % select laser on or laser off trial for AI-opto data
    opt.plot_COM_scheme (1,1) logical = false % plot COM showcase
    opt.savefig (1,1) logical = false % save plots
end
persistent com_str onepath_ delay_ selidx_ decision_ rnd_half_ curve_ type_ criteria_

fprintf('Delay time is: %d seconds \n', opt.delay);

if isempty(onepath_), onepath_='';end
if isempty(com_str) || ~strcmp(opt.onepath, onepath_) || opt.delay~=delay_ || opt.selidx~=selidx_ || opt.decision~=decision_ || opt.rnd_half~=rnd_half_ || opt.curve~=curve_ || opt.type~=type_ || opt.criteria~=criteria_
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
    com_str=struct();
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

        % TODO nonmem,incongruent
%% DPA-LN
        if strcmp(opt.type,'neupix') % calculate TCOM for learning data (no error trials)
            if opt.keep_sust
                mcid1=meta_str.allcid(ismember(meta_str.mem_type.',1:2) & sesssel.' & strcmp(meta_str.reg_tree(2,:),'CTX'));
                mcid2=meta_str.allcid(ismember(meta_str.mem_type.',3:4) & sesssel.' & strcmp(meta_str.reg_tree(2,:),'CTX'));
            else
                mcid1=meta_str.allcid(meta_str.mem_type.'==2 & sesssel.' & strcmp(meta_str.reg_tree(2,:),'CTX'));
                mcid2=meta_str.allcid(meta_str.mem_type.'==4 & sesssel.' & strcmp(meta_str.reg_tree(2,:),'CTX'));
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

            if size(trial,2)==6
                s1sel=find(trial(:,3)==4 & trial(:,6)==opt.delay);
                s2sel=find(trial(:,3)==8 & trial(:,6)==opt.delay);
            else
                s1sel=find(trial(:,5)==4 & trial(:,8)==opt.delay);
                s2sel=find(trial(:,5)==8 & trial(:,8)==opt.delay);
            end

            sess=['s',num2str(sessid)];
%             if sum(trial(:,9))<40,continue;end % meta data obtained from processed welltrained dataset
            if opt.rnd_half
                for ff=["s1a","s2a","s1b","s2b"]
                    com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                end
                if opt.curve
                    for ff=["s1aheat","s2aheat","s1acurve","s2acurve","s1aanticurve","s2aanticurve",...
                            "s1bheat","s2bheat","s1bcurve","s2bcurve","s1banticurve","s2banticurve"]
                        com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                    end
                end
                s1a=randsample(s1sel,floor(numel(s1sel)./2));
                s1b=s1sel(~ismember(s1sel,s1a));
                s2a=randsample(s2sel,floor(numel(s2sel)./2));
                s2b=s2sel(~ismember(s2sel,s2a));
                if nnz(s1a)>2 && nnz(s1b)>2 && nnz(s2a)>2 && nnz(s2b)>2
                    com_str=per_su_process(sess,suid,msel1,fr,s1a,s2a,com_str,'s1a',opt);
                    com_str=per_su_process(sess,suid,msel1,fr,s1b,s2b,com_str,'s1b',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,s2a,s1a,com_str,'s2a',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,s2b,s1b,com_str,'s2b',opt);
                end
            else
                for ff=["s1","s2"]
                    com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                end
                if opt.curve
                    for ff=["s1heat","s2heat","s1curve","s2curve"]
                        com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                    end
                end

                com_str=per_su_process(sess,suid,msel1,fr,s1sel,s2sel,com_str,'s1',opt);
                com_str=per_su_process(sess,suid,msel2,fr,s2sel,s1sel,com_str,'s2',opt);
            end
%% DUAL TASK
        elseif strcmp(opt.type,'dual_task') % calculate TCOM for dual task data
            mcid1=meta_str.allcid(ismember(meta_str.mem_type.',[1 2 5]) & sesssel.' & strcmp(meta_str.reg_tree(2,:),'CTX')); % pref sample 1
            mcid2=meta_str.allcid(ismember(meta_str.mem_type.',[3 4 6]) & sesssel.' & strcmp(meta_str.reg_tree(2,:),'CTX')); % pref sample 2
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
            s1sel=find(trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,end-1)>0 & trial(:,end)>0);
            s2sel=find(trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,end-1)>0 & trial(:,end)>0);
            e1sel=find(trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,end-1)==0);
            e2sel=find(trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,end-1)==0);
%             s1sel=find(trial(:,9)==2 & trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,end-1)>0 & trial(:,end)>0);
%             s2sel=find(trial(:,9)==16 & trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,end-1)>0 & trial(:,end)>0);
%             s3sel=find(trial(:,9)==-1 & trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,end-1)>0 & trial(:,end)>0);
%             s4sel=find(trial(:,9)==2 & trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,end-1)>0 & trial(:,end)>0);
%             s5sel=find(trial(:,9)==16 & trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,end-1)>0 & trial(:,end)>0);
%             s6sel=find(trial(:,9)==-1 & trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,end-1)>0 & trial(:,end)>0);
%             e1sel=find(trial(:,9)==2 & trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,end-1)==0);
%             e2sel=find(trial(:,9)==16 & trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,end-1)==0);
%             e3sel=find(trial(:,9)==-1 & trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,end-1)==0);
%             e4sel=find(trial(:,9)==2 & trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,end-1)==0);
%             e5sel=find(trial(:,9)==16 & trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,end-1)==0);
%             e6sel=find(trial(:,9)==-1 & trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,end-1)==0);
%             % 1/2/3 -> prefer sample 1 | 4/5/6 -> prefer sample 2
            sess=['s',num2str(sessid)];
%             if sum(trial(:,9))<40,continue;end % meta data obtained from processed welltrained dataset
            if opt.rnd_half
%                 for ff=["s1a","s2a","s3a","s4a","s5a","s6a","s1b","s2b","s3b","s4b","s5b","s6b"]
                for ff=["s1a","s2a","s1b","s2b","s1e","s2e"]
                    com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                end
                if opt.curve
                    for ff=["s1aheat","s2aheat","s1acurve","s2acurve",...
                            "s1bheat","s2bheat","s1bcurve","s2bcurve",...
                            "s1eheat","s2eheat","s1ecurve","s2ecurve"]
                        com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                    end
                end
                s1a=randsample(s1sel,floor(numel(s1sel)./2));
%             s1a=s1sel(1:2:end);
                s1b=s1sel(~ismember(s1sel,s1a));

                s2a=randsample(s2sel,floor(numel(s2sel)./2));
%             s2a=s2sel(1:2:end);
                s2b=s2sel(~ismember(s2sel,s2a));
                if nnz(s1a)>2 && nnz(s1b)>2 && nnz(s2a)>2 && nnz(s2b)>2 && nnz(e1sel)>2 && nnz(e2sel)>2
                    com_str=per_su_process(sess,suid,msel1,fr,s1a,s2a,com_str,'s1a',opt);
                    com_str=per_su_process(sess,suid,msel1,fr,s1b,s2b,com_str,'s1b',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,s2a,s1a,com_str,'s2a',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,s2b,s1b,com_str,'s2b',opt);
                    com_str=per_su_process(sess,suid,msel1,fr,e1sel,e2sel,com_str,'s1e',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,e2sel,e1sel,com_str,'s2e',opt);
                end
            else
                for ff=["s1","s2"]
                    com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                end
                if opt.curve
                    for ff=["s1heat","s2heat","s1curve","s2curve"]
                        com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                    end
                end
            
               com_str=per_su_process(sess,suid,msel1,fr,s1sel,s2sel,com_str,'s1',opt);
               com_str=per_su_process(sess,suid,msel2,fr,s2sel,s1sel,com_str,'s2',opt);
            end
%% ODR2AFC w/ error trial
        elseif strcmp(opt.type,'ODR2AFC') % calculate TCOM for mix odor 2AFC data
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
                    mcid1=meta_str.allcid(ismember(meta_str.mem_type.',1:2) & sesssel.'& IsCortex(meta_str.reg_tree(1,:)).' & IsGreyAndLevel7(meta_str.reg_tree(1,:)).');
                    mcid2=meta_str.allcid(ismember(meta_str.mem_type.',3:4) & sesssel.'& IsCortex(meta_str.reg_tree(1,:)).' & IsGreyAndLevel7(meta_str.reg_tree(1,:)).');
                case 'ctx_trans'
                    mcid1=meta_str.allcid(meta_str.mem_type.'==2 & sesssel.' & IsCortex(meta_str.reg_tree(1,:)).' & IsGreyAndLevel7(meta_str.reg_tree(1,:)).'); % L prefer 
                    mcid2=meta_str.allcid(meta_str.mem_type.'==4 & sesssel.' & IsCortex(meta_str.reg_tree(1,:)).' & IsGreyAndLevel7(meta_str.reg_tree(1,:)).'); % R prefer
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
            
            %
            s1sel=find(ismember(trial_Per80(:,5), [4 8 16]) & trial_Per80(:,7)==1); % left correct
            s2sel=find(ismember(trial_Per80(:,5), [12 20 24]) & trial_Per80(:,7)==2); % right correct
            e1sel=find(ismember(trial_Per80(:,5), [4 8 16]) & trial_Per80(:,7)==2); % left error
            e2sel=find(ismember(trial_Per80(:,5), [12 20 24]) & trial_Per80(:,7)==1); % right error

            sess=['s',num2str(sessid)];
%             if sum(trial(:,9))<40,continue;end % meta data obtained from processed welltrained dataset
            if opt.rnd_half
                for ff=["s1a","s2a","s1b","s2b","e1a","e2a","e1b","e2b"]
                    com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                end
                if opt.curve
                    for ff=["s1aheat","s2aheat","s1acurve","s2acurve","s1aanticurve","s2aanticurve",...
                            "s1bheat","s2bheat","s1bcurve","s2bcurve","s1banticurve","s2banticurve",...
                            "e1aheat","e2aheat","e1acurve","e2acurve","e1aanticurve","e2aanticurve",...
                            "e1bheat","e2bheat","e1bcurve","e2bcurve","e1banticurve","e2banticurve"]
                        com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
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
                    com_str=per_su_process(sess,suid,msel1,fr,s1a,s2a,com_str,'s1a',opt);
                    com_str=per_su_process(sess,suid,msel1,fr,s1b,s2b,com_str,'s1b',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,s2a,s1a,com_str,'s2a',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,s2b,s1b,com_str,'s2b',opt);
                    com_str=per_su_process(sess,suid,msel1,fr,e1a,e2a,com_str,'e1a',opt);
                    com_str=per_su_process(sess,suid,msel1,fr,e1b,e2b,com_str,'e1b',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,e2a,e1a,com_str,'e2a',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,e2b,e1b,com_str,'e2b',opt);
                end
            else 
                for ff=["s1","s2","e1","e2"]
                    com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                end
                if opt.curve
                    for ff=["s1heat","s2heat","s1curve","s2curve","e1heat","e2heat","e1curve","e2curve",...
                            "s1anticurve","s2anticurve","e1anticurve","e2anticurve"]
                        com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                    end
                end
            
               com_str=per_su_process(sess,suid,msel1,fr,s1sel,s2sel,com_str,'s1',opt);
               com_str=per_su_process(sess,suid,msel2,fr,s2sel,s1sel,com_str,'s2',opt);
               com_str=per_su_process(sess,suid,msel1,fr,e1sel,e2sel,com_str,'e1',opt);
               com_str=per_su_process(sess,suid,msel2,fr,e2sel,e1sel,com_str,'e2',opt);
            end
            clear fr_new trial_new fr_Per80 trial_Per80
%% AIOPTO
        elseif strcmp(opt.type,'AIOPTO')
            mcid1=meta_str.allcid(ismember(meta_str.mem_type.',[1 2 5]) & sesssel.' & strcmp(meta_str.reg_tree(2,:),'CTX')); % pref sample 1
            mcid2=meta_str.allcid(ismember(meta_str.mem_type.',[3 4 6]) & sesssel.' & strcmp(meta_str.reg_tree(2,:),'CTX')); % pref sample 2
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
            if strcmp(opt.laser,'on')
                s1sel=find(trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,9)>0 & trial(:,end-1)>0 & trial(:,end)>0);
                s2sel=find(trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,9)>0 & trial(:,end-1)>0 & trial(:,end)>0);
                e1sel=find(trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,9)>0 & trial(:,end-1)==0);
                e2sel=find(trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,9)>0 & trial(:,end-1)==0);
            elseif strcmp(opt.laser,'off')
                s1sel=find(trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,9)<0 & trial(:,end-1)>0 & trial(:,end)>0);
                s2sel=find(trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,9)<0 & trial(:,end-1)>0 & trial(:,end)>0);
                e1sel=find(trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,9)<0 & trial(:,end-1)==0);
                e2sel=find(trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,9)<0 & trial(:,end-1)==0);
            else
                s1sel=find(trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,end-1)>0 & trial(:,end)>0);
                s2sel=find(trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,end-1)>0 & trial(:,end)>0);
                e1sel=find(trial(:,5)==4 & trial(:,8)==opt.delay & trial(:,end-1)==0);
                e2sel=find(trial(:,5)==8 & trial(:,8)==opt.delay & trial(:,end-1)==0);
            end
            sess=['s',num2str(sessid)];
%             if sum(trial(:,9))<40,continue;end % meta data obtained from processed welltrained dataset
            if opt.rnd_half
                for ff=["s1a","s2a","s1b","s2b","s1e","s2e"]
                    com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                end
                if opt.curve
                    for ff=["s1aheat","s2aheat","s1acurve","s2acurve","s1aanticurve","s2aanticurve",...
                            "s1bheat","s2bheat","s1bcurve","s2bcurve","s1banticurve","s2banticurve",...
                            "s1eheat","s2eheat","s1ecurve","s2ecurve","s1eanticurve","s2eanticurve"]
                        com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                    end
                end
                s1a=randsample(s1sel,floor(numel(s1sel)./2));
%             s1a=s1sel(1:2:end);
                s1b=s1sel(~ismember(s1sel,s1a));

                s2a=randsample(s2sel,floor(numel(s2sel)./2));
%             s2a=s2sel(1:2:end);
                s2b=s2sel(~ismember(s2sel,s2a));
                if nnz(s1a)>2 && nnz(s1b)>2 && nnz(s2a)>2 && nnz(s2b)>2 && nnz(e1sel)>2 && nnz(e2sel)>2
                    com_str=per_su_process(sess,suid,msel1,fr,s1a,s2a,com_str,'s1a',opt);
                    com_str=per_su_process(sess,suid,msel1,fr,s1b,s2b,com_str,'s1b',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,s2a,s1a,com_str,'s2a',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,s2b,s1b,com_str,'s2b',opt);
                    com_str=per_su_process(sess,suid,msel1,fr,e1sel,e2sel,com_str,'s1e',opt);
                    com_str=per_su_process(sess,suid,msel2,fr,e2sel,e1sel,com_str,'s2e',opt);
                end
            else
                for ff=["s1","s2"]
                    com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                end
                if opt.curve
                    for ff=["s1heat","s2heat","s1curve","s2curve"]
                        com_str.(['s',num2str(sessid)]).(ff)=containers.Map('KeyType','int32','ValueType','any');
                    end
                end
            
               com_str=per_su_process(sess,suid,msel1,fr,s1sel,s2sel,com_str,'s1',opt);
               com_str=per_su_process(sess,suid,msel2,fr,s2sel,s1sel,com_str,'s2',opt);
            end
        end
    end

    %% SAVE Figures
    if opt.savefig
        FolderName = fullfile(homedir,'..','plots');   % Destination plot folder
        FigList = findobj(allchild(0), 'flat', 'Type', 'figure');
        for iFig = 1:length(FigList)
            FigHandle = FigList(iFig);
            FigName = num2str(get(FigHandle, 'Number'));
            set(0, 'CurrentFigure', FigHandle);
            savefig(fullfile(FolderName, ['COM' FigName '.fig']));
        end
    end
end
com_str_=com_str;
delay_ =opt.delay;
selidx_=opt.selidx;
decision_=opt.decision;
rnd_half_=opt.rnd_half;
curve_=opt.curve;
type_=opt.type;
criteria_=opt.criteria;
end


function com_str=per_su_process(sess,suid,msel,fr,pref_sel,nonpref_sel,com_str,samp,opt)
%TODO if decision
%TODO further specify conditions for stats_window
if opt.decision
    stats_window=(opt.delay*4+17):44;
else
    if opt.delay==6 && strcmp(opt.partial,'early3in6') && strcmp(opt.type,'neupix') % DPA WT/LN
        stats_window=17:28;
    elseif opt.delay==6 && strcmp(opt.partial,'late3in6') && strcmp(opt.type,'neupix') % DPA WT/LN
        stats_window=29:40;
    elseif opt.delay==5 && strcmp(opt.partial,'full') && strcmp(opt.type,'ODR2AFC') % ODR2AFC full delay
        stats_window=25:44; 
    elseif opt.delay==5 && strcmp(opt.partial,'partial') && strcmp(opt.type,'ODR2AFC') % ODR2AFC delay last 500ms - response set first 500ms
        stats_window=43:46;
    elseif opt.delay==6 && strcmp(opt.partial,'before') && strcmp(opt.laser,'on') && strcmp(opt.type,'AIOPTO') % AIOPTO 
        stats_window=17:22;
    elseif opt.delay==6 && strcmp(opt.partial,'after') && strcmp(opt.laser,'on') && strcmp(opt.type,'AIOPTO') % AIOPTO
        stats_window=35:40;
    elseif opt.delay==6 && strcmp(opt.partial,'after') && strcmp(opt.laser,'off') && strcmp(opt.type,'AIOPTO') % AIOPTO
        stats_window=35:40;
    else % full delay period
        stats_window=17:(opt.delay*4+16);
        
    end
end
for su=reshape(msel,1,[])
    perfmat=squeeze(fr(pref_sel,su,:));
    npmat=squeeze(fr(nonpref_sel,su,:));
    basemm=mean([mean(perfmat(:,stats_window),1);mean(npmat(:,stats_window),1)]);
    if ~opt.per_sec_stats
        basemm=mean(basemm);
    end
    if ~strcmp(opt.type,'ODR2AFC')
        itimm=mean(fr([pref_sel;nonpref_sel],su,1:12),'all'); % baseline window for full 3s ITI
    else
        itimm=mean(fr([pref_sel;nonpref_sel],su,13:16),'all'); % baseline window
    end
    %TODO compare the effect of smooth
    if strcmp(opt.cell_type,'any_nonmem')
        mm=smooth(squeeze(mean(fr([pref_sel;nonpref_sel],su,:))),5).';
        mm_pref=mm(stats_window)-itimm;
    else
        mm=smooth(squeeze(mean(fr(pref_sel,su,:))),5).';
        mm_pref=mm(stats_window)-basemm;
    end

    if max(mm_pref)<=0,continue;end % work around 6s paritial

    if opt.selidx
        sel_vec=[mean(perfmat,1);mean(npmat,1)];
        sel_idx=(-diff(sel_vec)./sum(sel_vec));
        sel_idx(all(sel_vec==0))=0;
        curve=sel_idx(stats_window);
    elseif contains(opt.cell_type,'any')
        curve=squeeze(mean(fr(pref_sel,su,:))).'-itimm;
        anticurve=squeeze(mean(fr(nonpref_sel,su,:))).'-itimm;
    elseif opt.delay==6 && strcmp(opt.type,'neupix') % full, early or late 6s DPA
        curve=squeeze(mean(fr(pref_sel,su,17:40))).'-basemm;
        anticurve=squeeze(mean(fr(nonpref_sel,su,17:40))).'-basemm;
    elseif opt.delay==6 && strcmp(opt.type,'AIOPTO')
        curve=squeeze(mean(fr(pref_sel,su,35:40))).'-basemm;
        anticurve=squeeze(mean(fr(nonpref_sel,su,35:40))).'-basemm;
    elseif opt.delay==5 && strcmp(opt.type,'ODR2AFC')
        curve=squeeze(mean(fr(pref_sel,su,25:44))).'-basemm;
        anticurve=squeeze(mean(fr(nonpref_sel,su,25:44))).'-basemm;
    else
        curve=mm_pref;
        anticurve=squeeze(mean(fr(nonpref_sel,su,stats_window))).'-basemm;
    end
    mm_pref(mm_pref<0)=0;
    com=sum((1:numel(stats_window)).*mm_pref)./sum(mm_pref);
    if opt.delay==6 && strcmp(opt.partial,'late3in6')
        com=com+12;
    end
    if opt.plot_COM_scheme
        template=[zeros(1,6),0:0.2:1,1:-0.2:0,zeros(1,6)];
        if corr(mm_pref.',template.','type','Pearson')>0.8
            fc_scheme(curve,mm_pref,com)
        end
    end
    com_str.(sess).(samp)(suid(su))=com;
    if opt.curve
        com_str.(sess).([samp,'curve'])(suid(su))=curve;
        if exist('anticurve','var')
            com_str.(sess).([samp,'anticurve'])(suid(su))=anticurve;
        end
        if opt.rnd_half || contains(opt.cell_type,'any') || opt.selidx || contains(opt.partial,'early3in6')
            heatnorm=curve./max(curve);
        else % per_su_showcase
            heatcent=squeeze(fr(pref_sel,su,stats_window))-basemm; % centralized norm. firing rate for heatmap plot
            heatnorm=heatcent./max(abs(heatcent));
            heatnorm(heatnorm<0)=0;
            if size(heatnorm,1)>10
                cc=arrayfun(@(x) min(corrcoef(heatnorm(x,:),curve),[],'all'),1:size(heatnorm,1));
                [~,idx]=sort(cc,'descend');
                heatnorm=heatnorm(idx(1:10),:);
            end
        end
        com_str.(sess).([samp,'heat'])(suid(su))=heatnorm;
    end
end
end


%% for COM scheme illustration
function fc_scheme(curve,mm_pref,com)
        if min(curve)>0
%             close all
            fh=figure('Color','w', 'Position',[32,32,275,225]);
            bar(mm_pref,'k');
            ylabel('Baseline-deduced firing rate w (Hz)')
            set(gca,'XTick',0:4:24,'XTickLabel',0:6)
            xlabel('Time t (0.25 to 6 sec in step of 0.25 sec)')
            xline(com,'--r');
%             keyboard()
%             exportgraphics(gcf(),'COM_illustration.pdf','ContentType','vector')
        end
end


%% markLPerf for AIOPTO data
function [out]=markLPerf(facSeq)
i=40;
facSeq_WT=zeros(length(facSeq),1);
while i<=length(facSeq)
    goodOff=nnz(xor(facSeq(i-39:i,5)==facSeq(i-39:i,6) , facSeq(i-39:i,7)>0));
    if goodOff>=24 %.60 correct rate
        facSeq_WT(i-39:i,1)=1;
    end
    i=i+1;
end
out=[facSeq,facSeq_WT];

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
