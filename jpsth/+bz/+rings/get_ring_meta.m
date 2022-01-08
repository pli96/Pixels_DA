function out=get_ring_meta(opt)
arguments
    opt.shufrpt (1,1) double = 50
    opt.savefile (1,1) logical = false
    opt.congru (1,1) logical = true
    opt.nonmem (1,1) logical = false
    opt.loadfile (1,1) logical = false
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','ODR2AFC','dual_task'})}='neupix'
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
    opt.delay (1,1) double = 6 % delay duration
end

homedir=ephys.util.getHomedir('dtype',opt.type,'type','sums');
if opt.loadfile
    load(fullfile(homedir,'ring_meta.mat'),'ring_meta');
    out=ring_meta;
else
    out=struct();
    if opt.congru
        out.congru=onetype('congru',opt.shufrpt,'type',opt.type,'criteria',opt.criteria);
    end
    if opt.nonmem
        out.nonmem=onetype('nonmem',opt.shufrpt,'type',opt.type,'criteria',opt.criteria);
    end
    if opt.savefile
        ring_meta=out;
        save(fullfile(homedir,'ring_meta.mat'),'ring_meta');
    end
end
end


%%other stats
function out=onetype(mtype,shufrpt,opt)
arguments
    mtype
    shufrpt
    opt.type (1,:) char {mustBeMember(opt.type,{'neupix','AIOPTO','ODR2AFC','dual_task'})}='neupix'
    opt.criteria (1,:) char {mustBeMember(opt.criteria,{'Learning','WT','any'})} = 'WT'
end
[out.cross_3,out.within_3]=bz.rings.rings_span('ring_size',3,'memtype',mtype,'type',opt.type,'criteria',opt.criteria);
[out.cross_4,out.within_4]=bz.rings.rings_span('ring_size',4,'memtype',mtype,'type',opt.type,'criteria',opt.criteria);
[out.cross_5,out.within_5]=bz.rings.rings_span('ring_size',5,'memtype',mtype,'type',opt.type,'criteria',opt.criteria);

[out.cross_3_shuf,out.cross_4_shuf,out.cross_5_shuf,out.within_3_shuf,out.within_4_shuf,out.within_5_shuf]=deal(cell(shufrpt,1));
for ri=1:shufrpt
    disp(ri);
    [out.cross_3_shuf{ri},out.within_3_shuf{ri}]=bz.rings.rings_span('ring_size',3,'memtype',mtype,'shufid',ri,'type',opt.type,'criteria',opt.criteria);
    [out.cross_4_shuf{ri},out.within_4_shuf{ri}]=bz.rings.rings_span('ring_size',4,'memtype',mtype,'shufid',ri,'type',opt.type,'criteria',opt.criteria);
    [out.cross_5_shuf{ri},out.within_5_shuf{ri}]=bz.rings.rings_span('ring_size',5,'memtype',mtype,'shufid',ri,'type',opt.type,'criteria',opt.criteria);
end
end
