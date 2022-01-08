function [fh,bh]=conn_prob_spatial_dist_zha(sig,pair,opt)
arguments
    sig (1,1) struct
    pair (1,1) struct
    opt.dist (1,1) double = 5
end

addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/align')
homedir=ephys.util.getHomedir('dtype','ODR2AFC');
sess_cnt=max(sig.sess);
same_stats=struct();
[same_stats.nm_nm,same_stats.congr,same_stats.incon,same_stats.mem_nm,same_stats.nm_mem]...
    =deal(nan(sess_cnt,1));
l2h_stats=same_stats;
h2l_stats=same_stats;
[~,sig_same,sig_h2l,sig_l2h]=zha_diff_at_level(sig.reg,'hierarchy',true);
[~,pair_same,pair_h2l,pair_l2h]=zha_diff_at_level(pair.reg,'hierarchy',true);
idmap=load(fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/align','reg_ccfid_map.mat'));

wantednum=[31,95,159,814,952,1080,44,500,714,961,972,453,589];
graysel=all(ismember(pair.reg(:,5,:),wantednum),3);
pair.reg=pair.reg(graysel,:,:);

diff_reg_pair=squeeze(pair.reg(pair_h2l(:,opt.dist) | pair_l2h(:,opt.dist),opt.dist,:));
ureg=unique(diff_reg_pair(:,1));
same_stats=[];
for ridx=1:numel(ureg)
    pair_count=nnz(all(pair.reg(:,opt.dist,:)==ureg(ridx),3));
    if pair_count<250
        continue;
    end
    sig_count=nnz(all(sig.reg(:,opt.dist,:)==ureg(ridx),3));
    same_stats=[same_stats;double(ureg(ridx)),double(ureg(ridx)),0,sig_count,pair_count];
end

reg_comb=nchoosek(ureg,2);
dist_stats=[];
for ridx=1:size(reg_comb,1)
    pair_count=nnz(pair.reg(:,opt.dist,1)==reg_comb(ridx,1) & pair.reg(:,opt.dist,2)==reg_comb(ridx,2));
    if pair_count<250
        continue;
    end
    [avail,dist]=bz.get_spatial_dist(idmap.ccfid2reg(reg_comb(ridx,1)),idmap.ccfid2reg(reg_comb(ridx,2)));
    if ~avail
        continue
    end
    sig_count=nnz(sig.reg(:,opt.dist,1)==reg_comb(ridx,1) & sig.reg(:,opt.dist,2)==reg_comb(ridx,2));
    dist_stats=[dist_stats;double(reg_comb(ridx,1)),double(reg_comb(ridx,2)),dist,sig_count,pair_count];
end

samemm=mean(same_stats(:,4)./same_stats(:,5)).*100;
dist_sums=[0,samemm,...
reshape(bootci(500,@(x) mean(x),same_stats(:,4)./same_stats(:,5).*100),1,2)-samemm];
Y=discretize(dist_stats(:,3)./100,0:5);
for di=reshape(unique(Y),1,[])
    xx=di-0.5;
    dsel=Y==di;
    mm=mean(dist_stats(dsel,4)./dist_stats(dsel,5).*100);
    if nnz(dsel)<=1
        ci=[mm,mm];
    else
        ci=bootci(500,@(x) mean(x),dist_stats(dsel,4)./dist_stats(dsel,5).*100);
    end
    dist_sums=[dist_sums;xx,mm,ci(1)-mm,ci(2)-mm];
end

% [r,p]=corr([same_stats(:,3);dist_stats(:,3)]./100,[same_stats(:,4);dist_stats(:,4)]./[same_stats(:,5);dist_stats(:,5)].*100);

xx=[same_stats(:,3);dist_stats(:,3)].*10;% micro-meter unit
yy=[same_stats(:,4);dist_stats(:,4)]./[same_stats(:,5);dist_stats(:,5)].*100;
tbl=table(xx,yy);
modelfun=@(b,x) b(1)*(x(:,1).^b(2))+b(3);
mdl=fitnlm(tbl,modelfun,[-0.5,0.5,2]);
disp(mdl)

fh=figure('Color','w','Position',[100,100,235,235]);
hold on;
mh=plot(dist_sums(:,1),dist_sums(:,2),'-k','LineWidth',1);
% fplot(@(x) mdl.Coefficients.Estimate(1).*(x.^mdl.Coefficients.Estimate(2))+mdl.Coefficients.Estimate(3),[0,7],'-k')
pltxy=sortrows([mdl.Variables.xx,mdl.Fitted]);
fith=plot(pltxy(:,1)./1000,pltxy(:,2),'-r','LineWidth',1); %micro-meter unit
errorbar(dist_sums(:,1),dist_sums(:,2),dist_sums(:,3),dist_sums(:,4),'k.');
scatter(same_stats(:,3)./100,same_stats(:,4)./same_stats(:,5).*100,4,...
    'o','MarkerFaceColor','k','MarkerFaceAlpha',0.4,'MarkerEdgeColor','none');
scatter(dist_stats(:,3)./100,dist_stats(:,4)./dist_stats(:,5).*100,4,...
    'o','MarkerFaceColor','k','MarkerFaceAlpha',0.4,'MarkerEdgeColor','none');
xlabel('Region distance (mm)');
ylabel('Coupling rate (%)');
xlim([-0.5,7])
ylim([0,3])
legend([mh,fith],{'Mean','Power law fit'},'Location','northoutside')
text(max(xlim()),max(ylim()),sprintf('%.2f,%.2f',sqrt(mdl.Rsquared.Ordinary),0),'HorizontalAlignment','right','VerticalAlignment','top');

exportgraphics(fh,fullfile(homedir,'..','plots','fc_rate_vs_spatial_dist.pdf'))

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

