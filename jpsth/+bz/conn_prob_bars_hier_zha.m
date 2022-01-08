% input data from
% [sig,pair]=bz.load_sig_pair('pair',true,'type','ODR2AFC','criteria','any','prefix','1201');
% load(fullfile(homedir,'sig_info.mat'),'sig');
% load(fullfile(homedir,'pair_info.mat'),'pair');
% pair.reg(:,[1 5],:)=pair.reg(:,[5 1],:);
% sig.reg(:,[1 5],:)=sig.reg(:,[5 1],:);

function [fh,bh]=conn_prob_bars_hier_zha(sig,pair,opt)
arguments
    sig (1,1) struct
    pair (1,1) struct
    opt.dist (1,1) double = 5
    opt.suffix (1,1) double = 4
end

homedir=ephys.util.getHomedir('dtype','ODR2AFC');
addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/align')
fields=fieldnames(sig);
disp(fields{opt.suffix})
sess_cnt=max(sig.sess);
same_stats=struct();
[same_stats.nm_nm,same_stats.congr,same_stats.incon,same_stats.mem_nm,same_stats.nm_mem]...
    =deal(nan(sess_cnt,1));
l2h_stats=same_stats;
h2l_stats=same_stats;
[~,sig_same,sig_h2l,sig_l2h]=zha_diff_at_region(sig.reg,'hierarchy',true);
[~,pair_same,pair_h2l,pair_l2h]=zha_diff_at_region(pair.reg,'hierarchy',true);

sess_sig_type=sig.(fields{opt.suffix})(sig_same(:,opt.dist),:);
sess_pair_type=pair.(fields{opt.suffix})(pair_same(:,opt.dist),:);
same_stats=bz.bars_util.get_ratio_hier(sess_sig_type,sess_pair_type);

%h2l
sess_sig_type=sig.(fields{opt.suffix})(sig_h2l(:,opt.dist),:);
sess_pair_type=pair.(fields{opt.suffix})(pair_h2l(:,opt.dist),:);
h2l_stats=bz.bars_util.get_ratio_hier(sess_sig_type,sess_pair_type);

%l2h
sess_sig_type=sig.(fields{opt.suffix})(sig_l2h(:,opt.dist),:);
sess_pair_type=pair.(fields{opt.suffix})(pair_l2h(:,opt.dist),:);
l2h_stats=bz.bars_util.get_ratio_hier(sess_sig_type,sess_pair_type);

fprintf('3 Groups in 1\n');

same_stats
h2l_stats
l2h_stats

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
exportgraphics(fh,fullfile(homedir,'..','plots',sprintf('conn_prob_bars_hier_%s_reg3in1.pdf',fields{opt.suffix})));


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

fprintf('p_same_stats=%.3f\n p_l2h_stats=%.3f\n p_h2l_stats=%.3f\n p_congr_stats=%.3f\n p_incon_stats=%.3f\n p_nm_nm_stats=%.3f\n',p1,p2,p3,p4,p5,p6);


end


function [is_diff,is_same,h2l,l2h]=zha_diff_at_level(reg,opt)
arguments
    reg
    opt.hierarchy (1,1) logical = false
end
persistent ratiomap idmap

if isempty(ratiomap) || isempty(idmap)
    % [~,~,ratiomap]=ref.get_pv_sst();
    % load('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/meta/ratiomap.mat','ratiomap');
    load('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/meta/OBM1Map_zha.mat','OBM1map');
    idmap=load(fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/align','reg_ccfid_map.mat'));
end

% wanted=["ACA" "AI" "AON" "DP" "EPd" "HIP" "ILA" "MO" "ORB" "PIR" "PL" "SS" "TT"];
% wantednum=[31,95,159,814,952,1080,44,500,714,961,972,453,589];
wantednum=[31,95,1080,44,714,972];
graysel=all(ismember(reg(:,5,:),wantednum),3);
selreg=reg(graysel,:,:);
if opt.hierarchy
    is_diff=[];
    is_same=false(size(selreg,1),6);
    h2l=false(size(selreg,1),6);
    l2h=false(size(selreg,1),6);
    is_same(:,5)=selreg(:,5,1)==selreg(:,5,2);
    for ri=1:size(selreg,1)
        if any(selreg(ri,5,:)==0,'all') || selreg(ri,5,1)==selreg(ri,5,2)
            continue
        end
        dhier=diff(arrayfun(@(x) OBM1map(char(idmap.ccfid2reg(x))),squeeze(selreg(ri,5,:))));
        if dhier>0
            l2h(ri,5)=true;
        else
            h2l(ri,5)=true;
        end
    end
else
    is_diff=false(size(reg,1),6);
    is_same=false(size(reg,1),6);
    h2l=[];
    l2h=[];
    for dep=1:6
        is_diff(:,dep)=reg(:,dep,1)~=reg(:,dep,2);
        is_same(:,dep)=reg(:,dep,1)==reg(:,dep,2);
    end
end
end


function [is_diff,is_same,h2l,l2h]=zha_diff_at_region(reg,opt)
arguments
    reg
    opt.hierarchy (1,1) logical = false
end
persistent ratiomap idmap

if isempty(ratiomap) || isempty(idmap)
    % [~,~,ratiomap]=ref.get_pv_sst();
    % load('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/meta/ratiomap.mat','ratiomap');
    load('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/meta/OBM1Map_zha.mat','OBM1map');
    idmap=load(fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/align','reg_ccfid_map.mat'));
end

% wanted=["ACA" "AI" "AON" "DP" "EPd" "HIP" "ILA" "MO" "ORB" "PIR" "PL" "SS" "TT"];
wantednum=[31,95,159,814,952,1080,44,500,714,961,972,453,589];
group1=[159,814,952,589,961];
group2=[31,95,1080,44,714,972];
group3=[500,453];
graysel=all(ismember(reg(:,5,:),wantednum),3);
selreg=reg(graysel,:,:);
if opt.hierarchy
    is_diff=[];
    is_same=false(size(selreg,1),6);
    h2l=false(size(selreg,1),6);
    l2h=false(size(selreg,1),6);
    is_same(:,5)=all(ismember(selreg(:,5,:),group1),3) | all(ismember(selreg(:,5,:),group2),3) | all(ismember(selreg(:,5,:),group3),3);
    h2l(:,5)=(ismember(selreg(:,5,1),group3) & ismember(selreg(:,5,2),group1)) | (ismember(selreg(:,5,1),group3) & ismember(selreg(:,5,2),group2)) | (ismember(selreg(:,5,1),group2) & ismember(selreg(:,5,2),group1));
    l2h(:,5)=(ismember(selreg(:,5,1),group1) & ismember(selreg(:,5,2),group2)) | (ismember(selreg(:,5,1),group1) & ismember(selreg(:,5,2),group3)) | (ismember(selreg(:,5,1),group2) & ismember(selreg(:,5,2),group3));
else
    is_diff=false(size(reg,1),6);
    is_same=false(size(reg,1),6);
    h2l=[];
    l2h=[];
    for dep=1:6
        is_diff(:,dep)=reg(:,dep,1)~=reg(:,dep,2);
        is_same(:,dep)=reg(:,dep,1)==reg(:,dep,2);
    end
end
end


function [is_diff,is_same,h2l,l2h]=zha_diff_at_region_one(reg,opt)
arguments
    reg
    opt.hierarchy (1,1) logical = false
end
persistent ratiomap idmap

if isempty(ratiomap) || isempty(idmap)
    % [~,~,ratiomap]=ref.get_pv_sst();
    % load('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/meta/ratiomap.mat','ratiomap');
    load('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/meta/OBM1Map_zha.mat','OBM1map');
    idmap=load(fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/align','reg_ccfid_map.mat'));
end

% wanted=["ACA" "AI" "AON" "DP" "EPd" "HIP" "ILA" "MO" "ORB" "PIR" "PL" "SS" "TT"];
wantednum=[31,95,159,814,952,1080,44,500,714,961,972,453,589];
group1=[159,814,952,589,961];
group2=[31,95,1080,44,714,972];
group3=[500,453];
graysel=all(ismember(reg(:,5,:),wantednum),3);
selreg=reg(graysel,:,:);
if opt.hierarchy
    is_diff=[];
    is_same=false(size(selreg,1),6);
    h2l=false(size(selreg,1),6);
    l2h=false(size(selreg,1),6);
    is_same(:,5)=all(ismember(selreg(:,5,:),group1),3) | all(ismember(selreg(:,5,:),group2),3) | all(ismember(selreg(:,5,:),group3),3);
    h2l(:,5)=(ismember(selreg(:,5,1),group3) & ismember(selreg(:,5,2),group1)) | (ismember(selreg(:,5,1),group3) & ismember(selreg(:,5,2),group2)) | (ismember(selreg(:,5,1),group2) & ismember(selreg(:,5,2),group1));
    l2h(:,5)=(ismember(selreg(:,5,1),group1) & ismember(selreg(:,5,2),group2)) | (ismember(selreg(:,5,1),group1) & ismember(selreg(:,5,2),group3)) | (ismember(selreg(:,5,1),group2) & ismember(selreg(:,5,2),group3));
else
    is_diff=false(size(reg,1),6);
    is_same=false(size(reg,1),6);
    h2l=[];
    l2h=[];
    for dep=1:6
        is_diff(:,dep)=reg(:,dep,1)~=reg(:,dep,2);
        is_same(:,dep)=reg(:,dep,1)==reg(:,dep,2);
    end
end
end
