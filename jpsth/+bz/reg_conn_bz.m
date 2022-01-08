function reg_conn_bz(opt)
arguments
    opt.data (:,1) struct =[]
    opt.prefix (1,:) char = 'BZWT'
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','ODR2AFC','dual_task','VDPAP'})}='neupix'
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
    opt.delay (1,1) double = 6
    opt.inhibit (1,1) logical = false;
end

%TODO merge with load_sig_pair script
homedir=ephys.util.getHomedir('dtype',opt.type); % ~/xcorr directory

if isempty(opt.data)
    if strcmp(opt.type,'neupix')
        if ~strcmp(opt.criteria,'Learning')
            if opt.inhibit
                load('sums_conn_inhibit.mat','sums_conn_str')
            else
                load('sums_conn.mat','sums_conn_str')
            end
        else
            load('sums_conn_learning.mat','sums_conn_str')
        end
    elseif strcmp(opt.type,'ODR2AFC') || strcmp(opt.type,'dual_task') || strcmp(opt.type,'VDPAP')
        load(fullfile(homedir,'..','sums_conn.mat'),'sums_conn_str')
    else
        load(fullfile(homedir,'..','bz0313_sums_conn.mat'),'sums_conn_str')
    end
else
    sums_conn_str=opt.data;
end

[~,index] = sortrows({sums_conn_str.folder}.'); sums_conn_str = sums_conn_str(index); clear index

fprintf('Total sessions %d\n',length(sums_conn_str));

for fidx=1:length(sums_conn_str)
    tic
    disp(fidx);
    fpath=sums_conn_str(fidx).folder; %session data folder
    if strcmp(opt.type,'neupix') || strcmp(opt.type,'ODR2AFC') || strcmp(opt.type,'dual_task') || strcmp(opt.type,'VDPAP')
        pc_stem=fpath;
        inputpath=dir(fullfile(homedir,'..','DataSum',pc_stem,'*','FR_All_1000.hdf5'));
        inputf=fullfile(inputpath.folder,inputpath.name);
        all_su=int32(h5read(inputf,'/SU_id'))+fidx*100000;
    else
        pc_stem=fpath;
        inputf=fullfile(homedir,'..','DataSum',fpath,'FT_SPIKE.mat');
        fstr=load(inputf);
        all_su=int32(cellfun(@(x) str2double(x),fstr.FT_SPIKE.label));
    end
 
    sig_con=int32(sums_conn_str(fidx).sig_con); % significant functional coupling
    if numel(sig_con)==2, sig_con=reshape(sig_con,1,2);end
    pair_comb_one_dir=nchoosek(all_su,2); % all pairs combination
    [sig_meta,pair_meta]=bz.util.get_meta(sig_con,pair_comb_one_dir,pc_stem,'type',opt.type,'criteria',opt.criteria,'delay',opt.delay); % assign meta info
    
    %mirror unidirection pair data
%     fields={'suid','reg','mem_type','per_bin','wf_good'};
    fields={'suid','reg','mem_type'};
    for fi=fields
        %TODO online genenrate session tag
%         sig.(fi{1})=cat(1,sig.(fi{1}),sig_meta.(fi{1}));
        pair_meta.(fi{1})=cat(1,pair_meta.(fi{1}),flip(pair_meta.(fi{1}),ndims(pair_meta.(fi{1})))); %uni-dir to bi-dir
%         pair.(fi{1})=cat(1,pair.(fi{1}),pair_meta.(fi{1}));
    end
    if opt.inhibit
        save(fullfile(homedir,'bzdata',sprintf('%s_conn_w_reg_%d_inhibitory.mat',opt.prefix,fidx)),'sig_meta','pair_meta','pc_stem','-v7.3','-nocompression')
    else
        save(fullfile(homedir,'bzdata',sprintf('%s_conn_w_reg_%d.mat',opt.prefix,fidx)),'sig_meta','pair_meta','pc_stem','-v7.3','-nocompression')
    end
    toc
end
end


