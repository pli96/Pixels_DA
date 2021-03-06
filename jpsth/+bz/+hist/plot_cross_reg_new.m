function fh=plot_cross_reg_new(stats,opt)
arguments
    stats (1,1) struct
    opt.binw (1,1) double = 200
    opt.dir (1,:) char {mustBeMember(opt.dir,{'from','to'})}  = 'from'
    opt.treedepth (1,1) double {mustBeMember(opt.treedepth,3:5)} =5 ;
    opt.relation (1,:) char {mustBeMember(opt.relation,{'same','diff'})} = 'diff'
    opt.title (1,:) char = []
    opt.minpair (1,1) double = 30
    opt.plottype (1,:) char {mustBeMember(opt.plottype,{'bar','curve'})} = 'curve'
end

pxxmin=opt.binw+opt.binw/2;
pxxmax=11*opt.binw;

trialtype=char(fieldnames(stats));

if strcmp(opt.relation,'diff')
    cr=bz.hist.get_stats_by_mem_type(stats,'between',opt.treedepth);
    % congsel=stats.congru.maxiter(:,1)==0 & stats.congru.diff_reg(:,opt.treedepth);
    % nonmsel=stats.nonmem.maxiter(:,1)==0 & stats.nonmem.diff_reg(:,opt.treedepth);
    % incosel=stats.incongru.maxiter(:,1)==0 & stats.incongru.diff_reg(:,opt.treedepth);
    congsel=sum(ismember(stats.correct.coeff,cr.congru),2)==11;
    nonmsel=sum(ismember(stats.correct.coeff,cr.nonmem),2)==11;
    incosel=sum(ismember(stats.correct.coeff,cr.incong),2)==11;
else
    cr=bz.hist.get_stats_by_mem_type(stats,'within',opt.treedepth);
    % congsel=stats.congru.maxiter(:,1)==0 & stats.congru.same_reg(:,opt.treedepth);
    % nonmsel=stats.nonmem.maxiter(:,1)==0 & stats.nonmem.same_reg(:,opt.treedepth);
    % incosel=stats.incongru.maxiter(:,1)==0 & stats.incongru.same_reg(:,opt.treedepth);
    congsel=sum(ismember(stats.correct.coeff,cr.congru),2)==11;
    nonmsel=sum(ismember(stats.correct.coeff,cr.nonmem),2)==11;
    incosel=sum(ismember(stats.correct.coeff,cr.incong),2)==11;
end

if strcmp(opt.dir,'from'), pos=1;else, pos=2;end
congreg=cellfun(@(x) x{pos,opt.treedepth},stats.(trialtype).reg(congsel,:),'UniformOutput',false);
nonmreg=cellfun(@(x) x{pos,opt.treedepth},stats.(trialtype).reg(nonmsel,:),'UniformOutput',false);
incoreg=cellfun(@(x) x{pos,opt.treedepth},stats.(trialtype).reg(incosel,:),'UniformOutput',false);

% [GCcon,GRcon]=groupcounts(string(congreg));
% [GCnon,GRnon]=groupcounts(string(nonmreg));
% [GCinc,GRinc]=groupcounts(string(incoreg));

for i=1:size(congreg)
    CBcon{i,1}=[congreg{i,1},'_',congreg{i,2}];
end

for i=1:size(nonmreg)
    CBnon{i,1}=[nonmreg{i,1},'_',nonmreg{i,2}];
end

for i=1:size(incoreg)
    CBinc{i,1}=[incoreg{i,1},'_',incoreg{i,2}];
end

GCcon = cellfun(@(x)nnz(strcmp(CBcon,x)), unique(CBcon), 'Uniform', false);
GCnon = cellfun(@(x)nnz(strcmp(CBnon,x)), unique(CBnon), 'Uniform', false);
GCinc = cellfun(@(x)nnz(strcmp(CBinc,x)), unique(CBinc), 'Uniform', false);

GRcon = unique(CBcon);
GRnon = unique(CBnon);
GRinc = unique(CBinc);

% figure();histogram(GC,1:10:max(GC));
congrudata=fliplr(cr.congru(:,2:end))*100;
nonmdata=fliplr(cr.nonmem(:,2:end))*100;
incodata=fliplr(cr.incong(:,2:end))*100;

% con_gr=[GRcon{1,1}(GCcon>=opt.minpair),GRcon{1,2}(GCcon>=opt.minpair)];
% non_gr=[GRnon{1,1}(GCnon>=opt.minpair),GRnon{1,2}(GCnon>=opt.minpair)];
% inc_gr=[GRinc{1,1}(GCinc>=opt.minpair),GRinc{1,2}(GCinc>=opt.minpair)];

con_gr=GRcon(cell2mat(GCcon)>=opt.minpair);
non_gr=GRnon(cell2mat(GCnon)>=opt.minpair);
inc_gr=GRinc(cell2mat(GCinc)>=opt.minpair);

% sel_gr=intersect(intersect(con_gr,non_gr),inc_gr);
sel_gr=intersect(con_gr,non_gr);

dim=ceil(sqrt(numel(sel_gr)));
if strcmp(opt.plottype,'curve')
    fh=figure('Color','w','Position',[100,100,400,300]);
    for i=1:size(sel_gr)
        subplot(dim,dim,i);
        hold on;
        congci=bootci(1000,@(x) mean(x),congrudata(strcmp(CBcon,(sel_gr(i))),:));
        congmm=mean(congrudata(strcmp(CBcon,sel_gr(i)),:));
        
        nonmci=bootci(1000,@(x) mean(x),nonmdata(strcmp(CBnon,(sel_gr(i))),:));
        nonmmm=mean(nonmdata(strcmp(CBnon,sel_gr(i)),:));

        incoci=bootci(1000,@(x) mean(x),incodata(strcmp(CBinc,(sel_gr(i))),:));
        incomm=mean(incodata(strcmp(CBinc,sel_gr(i)),:));
        
        fill([pxxmin:opt.binw:pxxmax,fliplr(pxxmin:opt.binw:pxxmax)],[congci(1,:),fliplr(congci(2,:))],'r','EdgeColor','none','FaceAlpha',0.2);
        fill([pxxmin:opt.binw:pxxmax,fliplr(pxxmin:opt.binw:pxxmax)],[nonmci(1,:),fliplr(nonmci(2,:))],'k','EdgeColor','none','FaceAlpha',0.2);
        fill([pxxmin:opt.binw:pxxmax,fliplr(pxxmin:opt.binw:pxxmax)],[incoci(1,:),fliplr(incoci(2,:))],'b','EdgeColor','none','FaceAlpha',0.2);
        
        plot(pxxmin:opt.binw:pxxmax,congmm,'-r');
        plot(pxxmin:opt.binw:pxxmax,nonmmm,'-k');
        plot(pxxmin:opt.binw:pxxmax,incomm,'-b');
        ylim([-1,10]);
        title(sel_gr(i));
        text(max(xlim()),max(ylim()),...
            sprintf('n= %d, %d, %d',nnz(strcmp(CBcon,(sel_gr(i)))),nnz(strcmp(CBinc,(sel_gr(i)))),nnz(strcmp(CBnon,(sel_gr(i))))),...
            'VerticalAlignment','top','HorizontalAlignment','right')
    end
    if ~isempty(opt.title)
        sgtitle(opt.title)
    end
else
    fh=figure('Color','w','Position',[100,100,400,300]);
    hold on;
    for i=1:size(sel_gr)
        [~,congstats]=bootci(1000,@(x) sum(mean(x)),congrudata(strcmp(CBcon,(sel_gr(i))),:));
        [~,nonmstats]=bootci(1000,@(x) sum(mean(x)),nonmdata(strcmp(CBnon,(sel_gr(i))),:));
        [~,incostats]=bootci(1000,@(x) sum(mean(x)),incodata(strcmp(CBinc,(sel_gr(i))),:));
        diffc_n=congstats-nonmstats;
        mm=mean(diffc_n);
        ci=bootci(1000,@(x) mean(x),diffc_n);
        bar(i,mm,'FaceColor','w','EdgeColor','k','LineWidth',1);
        errorbar(i,mm,ci(1)-mm,ci(2)-mm,'k.');
%         ylim([-1,10]);
%         text(max(xlim()),max(ylim()),...
%             sprintf('n= %d, %d, %d',nnz(strcmp(congreg,(sel_gr(i)))),nnz(strcmp(incoreg,(sel_gr(i)))),nnz(strcmp(nonmreg,(sel_gr(i))))),...
%             'VerticalAlignment','top','HorizontalAlignment','right')
    end
    set(gca(),'XTick',1:size(sel_gr),'XTickLabel',sel_gr,'XTickLabelRotation',90);
    if ~isempty(opt.title)
        sgtitle(opt.title)
    end

end
exportgraphics(fh,'STP_cross_reg.pdf');
end




