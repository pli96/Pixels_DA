% keyboard();
opt.type='ODR2AFC';
opt.criteria='any';
opt.delay=5;
homedir=ephys.util.getHomedir('dtype',opt.type,'type','raw'); % ~/DataSum directory
for sess=2:48
%     while true
        fs=sprintf('s%d',sess);
        com_map=wave.get_com_map('onepath',fullfile(homedir,ephys.sessid2path(sess,'type',opt.type,'criteria',opt.criteria)),'curve',true,'rnd_half',true,'per_sec_stats',false,'delay',opt.delay,'type',opt.type,'criteria',opt.criteria,'laser','any','partial','full');
        if ~isfield(com_map,fs)
            disp([sess,0,0])
            continue
        end        
        samp_key_S1=intersect(cell2mat(com_map.(fs).s1a.keys),cell2mat(com_map.(fs).s1b.keys));
        samp_key_S2=intersect(cell2mat(com_map.(fs).s2a.keys),cell2mat(com_map.(fs).s2b.keys));
        COMS1=cell2mat(values(com_map.(fs).s1a,num2cell(samp_key_S1)));
        COMS2=cell2mat(values(com_map.(fs).s2a,num2cell(samp_key_S2)));
%         if numel([samp_key_S1,samp_key_S2])<200
        if numel(samp_key_S1)<20 || numel(samp_key_S2)<20
            disp([sess,numel([samp_key_S1,samp_key_S2]),0])
            continue
        end
        r=corr([COMS1,COMS2].',...
            [cell2mat(values(com_map.(fs).s1b,num2cell(samp_key_S1))),...
            cell2mat(values(com_map.(fs).s2b,num2cell(samp_key_S2)))].');
        if r<0.75
            disp([sess,numel([samp_key_S1,samp_key_S2]),r])
            continue
        end
        
        %% s1
        immata=cell2mat(com_map.(fs).s1acurve.values(num2cell(samp_key_S1.')));
        immatb=cell2mat(com_map.(fs).s1bcurve.values(num2cell(samp_key_S1.')));
        immat_anti=cell2mat(com_map.(fs).s1aanticurve.values(num2cell(samp_key_S1.')));
        TCOMb=cell2mat(com_map.(fs).s1b.values(num2cell(samp_key_S1.')));
        fh1=plot_multi(immata,immatb,immat_anti,COMS1,TCOMb);
        sgtitle(sprintf('session=%d, r=%.3f, pref=S%d',sess,r,1));
        
        %% s2
        immata=cell2mat(com_map.(fs).s2acurve.values(num2cell(samp_key_S2.')));
        immatb=cell2mat(com_map.(fs).s2bcurve.values(num2cell(samp_key_S2.')));
        immat_anti=cell2mat(com_map.(fs).s2aanticurve.values(num2cell(samp_key_S2.')));
        TCOMb=cell2mat(com_map.(fs).s2b.values(num2cell(samp_key_S2.')));
        fh2=plot_multi(immata,immatb,immat_anti,COMS2,TCOMb);
        sgtitle(sprintf('session=%d, r=%.3f, pref=S%d',sess,r,2));

        %% s1 & s2
        sortmat=[ones(size(COMS1)),2*ones(size(COMS2));...
            double(samp_key_S1),double(samp_key_S2);...
            COMS1,COMS2].';
        sortmat=sortrows(sortmat,3);
        immata=[];
        for ri=1:size(sortmat,1)
            one_heat=com_map.(fs).(sprintf('s%daheat',sortmat(ri,1)))(sortmat(ri,2));
            immata=[immata;one_heat];
        end
        immatb=[];
        com_b=[];
        for ri=1:size(sortmat,1)
            one_heat=com_map.(fs).(sprintf('s%dbheat',sortmat(ri,1)))(sortmat(ri,2));
            immatb=[immatb;one_heat];
            com_b=[com_b;com_map.(fs).(sprintf('s%db',sortmat(ri,1)))(sortmat(ri,2))];
        end
        fh3=figure('Color','w','Position',[32,32,1080,140]);
        plotOne(1,immata,sortmat(:,3));
        plotOne(2,immatb,com_b);
        shufidx=randsample(size(immatb,1),size(immatb,1));
        plotOne(3,immatb(shufidx,:),com_b(shufidx));
        sgtitle(sprintf('session=%d, r=%.3f',sess,r));
       
        exportgraphics(fh1,fullfile(homedir,'..','plots',sprintf('wave_half_half_%d_S1.pdf',sess)));
        exportgraphics(fh2,fullfile(homedir,'..','plots',sprintf('wave_half_half_%d_S2.pdf',sess)));
        exportgraphics(fh3,fullfile(homedir,'..','plots',sprintf('wave_half_half_%d.pdf',sess)));

%     end
end

%% Functions

function fh=plot_multi(immata,immatb,immat_anti,TCOMa,TCOMb)
[sortedTCOM,sortidx]=sort(TCOMa);
normscale=max(abs([immata,immatb,immat_anti]),2);
fh=figure('Color','w','Position',[32,32,1080,140]);
plotOne(1,immata(sortidx,:)./normscale(sortidx).',sortedTCOM);
plotOne(2,immatb(sortidx,:)./normscale(sortidx).',TCOMb(sortidx));
shufidx=randsample(size(immatb,1),size(immatb,1));
plotOne(3,immatb(shufidx,:)./normscale(sortidx).',TCOMb(shufidx));
plotOne(4,immat_anti(sortidx,:)./normscale(sortidx).')
end


function plotOne(subidx,imdata,comdata)
subplot(1,4,subidx);
hold on
colormap('turbo');
gk = fspecial('gaussian', [3 3], 1);
imagesc(conv2(imdata,gk,'same'),[-1 1])
if exist('comdata','var') && ~isempty(comdata)
    scatter(comdata,1:numel(comdata),2,'o','MarkerFaceColor','k','MarkerFaceAlpha',0.5,'MarkerEdgeColor','none');
end
set(gca(),'XTick',[0.5,20.5],'XTickLabel',[0,5]);
colorbar();
ylim([0.5,size(imdata,1)+0.5])
xlim([0.5,5*4+0.5])
end



