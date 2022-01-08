% input data from
% [sig,pair]=bz.load_sig_pair('pair',true,'type','ODR2AFC','criteria','any','prefix','1201');
% pair.reg(:,[1 5],:)=pair.reg(:,[5 1],:);
% sig.reg(:,[1 5],:)=sig.reg(:,[5 1],:);

function [fh,bh]=conn_prob_bars_category_zha(sig,pair,opt)
arguments
    sig (1,1) struct
    pair (1,1) struct
    opt.dist (1,1) double = 5
end

homedir=ephys.util.getHomedir('dtype','ODR2AFC');

sess_cnt=max(sig.sess);
same_stats=struct();
[same_stats.t2f,same_stats.f2t,same_stats.t2t]=deal(nan(sess_cnt,1));
l2h_stats=same_stats;
h2l_stats=same_stats;
[~,sig_same,sig_h2l,sig_l2h]=zha_diff_at_level(sig.reg,'hierarchy',true);
[~,pair_same,pair_h2l,pair_l2h]=zha_diff_at_level(pair.reg,'hierarchy',true);

sess_sig_type=sig.categoryResp(sig_same(:,opt.dist),:);
sess_pair_type=pair.categoryResp(pair_same(:,opt.dist),:);
same_stats=get_ratio(sess_sig_type,sess_pair_type);

%h2l
sess_sig_type=sig.categoryResp(sig_h2l(:,opt.dist),:);
sess_pair_type=pair.categoryResp(pair_h2l(:,opt.dist),:);
h2l_stats=get_ratio(sess_sig_type,sess_pair_type);

%l2h
sess_sig_type=sig.categoryResp(sig_l2h(:,opt.dist),:);
sess_pair_type=pair.categoryResp(pair_l2h(:,opt.dist),:);
l2h_stats=get_ratio(sess_sig_type,sess_pair_type);

fprintf('Category Resp\n');

same_stats
h2l_stats
l2h_stats

hier_stats=struct('same_stats',same_stats,'l2h_stats',l2h_stats,'h2l_stats',h2l_stats);
assignin('base','hier_stats',hier_stats);


%% plot 
fh=figure('Color','w','Position',[32,32,235,235]);
hold on
bh=bar([same_stats.t2t(1),same_stats.t2f(1),same_stats.f2t(1);...
    l2h_stats.t2t(1),l2h_stats.t2f(1),l2h_stats.f2t(1);...
    h2l_stats.t2t(1),h2l_stats.t2f(1),h2l_stats.f2t(1)].*100);
[ci1,ci2]=deal([]);
for f=["t2t","t2f","f2t"]
    ci1=[ci1,cellfun(@(x) x.(f)(2),{same_stats,l2h_stats,h2l_stats})];
    ci2=[ci2,cellfun(@(x) x.(f)(3),{same_stats,l2h_stats,h2l_stats})];
end
errorbar([bh.XEndPoints],[bh.YEndPoints],ci1.*100-[bh.YEndPoints],ci2.*100-[bh.YEndPoints],'k.');


bh(1).FaceColor='w';
bh(2).FaceColor=[0.5,0.5,0.5];
bh(3).FaceColor='k';

legend(bh,{'Cate.-Cate.','Cate.-Non Cate.','Non Cate.-Cate.'})
set(gca(),'XTick',1:3,'XTickLabel',{'Within reg.','Olf. to Motor','Motor to Olf.'},'XTickLabelRotation',30)
ylabel('Func. coupling probability (%)');
exportgraphics(fh,fullfile(homedir,'..','plots','conn_prob_bars_categoryResp.pdf'));


%% chisq test
% compare same
p1=chisq_3(hier_stats.same_stats.t2t(4),hier_stats.same_stats.t2t(5),...
    hier_stats.same_stats.t2f(4),hier_stats.same_stats.t2f(5),...
hier_stats.same_stats.f2t(4),hier_stats.same_stats.f2t(5));

% compare l2h
p2=chisq_3(hier_stats.l2h_stats.t2t(4),hier_stats.l2h_stats.t2t(5),...
    hier_stats.l2h_stats.t2f(4),hier_stats.l2h_stats.t2f(5),...
hier_stats.l2h_stats.f2t(4),hier_stats.l2h_stats.f2t(5));

% compare h2l
p3=chisq_3(hier_stats.h2l_stats.t2t(4),hier_stats.h2l_stats.t2t(5),...
    hier_stats.h2l_stats.t2f(4),hier_stats.h2l_stats.t2f(5),...
hier_stats.h2l_stats.f2t(4),hier_stats.h2l_stats.f2t(5));

% compare t2t
p4=chisq_3(hier_stats.same_stats.t2t(4),hier_stats.same_stats.t2t(5),...
    hier_stats.l2h_stats.t2t(4),hier_stats.l2h_stats.t2t(5),...
hier_stats.h2l_stats.t2t(4),hier_stats.h2l_stats.t2t(5));

% compare t2f
p5=chisq_3(hier_stats.same_stats.t2f(4),hier_stats.same_stats.t2f(5),...
    hier_stats.l2h_stats.t2f(4),hier_stats.l2h_stats.t2f(5),...
hier_stats.h2l_stats.t2f(4),hier_stats.h2l_stats.t2f(5));

% compare f2t
p6=chisq_3(hier_stats.same_stats.f2t(4),hier_stats.same_stats.f2t(5),...
    hier_stats.l2h_stats.f2t(4),hier_stats.l2h_stats.f2t(5),...
hier_stats.h2l_stats.f2t(4),hier_stats.h2l_stats.f2t(5));

fprintf('p_same_stats=%.3f\n p_l2h_stats=%.3f\n p_h2l_stats=%.3f\n p_t2t_stats=%.3f\n p_t2f_stats=%.3f\n p_f2t_stats=%.3f\n',p1,p2,p3,p4,p5,p6);


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

wanted=["ACA" "AI" "AON" "DP" "EPd" "HIP" "ILA" "MO" "ORB" "PIR" "PL" "SS" "TT"];
wantednum=[31,95,159,814,952,1080,44,500,714,961,972,453,589];
graysel=all(ismember(reg(:,5,:),wantednum),3);
selreg=reg(graysel,:,:);
if opt.hierarchy
    is_diff=[];
    is_same=false(size(selreg,1),6);
    h2l=false(size(selreg,1),6);
    l2h=false(size(selreg,1),6);
    is_same(:,5)=selreg(:,5,1)==selreg(:,5,2);
    for ri=1:size(selreg,1)
%         regname=arrayfun(@(x) idmap.ccfid2reg(x),squeeze(selreg(ri,5,:)));
%         regtree=cellfun(@(x) idmap.reg2tree(x),squeeze(regname),'UniformOutput',false);
%         regfull=string(cat(2,regtree{:}));
%         if nnz(regfull=='CTX')<2 || nnz(ismember(reg(ri,5,:),wantednum))<2 || any(reg(ri,5,:)==0,'all') || reg(ri,5,1)==reg(ri,5,2)
%             continue
%         end
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


function out=get_ratio(sig_type,pair_type)
% 0=NM,1=S1 sust, 2=S1 trans, 3=S2 sust, 4=S2 trans,-1=switched

arguments
    sig_type (:,2) int32
    pair_type (:,2) int32
end
out=struct();

t2t_p=nnz(all(pair_type==1,2));
if t2t_p>0
    sig=nnz(all(sig_type==1,2));
    [phat,pci]=binofit(sig,t2t_p);
    out.t2t=[phat,pci,sig,t2t_p];
else
    out.t2t=[0,0,0,0];
end

t2f_p=nnz(pair_type(:,1)==1 & pair_type(:,2)==0);

if t2f_p>0
    sig=nnz(sig_type(:,1)==1 & sig_type(:,2)==0);
    [phat,pci]=binofit(sig,t2f_p);
    out.t2f=[phat,pci,sig,t2f_p];
else
    out.t2f=[0,0,0,0];
end

f2t_p=nnz(pair_type(:,1)==0 & pair_type(:,2)==1);

if f2t_p>0
    sig=nnz(sig_type(:,1)==0 & sig_type(:,2)==1);
    [phat,pci]=binofit(sig,f2t_p);
    out.f2t=[phat,pci,sig,f2t_p];
else
    out.f2t=[0,0,0,0];
end


end

