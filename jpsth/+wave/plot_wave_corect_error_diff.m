% keyboard();
opt.type='ODR2AFC';
opt.criteria='any';
opt.delay=5;
opt.partial='full';
opt.laser='any';
opt.cell_type='ctx_sel';
homedir=ephys.util.getHomedir('dtype',opt.type,'type','raw'); % ~/DataSum directory
for sess=1:48
%     while true
        fs=sprintf('s%d',sess);
        norm_fr=wave.get_norm_fr_map('onepath',fullfile(homedir,ephys.sessid2path(sess,'type',opt.type,'criteria',opt.criteria)), ...
            'curve',true,'rnd_half',false,'per_sec_stats',false, ...
            'delay',opt.delay,'type',opt.type,'criteria',opt.criteria,'partial',opt.partial,'cell_type',opt.cell_type);
        if ~isfield(norm_fr,fs)
            disp([sess,0,0])
            continue
        end
        
        samp_key_S1=intersect(cell2mat(norm_fr.(fs).s1curve.keys),cell2mat(norm_fr.(fs).e1curve.keys));
        samp_key_S2=intersect(cell2mat(norm_fr.(fs).s2curve.keys),cell2mat(norm_fr.(fs).e2curve.keys));

%         if numel([samp_key_S1,samp_key_S2])<200
        if numel(samp_key_S1)<20 || numel(samp_key_S2)<20
            disp([sess,numel([samp_key_S1,samp_key_S2]),0])
            continue
        end

        %% s1 & s2

        % select 13 region
%         load(fullfile(homedir,'deleted_meta.mat'),'meta')
        neuronsel=meta.allcid(meta.sess==sess);
        sesssel=find(meta.sess==sess);
        sel=find(ismember(neuronsel,[samp_key_S1.';samp_key_S2.']));
        all_idx=sesssel(sel);
        selreg=meta.reg_tree(all_idx);

        immata=[cell2mat(norm_fr.(fs).s1curve.values(num2cell(samp_key_S1.')));cell2mat(norm_fr.(fs).s2curve.values(num2cell(samp_key_S2.')))];
        immatb=[cell2mat(norm_fr.(fs).e1curve.values(num2cell(samp_key_S1.')));cell2mat(norm_fr.(fs).e2curve.values(num2cell(samp_key_S2.')))];
        df=immata-immatb; % correct-error

        % sort by correct/error | tbin | peak value
        [pk,tbin]=max(abs(df),[],2); % find abs(peakvalue) and its tbin 
        neg=[];
        pos=[];
        for i=1:size(df,1)
            if df(i,tbin(i))<0
                neg=[neg;df(i,:)];
            else
                pos=[pos;df(i,:)];
            end
        end

        % sort by tbin/peak value
        [negpk,negtbin]=max(abs(neg),[],2);
        neg=[neg negpk negtbin];
        [~,sortednegtbinidx]=sortrows(neg,[22 21]);
        neg_sort=neg(sortednegtbinidx,:);

        [pospk,postbin]=max(abs(pos),[],2);
        pos=[pos pospk postbin];
        [~,sortedpostbinidx]=sortrows(pos,[22 21]);
        pos_sort=pos(sortedpostbinidx,:);

        df_final=[neg_sort(:,1:20);pos_sort(:,1:20)];
        tbin_final=[neg_sort(:,22);pos_sort(:,22)];
        [~,sortidx_final]=ismember(df_final,df,'rows');

        normscale=max(df_final,2);
        fh=figure('Color','w','Position',[680,558,1080,720]);
        hold on
%         load(fullfile(homedir,'..','xcorr','mycolor_RedBlue.mat'),'mycolor_RedBlue');
        colormap(mycolor_RedBlue)
        gk = fspecial('gaussian', [3 3], 1); % adjust std 0.3/0.4
        im=imagesc(conv2(df_final./normscale,gk,'same'),[-1 1]);
        im.AlphaData = .75;
        for i=1:size(df_final,1)
            scatter(tbin_final(i),i,20,'o','MarkerFaceColor',getRegColor(selreg{sortidx_final(i)}),'MarkerEdgeColor','none');
        end
        yline(size(neg,1)+0.5,'linewidth',1);
        set(gca(),'XTick',[0.5,20.5],'XTickLabel',[0,5]);
        colorbar();
        ylim([0.5,size(df_final./normscale,1)+0.5])
        xlim([0.5,5*4+0.5])
  
%         exportgraphics(fh,fullfile(homedir,'..','plots',sprintf('wave_correct_error_diff_%d.pdf',sess)));

%     end
end


%% Functions

function c=getRegColor(reg)
if ismember(reg,{'SS','MO'})
    c=[64,98,159]./255;
elseif ismember(reg,{'ORB','RSP','ACA','PTLp','FRP'})
    c=[220,169,88]./255;
elseif ismember(reg,{'VIS','AUD'})
    c=[133,102,40]./255;
elseif ismember(reg,{'AI','VISC','GU','PERI','ECT','TEa'})
    c=[179,34,117]./255;
elseif ismember(reg,{'PL','ILA'})
    c=[99,89,160]./255;
elseif ismember(reg,{'AON','DP','TT','PIR','TR'})
    c=[255,0,0]./255;
elseif ismember(reg,{'CEA','ACB','LS','CP'})
    c=[255,0,255]./255;
elseif ismember(reg,{'HIP','RHP'})
    c=[0,0,255]./255;
elseif ismember(reg,{'EPd'})
    c=[0,255,255]./255;
else
    c=[127,127,127]./255;
    disp('Missing grouping data')
    disp(reg)
end
end
