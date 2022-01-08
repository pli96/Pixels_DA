function [metas,stats,fwd_rev]=get_fc_coding(opt)
arguments
    opt.keep_trial (1,1) logical = false
    opt.no_shift (1,1) logical = false
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','dual_task','ODR2AFC'})}='neupix'
end
persistent metas_ stats_ fwd_rev_ no_shift
if isempty(metas_) || isempty(stats_) || isempty(fwd_rev_) || no_shift~=opt.no_shift
    sig=bz.load_sig_pair('type',opt.type,'prefix','0910','criteria','WT');
    sess=unique(sig.sess);
    homedir=ephys.util.getHomedir('dtype',opt.type);
    fl=dir(fullfile(homedir,'fcdata','fc_coding_*.mat'));
    % {suids(fci,:),fwd_fc,fwd_fc-mean(fwd_shift,2),fwd_shift,rev_fc,rev_fc-mean(rev_shift,2),rev_shift}
    metas=[];
    stats=[];
    fwd_rev=[];
    for fi=1:numel(fl)
        %     disp(fi);
        fstr=load(fullfile(fl(fi).folder,fl(fi).name));
        sess=fstr.onesess.fidx;
        sesssel=sig.sess==sess;
        ids=sig.suid(sesssel,:);
        mems=sig.mem_type(sesssel,:);
        regs=squeeze(sig.reg(sesssel,5,:));
        roots=squeeze(sig.reg(sesssel,1,:));
        
        if opt.no_shift
            stat_idx=2;
        else
            stat_idx=3;
        end

        if strcmp(opt.type, 'neupix')
            [s1sel,s2sel]=bz.util.ExtractTrial(fstr.onesess.trials,'type','neupix','trials','correct');
            [e1sel,e2sel]=bz.util.ExtractTrial(fstr.onesess.trials,'type','neupix','trials','error');

            for fci=1:size(fstr.onesess.fc,1) %fc idx
            suid1=fstr.onesess.fc{fci,1}(1);
            suid2=fstr.onesess.fc{fci,1}(2);
            fcsel=ids(:,1)==suid1 & ids(:,2)==suid2;
            mem=mems(fcsel,:);
            root=roots(fcsel,:);
            reg=regs(fcsel,:);
            if any(isempty(reg)) || any(reg==0,'all') || ~all(root==567,'all'), continue;end
            pertrl=fstr.onesess.fc{fci,stat_idx}>0;
            metas=[metas;sess,suid1,suid2,mem,reg];
            stats=[stats;mean(fstr.onesess.fc{fci,stat_idx}(s1sel)),mean(fstr.onesess.fc{fci,stat_idx}(s2sel)),...%1,2
                mean(fstr.onesess.fc{fci,stat_idx}(e1sel)),mean(fstr.onesess.fc{fci,stat_idx}(e2sel)),... %3,4
                nnz(pertrl(s1sel))/nnz(s1sel),nnz(pertrl(s2sel))/nnz(s2sel)];
            fwd_rev=[fwd_rev;...
                mean(fstr.onesess.fc{fci,2}(s1sel)>fstr.onesess.fc{fci,5}(s1sel)),...
                mean(fstr.onesess.fc{fci,2}(s2sel)>fstr.onesess.fc{fci,5}(s2sel))];
            end

        elseif strcmp(opt.type, 'dual_task')
            trial_type=["distractorNo-correct","distractorGo-correct","distractorNoGo-correct"...
        ,"distractorNo-error","distractorGo-error","distractorNoGo-error"];
            [sel_no_c1,sel_no_c2]=bz.util.ExtractTrial(fstr.onesess.trials,'task','dual_task','trials',trial_type(1)); % distractorNo-correct
            [sel_go_c1,sel_go_c2]=bz.util.ExtractTrial(fstr.onesess.trials,'task','dual_task','trials',trial_type(2)); % distractorGo-correct
            [sel_ng_c1,sel_ng_c2]=bz.util.ExtractTrial(fstr.onesess.trials,'task','dual_task','trials',trial_type(3)); % distractorNoGo-correct
            [sel_no_e1,sel_no_e2]=bz.util.ExtractTrial(fstr.onesess.trials,'task','dual_task','trials',trial_type(4)); % distractorNo-error
            [sel_go_e1,sel_go_e2]=bz.util.ExtractTrial(fstr.onesess.trials,'task','dual_task','trials',trial_type(5)); % distractorGo-error
            [sel_ng_e1,sel_ng_e2]=bz.util.ExtractTrial(fstr.onesess.trials,'task','dual_task','trials',trial_type(6)); % distractorNoGo-error

            for fci=1:size(fstr.onesess.fc,1) %fc idx
                suid1=fstr.onesess.fc{fci,1}(1);
                suid2=fstr.onesess.fc{fci,1}(2);
                fcsel=ids(:,1)==suid1 & ids(:,2)==suid2;
                mem=mems(fcsel,:);
                root=roots(fcsel,:);
                reg=regs(fcsel,:);
                if any(isempty(reg)) || any(reg==0,'all') || ~all(root==567,'all'), continue;end
                pertrl=fstr.onesess.fc{fci,stat_idx}>0;
                metas=[metas;sess,suid1,suid2,mem,reg];
                stats=[stats;...
                    mean(fstr.onesess.fc{fci,stat_idx}(sel_no_c1)),mean(fstr.onesess.fc{fci,stat_idx}(sel_no_c2)),... % 1,2
                    mean(fstr.onesess.fc{fci,stat_idx}(sel_go_c1)),mean(fstr.onesess.fc{fci,stat_idx}(sel_go_c2)),... % 3,4
                    mean(fstr.onesess.fc{fci,stat_idx}(sel_ng_c1)),mean(fstr.onesess.fc{fci,stat_idx}(sel_ng_c2)),... % 5,6
                    mean(fstr.onesess.fc{fci,stat_idx}(sel_no_e1)),mean(fstr.onesess.fc{fci,stat_idx}(sel_no_e2)),... % 7,8
                    mean(fstr.onesess.fc{fci,stat_idx}(sel_go_e1)),mean(fstr.onesess.fc{fci,stat_idx}(sel_go_e2)),... % 9,10
                    mean(fstr.onesess.fc{fci,stat_idx}(sel_ng_e1)),mean(fstr.onesess.fc{fci,stat_idx}(sel_ng_e2)),... % 11,12
                    nnz(pertrl(sel_no_c1))/nnz(sel_no_c1),...
                    nnz(pertrl(sel_no_c2))/nnz(sel_no_c2),...
                    nnz(pertrl(sel_go_c1))/nnz(sel_go_c1),...
                    nnz(pertrl(sel_go_c2))/nnz(sel_go_c2),...
                    nnz(pertrl(sel_ng_c1))/nnz(sel_ng_c1),...
                    nnz(pertrl(sel_ng_c2))/nnz(sel_ng_c2)];
%                 fwd_rev=[fwd_rev;...
%                     mean(fstr.onesess.fc{fci,2}(s1sel)>fstr.onesess.fc{fci,5}(s1sel)),...
%                     mean(fstr.onesess.fc{fci,2}(s2sel)>fstr.onesess.fc{fci,5}(s2sel))];
            end
        end
        disp(size(metas,1));
    end
    metas_=metas;
    stats_=stats;
    fwd_rev_=fwd_rev;
    no_shift=opt.no_shift;
else
    metas=metas_;
    stats=stats_;
    fwd_rev=fwd_rev_;
end
