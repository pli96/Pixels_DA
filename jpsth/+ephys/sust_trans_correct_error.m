function sust_trans_correct_error(type,opt)
arguments
    type (1,:) char {mustBeMember(type,{'Sustained','Transient'})}
    opt.single_bin (1,1) logical = true
    opt.bin (1,1) double {mustBeInRange(opt.bin,1,6),mustBeInteger} = 6
    opt.plot_scatter (1,1) logical = false
    opt.plot_per_su (1,1) logical = true
    opt.plot_per_trial (1,1) logical = false
    opt.ctx_only (1,1) logical = false
    opt.plot_showcase (1,1) logical = true
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','ODR2AFC','dual_task','VDPAP'})}='neupix'
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
    opt.delay (1,1) double = 6 % delay duration
end

set(groot,'defaultTextFontSize',10);

homedir=ephys.util.getHomedir('dtype',opt.type,'type','raw'); % ~/DataSum directory

if ~strcmp(opt.type,'ODR2AFC')
    meta=ephys.util.load_meta('type',opt.type,'criteria',opt.criteria,'delay',opt.delay);
else
    load(fullfile(homedir,'..','xcorr','deleted_meta.mat'),'meta');
end

stats=struct();
if opt.plot_scatter
    figure('Color','w','Position',[100,100,400,400]);
    hold on;
end

fidx=1;
colors={'r','b'};
if strcmp(type,'Sustained')
    types=[1,3];
else
    types=[2,4];
end
for onetype=types
    if opt.ctx_only
        typesel=find(meta.mem_type==onetype & strcmp(meta.reg_tree(2,:),'CTX') & ~strcmp(meta.reg_tree(5,:),''));
    else
        typesel=find(meta.mem_type==onetype);
    end
    if strcmp(type,'Transient')
        if opt.single_bin
            subsel=meta.per_bin(opt.bin,typesel)~=0;
            typesel=typesel(subsel);
%         else
%             typesel=typesel(1:50:numel(typesel));
        end
    end
    homedir=ephys.util.getHomedir('type','raw');
    idx=1;
    stats.(sprintf('type%d',onetype))=nan(0,4);
    stats.(sprintf('type%d_pertrial',onetype))=cell(0,4);
    for ii=typesel
        fpath=fullfile(homedir,meta.allpath{ii},'FR_All_1000.hdf5');
        trials=h5read(fpath,'/Trials');
        suid=h5read(fpath,'/SU_id');
        fr=h5read(fpath,'/FR_All');
        if opt.single_bin
            bins=opt.bin+4;
%             if meta.per_bin(6,ii)==0
%                 continue
%             end
        else
            bins=find(meta.per_bin(:,ii)~=0)+4;
        end
        if nnz(trials(:,10)==0 &trials(:,5)==4 & trials(:,8)==6)==0 ...
                ||nnz(trials(:,10)==0 &trials(:,5)==8 & trials(:,8)==6)==0
            continue
        end
        
        cs1=mean(fr(trials(:,9)~=0 & trials(:,10)~=0 &trials(:,5)==4 & trials(:,8)==6,suid==meta.allcid(ii),bins),3);
        cs2=mean(fr(trials(:,9)~=0 & trials(:,10)~=0 &trials(:,5)==8 & trials(:,8)==6,suid==meta.allcid(ii),bins),3);
        es1=mean(fr(trials(:,10)==0 &trials(:,5)==4 & trials(:,8)==6,suid==meta.allcid(ii),bins),3);
        es2=mean(fr(trials(:,10)==0 &trials(:,5)==8 & trials(:,8)==6,suid==meta.allcid(ii),bins),3);
        
        delaymm=mean([mean(cs1),mean(cs2)]);
        delaystd=std([cs1;cs2]);
        if delaystd==0, continue;  end
        
        cs1=(cs1-delaymm)./delaystd;
        cs2=(cs2-delaymm)./delaystd;
        es1=(es1-delaymm)./delaystd;
        es2=(es2-delaymm)./delaystd;
        
        %         if onetype==2 && mean(cs1)<mean(cs2),keyboard;end
        if opt.plot_showcase
            if min(cellfun(@(x) numel(x),{cs1,cs2,es1,es2}))<10
                continue
            end
            [~,~,~,AUCC]=perfcurve([zeros(size(cs1));ones(size(cs2))],[cs1;cs2],0);
            [~,~,~,AUCE]=perfcurve([zeros(size(es1));ones(size(es2))],[es1;es2],0);
            
            if abs(AUCC-0.5)>0.30 && abs(AUCE-0.5)<0.15
                figure()
                subplot(1,3,1)
                hold on 
                cs1c=squeeze(mean(fr(trials(:,9)~=0 & trials(:,10)~=0 &trials(:,5)==4 & trials(:,8)==6,suid==meta.allcid(ii),3:10),[1,2]));
                cs2c=squeeze(mean(fr(trials(:,9)~=0 & trials(:,10)~=0 &trials(:,5)==8 & trials(:,8)==6,suid==meta.allcid(ii),3:10),[1 2]));
                es1c=squeeze(mean(fr(trials(:,10)==0 &trials(:,5)==4 & trials(:,8)==6,suid==meta.allcid(ii),3:10),[1 2]));
                es2c=squeeze(mean(fr(trials(:,10)==0 &trials(:,5)==8 & trials(:,8)==6,suid==meta.allcid(ii),3:10),[1 2]));
                
                plot(cs1c,'-r')
                plot(cs2c,'-b')
                plot(es1c,':r')
                plot(es2c,':b')
                xline(1.5,'--k')
                
                
                subplot(1,3,2)
                hold on 
                histogram(cs1,-3:0.3:3,'FaceColor','r','FaceAlpha',0.4)
                histogram(cs2,-3:0.3:3,'FaceColor','b','FaceAlpha',0.4)
                subplot(1,3,3)
                hold on 
                histogram(es1,-3:0.3:3,'FaceColor','r','FaceAlpha',0.4)
                histogram(es2,-3:0.3:3,'FaceColor','b','FaceAlpha',0.4)
                sgtitle(ii);
                keyboard()
            end
        end
        
        if opt.plot_scatter
            ch(fidx)=scatter(mean(cs1),mean(cs2),36,colors{fidx},'MarkerFaceColor',colors{fidx},'MarkerFaceAlpha',0.8,'MarkerEdgeColor','none');
            eh=scatter(mean(es1),mean(es2),16,'k','MarkerFaceColor','k','MarkerFaceAlpha',0.2,'MarkerEdgeColor','none');
            plot([mean(cs1),mean(es1)],[mean(cs2),mean(es2)],':','LineWidth',0.5,'Color',colors{fidx});
        end
        stats.(sprintf('type%d',onetype))(idx,:)=[mean(cs1),mean(cs2),mean(es1),mean(es2)];
        stats.(sprintf('type%d_pertrial',onetype))(idx,:)={cs1,cs2,es1,es2};
        idx=idx+1;
    end
    fidx=fidx+1;
end
if opt.plot_scatter
    plot([-10,10],[-10,10],'--k')
    xlim([-2,2]);
    ylim(xlim());
    xlabel('Sample 1 normalized FR (Z-score)')
    ylabel('Sample 2 normalized FR (Z-score)')
    legend([ch(1),ch(2),eh],{'S1 correct trials','S2 correct trials','Error trials'});
end

% SU per session mean
% correct trial
if opt.plot_per_su
figure('Color','w','Position',[100,100,750,176]);
subplot(1,3,1);
hold on;
ph=histogram([stats.(sprintf('type%d',types(1)))(:,1);stats.(sprintf('type%d',types(2)))(:,2)],-2:0.1:2,'Normalization','probability','FaceColor','r','FaceAlpha',0.4);
nph=histogram([stats.(sprintf('type%d',types(1)))(:,2);stats.(sprintf('type%d',types(2)))(:,1)],-2:0.1:2,'Normalization','probability','FaceColor','k','FaceAlpha',0.4);
xline(nanmean([stats.(sprintf('type%d',types(1)))(:,1);stats.(sprintf('type%d',types(2)))(:,2)]),'--r','LineWidth',1);
xline(nanmean([stats.(sprintf('type%d',types(1)))(:,2);stats.(sprintf('type%d',types(2)))(:,1)]),'--k','LineWidth',1)
xlim([-1.5,1.5]);
title('Correct trials')
xlabel('Normalized FR (Z-Score)');
ylabel('Probability')
text(max(xlim()),max(ylim()),num2str(numel(ph.Data)),'HorizontalAlignment','right','VerticalAlignment','top');

%error trial
subplot(1,3,2);
hold on;
ph=histogram([stats.(sprintf('type%d',types(1)))(:,3);stats.(sprintf('type%d',types(2)))(:,4)],-2:0.1:2,'Normalization','probability','FaceColor','r','FaceAlpha',0.4);
nph=histogram([stats.(sprintf('type%d',types(1)))(:,4);stats.(sprintf('type%d',types(2)))(:,3)],-2:0.1:2,'Normalization','probability','FaceColor','k','FaceAlpha',0.4);
xline(nanmean([stats.(sprintf('type%d',types(1)))(:,3);stats.(sprintf('type%d',types(2)))(:,4)]),'--r','LineWidth',1)
xline(nanmean([stats.(sprintf('type%d',types(1)))(:,4);stats.(sprintf('type%d',types(2)))(:,3)]),'--k','LineWidth',1)
xlim([-1.5,1.5]);
title('Error trials');
legend([ph,nph],{'Prefered','Non-prefered'});
xlabel('Normalized FR (Z-Score)');
ylabel('Probability')

%auc
onecolumn=size(stats.(sprintf('type%d',types(1))),1)+size(stats.(sprintf('type%d',types(2))),1);
[xc,yc,~,aucc]=perfcurve((1:2*onecolumn)>onecolumn,[stats.(sprintf('type%d',types(1)))(:,1);stats.(sprintf('type%d',types(2)))(:,2);stats.(sprintf('type%d',types(1)))(:,2);stats.(sprintf('type%d',types(2)))(:,1)],0);
[xe,ye,~,auce]=perfcurve((1:2*onecolumn)>onecolumn,[stats.(sprintf('type%d',types(1)))(:,3);stats.(sprintf('type%d',types(2)))(:,4);stats.(sprintf('type%d',types(1)))(:,4);stats.(sprintf('type%d',types(2)))(:,3)],0);
subplot(1,3,3);
hold on;
hc=plot(xc,yc,'-r','LineWidth',1);
he=plot(xe,ye,'-k','LineWidth',1);
legend([hc,he],{sprintf('Correct trials AUC=%0.3f',aucc),...
    sprintf('Error trials AUC=%0.3f',auce)},...
    'Location','southeast');
xlabel('False positive rate (fpr)');
ylabel('True positive rate (tpr)');
if opt.single_bin
    sgtitle(sprintf('%s averaged cross-trial bin %d',type,opt.bin));
else
    sgtitle(sprintf('%s averaged cross-trial',type));
end
end

%Per trial
if opt.plot_per_trial
%correct trials
figure('Color','w','Position',[100,100,1200,300]);
subplot(1,3,1);
hold on;
xbins=-3:0.15:3;
prefmat=cell2mat(cellfun(@(x) histcounts(x,xbins,'Normalization','probability'),...
    [stats.(sprintf('type%d_pertrial',types(1)))(:,1);...
    stats.(sprintf('type%d_pertrial',types(2)))(:,2)],...
    'UniformOutput',false));
nonprefmat=cell2mat(cellfun(@(x) histcounts(x,xbins,'Normalization','probability'),...
    [stats.(sprintf('type%d_pertrial',types(1)))(:,2);...
    stats.(sprintf('type%d_pertrial',types(2)))(:,1)],...
    'UniformOutput',false));

ph=bar(xbins(1:end-1)+0.075,mean(prefmat),'FaceColor','r','FaceAlpha',0.4);
nph=bar(xbins(1:end-1)+0.075,mean(nonprefmat),'FaceColor','k','FaceAlpha',0.4);

pcom=sum((xbins(1:end-1)+0.075).*mean(prefmat))./sum(mean(prefmat));
npcom=sum((xbins(1:end-1)+0.075).*mean(nonprefmat))./sum(mean(nonprefmat));
xline(pcom,'--r','LineWidth',1);
xline(npcom,'--k','LineWidth',1);
title('Correct trials')
xlabel('Normalized FR (Z-Score)');
ylabel('Probability')

%error trials
subplot(1,3,2);
hold on;
xbins=-3:0.15:3;
prefmat=cell2mat(cellfun(@(x) histcounts(x,xbins,'Normalization','probability'),...
    [stats.(sprintf('type%d_pertrial',types(1)))(:,3);...
    stats.(sprintf('type%d_pertrial',types(2)))(:,4)],...
    'UniformOutput',false));
nonprefmat=cell2mat(cellfun(@(x) histcounts(x,xbins,'Normalization','probability'),...
    [stats.(sprintf('type%d_pertrial',types(1)))(:,4);...
    stats.(sprintf('type%d_pertrial',types(2)))(:,3)],...
    'UniformOutput',false));

ph=bar(xbins(1:end-1)+0.075,nanmean(prefmat),'FaceColor','r','FaceAlpha',0.4);
nph=bar(xbins(1:end-1)+0.075,nanmean(nonprefmat),'FaceColor','k','FaceAlpha',0.4);

pcom=sum((xbins(1:end-1)+0.075).*nanmean(prefmat))./sum(nanmean(prefmat));
npcom=sum((xbins(1:end-1)+0.075).*nanmean(nonprefmat))./sum(nanmean(nonprefmat));
xline(pcom,'--r','LineWidth',1);
xline(npcom,'--k','LineWidth',1);

title('Error trials');
legend([ph,nph],{'Prefered','Non-prefered'});
xlabel('Normalized FR (Z-Score)');
ylabel('Probability')

%auc

subplot(1,3,3);
hold on;
xq=0.005:0.01:1;
prefs1=arrayfun(@(x) auc_per_su(stats.(sprintf('type%d_pertrial',types(1)))(x,:),0,xq),...
    1:size(stats.(sprintf('type%d_pertrial',types(1))),1));
prefs2=arrayfun(@(x) auc_per_su(stats.(sprintf('type%d_pertrial',types(2)))(x,:),1,xq),...
    1:size(stats.(sprintf('type%d_pertrial',types(2))),1));

hc=plot(xq,mean([cell2mat({prefs1.yc}.');cell2mat({prefs2.yc}.')]),'-r','LineWidth',1);
he=plot(xq,mean([cell2mat({prefs1.ye}.');cell2mat({prefs2.ye}.')]),'-k','LineWidth',1);
legend([hc,he],{sprintf(...
    'Correct trials AUC=%0.2f',mean([prefs1.aucc,prefs2.aucc]))...
    ,sprintf(...
    'Error trials AUC=%0.2f',mean([prefs1.auce,prefs2.auce]))},...
    'Location','southeast');
xlabel('False positive rate (fpr)');
ylabel('True positive rate (tpr)');
sgtitle(sprintf('%s stats from trials, averaged over neurons',type));
end
end


function out=auc_per_su(data,pos,xq)
out=struct();
labels=(1:numel([data{1};data{2}]))>numel(data{1});
scores=[data{1};data{2}];
[xc,yc,~,out.aucc]=perfcurve(labels,scores,pos);
[G,uxc]=findgroups(xc);
mmy=splitapply(@(x) mean(x), yc, G);
out.yc=interp1(uxc,mmy,xq);

labels=(1:numel([data{3};data{4}]))>numel(data{3});
scores=[data{3};data{4}];
[xe,ye,~,out.auce]=perfcurve(labels,scores,pos);
[G,uxe]=findgroups(xe);
mmy=splitapply(@(x) mean(x), ye, G);
out.ye=interp1(uxe,mmy,xq);

end
