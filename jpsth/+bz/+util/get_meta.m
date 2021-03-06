%TODO move to ephys package
function [sig,pair]=get_meta(sig_id,pair_id_one_dir,fpath,opt)
arguments
    sig_id (:,2) int32
    pair_id_one_dir (:,2) int32
    fpath (1,:) char
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','MY','dual_task','ODR2AFC'})}='neupix'
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'

end
if ispc
    idmap=load(fullfile('K:','code','align','reg_ccfid_map.mat'));
elseif isunix
    idmap=load(fullfile('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code','align','reg_ccfid_map.mat'));
end
meta_str=ephys.util.load_meta('type',opt.type,'criteria',opt.criteria);
reg_map=containers.Map('KeyType','int32','ValueType','any'); %reg_map(su_id)=reg
% wf_map=containers.Map('KeyType','int32','ValueType','any');
% wrsp_map=containers.Map('KeyType','int32','ValueType','any');
% selec_map=containers.Map('KeyType','int32','ValueType','any');
mem_type_map=containers.Map('KeyType','int32','ValueType','int32');
% per_bin_map=containers.Map('KeyType','int32','ValueType','any');
% pc_stem=replace(regexp(fpath,'(?<=SPKINFO/).*$','match','once'),'/','\');
sess_idx=find(startsWith(meta_str.allpath,replace(fpath,'/','\')));
for suidx=reshape(sess_idx,1,[])
    suid=meta_str.allcid(suidx);
    acrontree=meta_str.reg_tree(:, suidx);
    ccfid=nan(1,6);
    for i=1:numel(acrontree), if isempty(acrontree{i}), ccfid(i)=0;else, ccfid(i)=idmap.reg2ccfid(acrontree{i});end;end
    reg_map(suid)=int32(ccfid);
    %     wrsp_map(suid)=meta_str.wrs_p(:,suidx);
    %     selec_map(suid)=meta_str.selec(:,suidx);
    mem_type_map(suid)=meta_str.mem_type(suidx);
    %     per_bin_map(suid)=meta_str.per_bin(:,suidx).';
    %     wf_map(suid)=meta_str.good_waveform(suidx);
end
sig=struct();
sig.suid=sig_id;
sig.reg=reshape(cell2mat(arrayfun(@(x) reg_map(x),sig_id,'UniformOutput',false)),[],6,2);
% sig.wrsp=reshape(cell2mat(arrayfun(@(x) wrsp_map(x),sig_id,'UniformOutput',false)),[],14,2);
% sig.selec=reshape(cell2mat(arrayfun(@(x) selec_map(x),sig_id,'UniformOutput',false)),[],14,2);
sig.mem_type=reshape(cell2mat(arrayfun(@(x) mem_type_map(x),sig_id,'UniformOutput',false)),[],2);
% sig.wf_good=reshape(cell2mat(arrayfun(@(x) wf_map(x),sig_id,'UniformOutput',false)),[],2);
% c=cell2mat(arrayfun(@(x) per_bin_map(x),sig_id,'UniformOutput',false));
% sig.per_bin=cat(3,c(:,1:6),c(:,7:end));

pair=struct();
if numel(pair_id_one_dir)>2
    pair.suid=pair_id_one_dir;
    pair.reg=reshape(cell2mat(arrayfun(@(x) reg_map(x),pair_id_one_dir,'UniformOutput',false)),[],6,2);
    % pair.wrsp=reshape(cell2mat(arrayfun(@(x) wrsp_map(x),pair_id_one_dir,'UniformOutput',false)),[],14,2);
    % pair.selec=reshape(cell2mat(arrayfun(@(x) selec_map(x),pair_id_one_dir,'UniformOutput',false)),[],14,2);
    pair.mem_type=reshape(cell2mat(arrayfun(@(x) mem_type_map(x),pair_id_one_dir,'UniformOutput',false)),[],2);
    % pair.wf_good=reshape(cell2mat(arrayfun(@(x) wf_map(x),pair_id_one_dir,'UniformOutput',false)),[],2);
    % c=cell2mat(arrayfun(@(x) per_bin_map(x),pair_id_one_dir,'UniformOutput',false));
    % pair.per_bin=cat(3,c(:,1:6),c(:,7:end));
end
end

