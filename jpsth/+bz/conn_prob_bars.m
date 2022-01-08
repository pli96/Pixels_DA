% input data from
% [sig,pair]=bz.load_sig_pair('pair',true,'type',opt.type,'criteria',opt.criteria,'prefix',opt.prefix);

function conn_prob_bars(sig,pair,opt)
arguments
    sig (1,1) struct
    pair (1,1) struct
    opt.dist (1,1) double = 5
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','ODR2AFC','dual_task','VDPAP'})}='neupix'
end

homedir=ephys.util.getHomedir('dtype',opt.type);
addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/align')
sess_cnt=max(sig.sess);
same_stats=struct();
[same_stats.nm_nm,same_stats.congr,same_stats.incon,same_stats.mem_nm,same_stats.nm_mem]...
    =deal(nan(sess_cnt,1));
diff_stats=same_stats;
[sig_diff,sig_same]=bz.util.diff_at_level(sig.reg);
[pair_diff,pair_same]=bz.util.diff_at_level(pair.reg);

for i=1:sess_cnt
    if rem(i,20)==0, disp(i);end
    %same
    sess_sig_type=sig.mem_type(sig.sess==i & sig_same(:,opt.dist),:);
    sess_pair_type=pair.mem_type(pair.sess==i & pair_same(:,opt.dist),:);
    onesess=bz.bars_util.get_ratio(sess_sig_type,sess_pair_type,'nm_mem',true);
    for fld=["congr","incon","mem_nm","nm_mem","nm_nm"]
        if isfield(onesess,fld)
            same_stats.(fld)(i)=onesess.(fld);
        end
    end
    %diff
    sess_sig_type=sig.mem_type(sig.sess==i & sig_diff(:,opt.dist),:);
    sess_pair_type=pair.mem_type(pair.sess==i & pair_diff(:,opt.dist),:);
    onesess=bz.bars_util.get_ratio(sess_sig_type,sess_pair_type,'nm_mem',true);
    for fld=["congr","incon","mem_nm","nm_mem","nm_nm"]
        if isfield(onesess,fld)
            diff_stats.(fld)(i)=onesess.(fld);
        end
    end
end
flds=["congr","incon","mem_nm","nm_mem","nm_nm"];
samemat=cell2mat(arrayfun(@(x) same_stats.(x),flds,'UniformOutput',false));
diffmat=cell2mat(arrayfun(@(x) diff_stats.(x),flds,'UniformOutput',false));
finisel=all(isfinite([samemat,diffmat]),2);

same_stats.sums.mm=mean(samemat(finisel,:)).*100;
same_stats.sums.ci=bootci(1000,@(x) mean(x),samemat(finisel,:)).*100;
diff_stats.sums.mm=mean(diffmat(finisel,:)).*100;
diff_stats.sums.ci=bootci(1000,@(x) mean(x),diffmat(finisel,:)).*100;

[psame,~,stats_sm]=anova1(samemat(finisel,:),flds,'off');
[pdiff,~,stats_df]=anova1(diffmat(finisel,:),flds,'off');

out_sm=multcompare(stats_sm);
out_df=multcompare(stats_df);

disp(out_sm);
disp(out_df);

fh=figure('Color','w','Position',[100,100,250,250]);
subplot(1,2,1);hold on;
plotOne(same_stats,psame)
ylabel('Coupling fraction (%)')
title('Within reg.')
subplot(1,2,2);hold on;
plotOne(diff_stats,pdiff)
title('Cross reg.')
exportgraphics(fh,fullfile(homedir,'..','plots','conn_frac_bar.pdf'));
end


function plotOne(data,p)
bar(1:5,data.sums.mm,'FaceColor','w','EdgeColor','k');
errorbar(1:5,...
    data.sums.mm,...
    data.sums.ci(1,:)-data.sums.mm,...
    data.sums.ci(2,:)-data.sums.mm,...
    'k.');

if max(ylim())<1
    ylim([0,1]);
end
    
set(gca(),'XTick',1:5,'XTickLabel',["Congru","Incongru","Mem-Non","Non-Mem","Non-Non"],...
    'XTickLabelRotation',60,'TickLabelInterpreter','none','FontSize',10,...
    'YTick',0:0.5:max(ylim()))
text(max(xlim()),max(ylim()),sprintf('p=%.3f',p),'HorizontalAlignment','right','VerticalAlignment','top');
end
