addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/jpsth')
homedir=ephys.util.getHomedir('dtype','neupix');
new_data=true;
if new_data
    stats=gendata('delay',6,'type','neupix','criteria','Learning');
    save(fullfile(homedir,'..','COM_half_half.mat'),'stats');
end


if ~isfile(fullfile(homedir,'..','COM_half_half.mat'))
    load(fullfile(homedir,'..','COM_half_half.mat'),'stats');
    %TODO else generate small local dataset for showcase?
    mm=mean(stats);
    ci=bootci(500,@(x) mean(x), stats);
    fh=figure('Color','w','Position',[32,32,210,100]);
    hold on
    bar(mm,0.7,'FaceColor','w','EdgeColor','k','LineWidth',1);
    errorbar(1:3,mm,ci(1,:)-mm,ci(2,:)-mm,'k.','CapSize',20,'Color',[0.5,0.5,0.5])
    ylabel('Pearson r')
    set(gca(),'XTick',1:3,'XTickLabel',{'Correct','Error','Shuffle'});
    xlim([0.5,3.5]);
    ylim([0,0.8])
    exportgraphics(fh,fullfile(homedir,'..','plots','COM_half_half_stats.pdf'))
end

function stats=gendata(opt)
arguments
    opt.to_plot (1,1) logical = false
    opt.delay (1,1) double = 6 % delay duration
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','ODR2AFC','dual_task','VDPAP'})}='neupix'
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
end

if isunix
    if isempty(gcp('nocreate'))
%         parpool(50);
    end
    rpts=500;
else
    %     if isempty(gcp('nocreate'))
    %         parpool(2)
    %     end
    rpts=3;
end

localshuff=@(x) randsample(x,numel(x));
stats=nan(rpts,2);
% [data1hsum,data2hsum]=deal([]);
for rpt=1:rpts
    disp(rpt)
    [data1hall,data2hall]=deal([]);
%     [data1hall,data2hall,dataeall]=deal([]);
    com_map=wave.get_com_map('curve',false,'rnd_half',true,'delay',opt.delay,'type',opt.type,'criteria',opt.criteria);
    for fn=reshape(fieldnames(com_map),1,[])
        fs=fn{1};
        s1key=num2cell(intersect(cell2mat(com_map.(fs).s1a.keys),cell2mat(com_map.(fs).s1b.keys)));
        s2key=num2cell(intersect(cell2mat(com_map.(fs).s2a.keys),cell2mat(com_map.(fs).s2b.keys)));
%         s1key=num2cell(intersect(cell2mat(com_map.(fs).s1a.keys),intersect(cell2mat(com_map.(fs).s1b.keys),cell2mat(com_map.(fs).s1e.keys))));
%         s2key=num2cell(intersect(cell2mat(com_map.(fs).s2a.keys),intersect(cell2mat(com_map.(fs).s2b.keys),cell2mat(com_map.(fs).s2e.keys))));
        data1h=[cell2mat(com_map.(fs).s1a.values(s1key)).';cell2mat(com_map.(fs).s2a.values(s2key)).'].*0.25;
        data2h=[cell2mat(com_map.(fs).s1b.values(s1key)).';cell2mat(com_map.(fs).s2b.values(s2key)).'].*0.25;
%         datae=[cell2mat(com_map.(fs).s1e.values(s1key)).';cell2mat(com_map.(fs).s2e.values(s2key)).'].*0.25;
        
        data1hall=[data1hall;data1h];
        data2hall=[data2hall;data2h];
%         dataeall=[dataeall;datae];
        if opt.to_plot
            [rd,pd]=corr(data1h,data2h);
            [rs,ps]=corr(data1h,localshuff(data2h));
%             [re,pe]=corr(data1h,datae);
            fh=figure('Color','w','Position',[32,32,210,210]);
            hold on;
            dh=scatter(data1h,data2h,9,'o','MarkerFaceColor','r','MarkerEdgeColor','none','MarkerFaceAlpha',0.5);
            sh=scatter(data1h,(localshuff(data2h)),9,'o','MarkerFaceColor',[0.5,0.5,0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.5);
%             eh=scatter(data1h,datae,9,'o','MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',0.5);
            xlabel('C.O.M. in 1st half trials (s)')
            ylabel('C.O.M. in 2nd half trials (s)')
            legend([dh,sh],{'No-shuffle','Shuffle'},'Location','northoutside','Orientation','horizontal')
            text(max(xlim()),max(ylim()),sprintf('%.2f,%.2f,%.2f,%.2f',rd,pd,rs,ps),'HorizontalAlignment','right','VerticalAlignment','top');
%             legend([dh,eh,sh],{'Correct','Error','Shuffle'},'Location','northoutside','Orientation','horizontal')
%             text(max(xlim()),max(ylim()),sprintf('%.2f,%.2f,%.2f,%.2f,%.2f,%.2f',rd,pd,re,pe,rs,ps),'HorizontalAlignment','right','VerticalAlignment','top');
%             keyboard();
            exportgraphics(fh,'COM_half_half.pdf');
        end
    end
    [rd,pd]=corr(data1hall,data2hall);
    [rs,ps]=corr(data1hall,localshuff(data2hall));
    stats(rpt,:)=[rd,rs];
%     [re,pe]=corr(data1hall,dataeall);
%     stats(rpt,:)=[rd,re,rs];
end
end