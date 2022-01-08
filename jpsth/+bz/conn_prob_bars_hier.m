% input data from
% [sig,pair]=bz.load_sig_pair('pair',true,'type','dual_task','criteria','WT','prefix','1108')

function [fh,bh]=conn_prob_bars_hier(sig,pair,opt)
arguments
    sig (1,1) struct
    pair (1,1) struct
    opt.dist (1,1) double = 5
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','ODR2AFC','dual_task','VDPAP'})}='neupix'
    opt.per_region_within (1,1) logical = false
end

homedir=ephys.util.getHomedir('dtype',opt.type);
sess_cnt=max(sig.sess);
same_stats=struct();
[same_stats.nm_nm,same_stats.congr,same_stats.incon,same_stats.mem_nm,same_stats.nm_mem]...
    =deal(nan(sess_cnt,1));
l2h_stats=same_stats;
h2l_stats=same_stats;
[~,sig_same,sig_h2l,sig_l2h]=bz.util.diff_at_level(sig.reg,'hierarchy',true);
[~,pair_same,pair_h2l,pair_l2h]=bz.util.diff_at_level(pair.reg,'hierarchy',true);

sess_sig_type=sig.mem_type(sig_same(:,opt.dist),:);
sess_pair_type=pair.mem_type(pair_same(:,opt.dist),:);
same_stats=bz.bars_util.get_ratio_hier(sess_sig_type,sess_pair_type);

%h2l
sess_sig_type=sig.mem_type(sig_h2l(:,opt.dist),:);
sess_pair_type=pair.mem_type(pair_h2l(:,opt.dist),:);
h2l_stats=bz.bars_util.get_ratio_hier(sess_sig_type,sess_pair_type);

%l2h
sess_sig_type=sig.mem_type(sig_l2h(:,opt.dist),:);
sess_pair_type=pair.mem_type(pair_l2h(:,opt.dist),:);
l2h_stats=bz.bars_util.get_ratio_hier(sess_sig_type,sess_pair_type);

hier_stats=struct('same_stats',same_stats,'l2h_stats',l2h_stats,'h2l_stats',h2l_stats);
assignin('base','hier_stats',hier_stats);

fh=figure('Color','w','Position',[32,32,235,235]);
hold on
bh=bar([same_stats.congr(1),same_stats.incon(1),same_stats.nm_nm(1);...
    l2h_stats.congr(1),l2h_stats.incon(1),l2h_stats.nm_nm(1);...
    h2l_stats.congr(1),h2l_stats.incon(1),h2l_stats.nm_nm(1)].*100);
[ci1,ci2]=deal([]);
for f=["congr","incon","nm_nm"]
    ci1=[ci1,cellfun(@(x) x.(f)(2),{same_stats,l2h_stats,h2l_stats})];
    ci2=[ci2,cellfun(@(x) x.(f)(3),{same_stats,l2h_stats,h2l_stats})];
end
errorbar([bh.XEndPoints],[bh.YEndPoints],ci1.*100-[bh.YEndPoints],ci2.*100-[bh.YEndPoints],'k.');


bh(1).FaceColor='w';
bh(2).FaceColor=[0.5,0.5,0.5];
bh(3).FaceColor='k';

legend(bh,{'Same memory','Diff. memory','Non-memory'})
set(gca(),'XTick',1:3,'XTickLabel',{'Within reg.','Olf. to Motor','Motor to Olf.'},'XTickLabelRotation',30)
ylabel('Func. coupling probability (%)');
exportgraphics(fh,fullfile(homedir,'..','plots','conn_prob_bars_hier.pdf'));


%% chisq test
% compare same
p1=chisq_3(hier_stats.same_stats.congr(4),hier_stats.same_stats.congr(5),...
    hier_stats.same_stats.incon(4),hier_stats.same_stats.incon(5),...
hier_stats.same_stats.nm_nm(4),hier_stats.same_stats.nm_nm(5));

% compare l2h
p2=chisq_3(hier_stats.l2h_stats.congr(4),hier_stats.l2h_stats.congr(5),...
    hier_stats.l2h_stats.incon(4),hier_stats.l2h_stats.incon(5),...
hier_stats.l2h_stats.nm_nm(4),hier_stats.l2h_stats.nm_nm(5));

% compare h2l
p3=chisq_3(hier_stats.h2l_stats.congr(4),hier_stats.h2l_stats.congr(5),...
    hier_stats.h2l_stats.incon(4),hier_stats.h2l_stats.incon(5),...
hier_stats.h2l_stats.nm_nm(4),hier_stats.h2l_stats.nm_nm(5));

% compare congr
p4=chisq_3(hier_stats.same_stats.congr(4),hier_stats.same_stats.congr(5),...
    hier_stats.l2h_stats.congr(4),hier_stats.l2h_stats.congr(5),...
hier_stats.h2l_stats.congr(4),hier_stats.h2l_stats.congr(5));

% compare incon
p5=chisq_3(hier_stats.same_stats.incon(4),hier_stats.same_stats.incon(5),...
    hier_stats.l2h_stats.incon(4),hier_stats.l2h_stats.incon(5),...
hier_stats.h2l_stats.incon(4),hier_stats.h2l_stats.incon(5));

% compare nm
p6=chisq_3(hier_stats.same_stats.nm_nm(4),hier_stats.same_stats.nm_nm(5),...
    hier_stats.l2h_stats.nm_nm(4),hier_stats.l2h_stats.nm_nm(5),...
hier_stats.h2l_stats.nm_nm(4),hier_stats.h2l_stats.nm_nm(5));

fprintf('p_same_stats=%.3f\n p_l2h_stats=%.3f\n p_h2l_stats=%.3f\n p_congru_stats=%.3f\n p_incon_stats=%.3f\n p_nm_nm_stats=%.3f\n',p1,p2,p3,p4,p5,p6);

end
