% keyboard();
opt.type='ODR2AFC';
opt.criteria='any';
opt.delay=5;
opt.partial='full';
opt.laser='any';
homedir=ephys.util.getHomedir('dtype',opt.type,'type','raw'); % ~/DataSum directory
for sess=6
%     while true
        fs=sprintf('s%d',sess);
        com_map=wave.get_com_map('onepath',fullfile(homedir,ephys.sessid2path(sess,'type',opt.type,'criteria',opt.criteria)),'curve',true,'rnd_half',true,'per_sec_stats',false,'delay',opt.delay,'type',opt.type,'criteria',opt.criteria,'laser',opt.laser,'partial',opt.partial);
        if ~isfield(com_map,fs)
            disp([sess,0,0])
            continue
        end
        
        samp_key_S1=intersect(intersect(intersect(cell2mat(com_map.(fs).e1a.keys),cell2mat(com_map.(fs).e1b.keys)),cell2mat(com_map.(fs).s1a.keys)),cell2mat(com_map.(fs).s1b.keys));
        samp_key_S2=intersect(intersect(intersect(cell2mat(com_map.(fs).e2a.keys),cell2mat(com_map.(fs).e2b.keys)),cell2mat(com_map.(fs).s2a.keys)),cell2mat(com_map.(fs).s2b.keys));

        % error trial COM as sample
        COMS1a=cell2mat(values(com_map.(fs).e1a,num2cell(samp_key_S1)));
        COMS2a=cell2mat(values(com_map.(fs).e2a,num2cell(samp_key_S2)));
        COMS1b=cell2mat(values(com_map.(fs).e1b,num2cell(samp_key_S1)));
        COMS2b=cell2mat(values(com_map.(fs).e2b,num2cell(samp_key_S2)));
        % correct trial COM as reference
        ref_COMS1a=cell2mat(values(com_map.(fs).s1a,num2cell(samp_key_S1)));
        ref_COMS2a=cell2mat(values(com_map.(fs).s2a,num2cell(samp_key_S2)));        
        ref_COMS1b=cell2mat(values(com_map.(fs).s1b,num2cell(samp_key_S1)));
        ref_COMS2b=cell2mat(values(com_map.(fs).s2b,num2cell(samp_key_S2)));

%         if numel([samp_key_S1,samp_key_S2])<200
        if numel(samp_key_S1)<20 || numel(samp_key_S2)<20
            disp([sess,numel([samp_key_S1,samp_key_S2]),0])
            continue
        end

        % correlation between first half trials and second half trials
        r1=corr([ref_COMS1a,ref_COMS2a].',...
            [ref_COMS1b,ref_COMS2b].');
        r2=corr([COMS1a,COMS2a].',...
            [COMS1b,COMS2b].');

        % discard sessions with low correlations
        if r1<0.75
            disp([sess,numel([samp_key_S1,samp_key_S2]),r1, r2])
            continue
        end

        %% s1 & s2
        % error trial COM
        sortmata=[ones(size(COMS1a)),2*ones(size(COMS2a));...
            double(samp_key_S1),double(samp_key_S2);...
            COMS1a,COMS2a].';
        sortmatb=[ones(size(COMS1b)),2*ones(size(COMS2b));...
            double(samp_key_S1),double(samp_key_S2);...
            COMS1b,COMS2b].';      

        % correct trial COM
        ref_sortmata=[ones(size(ref_COMS1a)),2*ones(size(ref_COMS2a));...
            double(samp_key_S1),double(samp_key_S2);...
            ref_COMS1a,ref_COMS2a].';
        ref_sortmatb=[ones(size(ref_COMS1b)),2*ones(size(ref_COMS2b));...
            double(samp_key_S1),double(samp_key_S2);...
            ref_COMS1b,ref_COMS2b].';        

        % correct trials first half
        immata=[cell2mat(com_map.(fs).s1acurve.values(num2cell(samp_key_S1.')));cell2mat(com_map.(fs).s2acurve.values(num2cell(samp_key_S2.')))];
        % correct trials second half
        immatb=[cell2mat(com_map.(fs).s1bcurve.values(num2cell(samp_key_S1.')));cell2mat(com_map.(fs).s2bcurve.values(num2cell(samp_key_S2.')))];
        % error trials first half
        immatc=[cell2mat(com_map.(fs).e1acurve.values(num2cell(samp_key_S1.')));cell2mat(com_map.(fs).e2acurve.values(num2cell(samp_key_S2.')))];
        % error trials second half
        immatd=[cell2mat(com_map.(fs).e1bcurve.values(num2cell(samp_key_S1.')));cell2mat(com_map.(fs).e2bcurve.values(num2cell(samp_key_S2.')))];

        fh=plot_multi(immata,immatb,immatc,immatd,ref_sortmata,ref_sortmatb,sortmata,sortmatb);
        sgtitle(sprintf('session=%d, r_correct=%.3f, r_error=%.3f',sess,r1,r2));
       
        exportgraphics(fh,fullfile(homedir,'..','plots',sprintf('wave_half_half_%d_comparison_%s.pdf',sess,opt.partial)));

%     end
end


%% Functions

function fh=plot_multi(immata,immatb,immatc,immatd,TCOMa,TCOMb,TCOMc,TCOMd)
[sortedTCOMa,sortidx]=sortrows(TCOMa,3);
sortedTCOMb=TCOMb(sortidx,:);
sortedTCOMc=TCOMc(sortidx,:);
sortedTCOMd=TCOMd(sortidx,:);
normscale=max(abs([immata,immatb,immatc,immatd]),[],2);
fh=figure('Color','w','Position',[32,32,1080,140]);
plotOne(1,immata(sortidx,:)./normscale(sortidx),sortedTCOMa(:,3));
plotOne(2,immatb(sortidx,:)./normscale(sortidx),sortedTCOMb(:,3));
plotOne(3,immatc(sortidx,:)./normscale(sortidx),sortedTCOMc(:,3));
plotOne(4,immatd(sortidx,:)./normscale(sortidx),sortedTCOMd(:,3));
shufidx=randsample(size(immata,1),size(immata,1));
plotOne(5,immata(shufidx,:)./normscale(sortidx),TCOMa(shufidx,3));
end


function plotOne(subidx,imdata,comdata)
subplot(1,5,subidx);
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

