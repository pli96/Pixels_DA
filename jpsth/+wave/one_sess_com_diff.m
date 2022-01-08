function [fh1,fh2]=one_sess_com_diff(opt)
arguments
    opt.sess (1,1) double = 18
    opt.samp (1,1) double = 1
    opt.pair (:,2) double
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','dual_task','ODR2AFC'})}='neupix'
    opt.prefix (1,:) char = 'BZWT'
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
    opt.delay (1,1) double = 6 % delay duration
end

if opt.samp==1
    odor_type=2;
    cmkey='s1';
    cckey='s1curve';
elseif opt.samp==2
    odor_type=4;
    cmkey='s2';
    cckey='s2curve';
end

homedir=ephys.util.getHomedir('dtype',opt.type,'type','raw'); % ~/Datasum directory 
com_map=wave.get_com_map('onepath',fullfile(homedir,ephys.sessid2path(opt.sess,'type',opt.type,'criteria',opt.criteria)),'curve',true,'delay',opt.delay,'type',opt.type,'criteria',opt.criteria);
fn=char(fieldnames(com_map));
[sig,~]=bz.load_sig_pair('type',opt.type,'criteria',opt.criteria,'prefix',opt.prefix);
suids=sig.suid(sig.sess==opt.sess ...
    & all(sig.mem_type==odor_type,2)...
    ,:);
cms=arrayfun(@(x) com_map.(fn).(cmkey)(x),suids);
[~,cmidx]=sort(cms(:,2));
% [~,mmidx]=sort(mean(cms,2));
mmidx=cmidx;
[immatLR,immatUD]=deal([]);
for ii=1:size(suids,1)
    immatLR=[immatLR;
        -com_map.(fn).(cckey)(suids(cmidx(ii),1)),...
        zeros(1,8),...
        com_map.(fn).(cckey)(suids(cmidx(ii),2));
        ];
    
    immatUD=[immatUD;
        -com_map.(fn).(cckey)(suids(mmidx(ii),1));...
        com_map.(fn).(cckey)(suids(mmidx(ii),2));...
        ];
    
end

fh1=figure('Color','w','Position',[100,100,235,235]);
hold on;
imagesc(immatUD,[-1,1]);
colormap(bluewhitered(256));
plot(cms(mmidx,1),(1:size(immatLR,1)).*2-1,'o','MarkerSize',2,'MarkerFaceColor',[0.5,0.5,0.5],'MarkerEdgeColor',[0.5,0.5,0.5])
plot(cms(mmidx,2),(1:size(immatLR,1)).*2,'ko','MarkerSize',2,'MarkerFaceColor','k')
set(gca(),'YDir','normal','XTick',0:8:24,'XTickLabel',0:2:6,...
'YTick',0:200:size(immatLR,1)*2,'YTickLabel',0:100:size(immatLR,1));
ylim([0,size(immatLR,1)*2]);
xlim([0,24]);
ylabel('Funcional coupling #.');
xlabel('Delay time (s)');
exportgraphics(fh1,fullfile(homedir,'..','plots',sprintf('COM_diff_%d.pdf',opt.samp)));

if false
    fh2=figure('Color','w','Position',[100,100,235,235]);
    hold on;
    imagesc(immatLR,[-1,1]);
    colormap(bluewhitered(256));
    set(gca(),'YDir','normal','XTick',0:8:56,'XTickLabel',[0:2:6,0:2:6]);
    plot(cms(cmidx,1),1:size(immatLR,1),'ko','MarkerSize',2,'MarkerFaceColor','k')
    plot(cms(cmidx,2)+24+8,1:size(immatLR,1),'ko','MarkerSize',2,'MarkerFaceColor','k')
    ylim([0,size(immatLR,1)]);
    xlim([0,48+8]);
    ylabel('Func. coupling #.');
    xlabel('Delay time (s)');
end
