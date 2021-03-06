% input data from
% [sig,pair]=bz.load_sig_pair('pair',true)

function conn_prob(sig,pair)
arguments
    sig (1,1) struct
    pair (1,1) struct
end

addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/align')
[sig.reg_dist,pair.reg_dist]=get_conn_dist(sig,pair);
sess_cnt=max(sig.sess);
stats=struct();
stats.nm_nm=nan(sess_cnt,7);
stats.congr=nan(sess_cnt,7);
stats.incon=nan(sess_cnt,7);
stats.mem_nm=nan(sess_cnt,7);
stats.nm_mem=nan(sess_cnt,7);
mm=cell(7,1);
ci=cell(7,1);
for dist=0:6
    for i=1:sess_cnt
        if rem(i,20)==0, disp(i);end
        sess_sig_type=sig.mem_type(sig.sess==i & sig.reg_dist>=0 &sig.reg_dist<=dist,:);
        sess_pair_type=pair.mem_type(pair.sess==i & pair.reg_dist>=0 & pair.reg_dist<=dist,:);
        onesess=bz.bars_util.get_ratio(sess_sig_type,sess_pair_type);
        for fld=["nm_nm","congr","incon","mem_nm","nm_mem"]
            if isfield(onesess,fld)
                stats.(fld)(i,dist+1)=onesess.(fld);
            end
        end
    end
%     cell5={stats.nm_nm,stats.nm_mem,stats.mem_nm,stats.incon,stats.congr};
end
for distbin=1:7
    mm{distbin}=cellfun(@(x) nanmean(x)*100,cell5,'UniformOutput',false);
    ci{distbin}=cell2mat(cellfun(@(x) bootci(1000,@(y) nanmean(y)*100,x),cell5,'UniformOutput',false));
end
finisel=all(cell2mat(cellfun(@(x) all(isfinite(stats.(x)),2),...
    {'nm_nm','congr','incon','mem_nm','nm_mem'},'UniformOutput',false)),2);
p=anova2([stats.nm_nm(finisel,:);stats.congr(finisel,:)],nnz(finisel),'off');
disp(p);
colors={'k','c','m','b','r'};
fh=figure('Color','w','Position',[100,100,300,300]);
hold on;
for i=1:5
    oneci=cell2mat(cellfun(@(x) x(:,i)',ci,'UniformOutput',false));
    fill([0:6,6:-1:0],[oneci(:,1);flip(oneci(:,2))],colors{i},'FaceAlpha',0.1,'EdgeColor','none');
    ph(i)=plot(0:6,cellfun(@(x) x(i),mm),'LineWidth',1,'Color',colors{i});
end
ylim([0,3]);
xlabel('Max structural distance');
ylabel('Coupling fraction (%)');
legend(ph,{'NonMem','NonMem->Mem','Mem->NonMem','Incongru','Congruent'});
set(gca,'XTick',0:6,'YTick',0:3)
% exportgraphics
% 
% arrayfun(@(x) errorbar(x,mm(x),ci{x}(1)-mm(x),ci{x}(2)-mm(x),'k.','LineWidth',1),1:5);
% set(gca,'XTick',1:5,'XTickLabel',{'NonMem-NonMem','NonMem-Mem','Mem-NonMem','Incongruent','Congruent'},'XTickLabelRotation',45);
% ylabel('Connection fraction (%)')
% xlim([0.5,5.5]);
% % exportgraphics(fh,fullfile('bzdata','conn_frac.pdf'));
end