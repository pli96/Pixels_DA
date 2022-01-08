function out=procPerf(facSeq, opt)
arguments
    facSeq
    opt.mode   (1,:) char {mustBeMember(opt.mode,{'correct','all','error'})} = 'correct'
end

if length(facSeq)<40 % interrupted sessions
    out=[];
    return
end

if strcmp(opt.mode, 'error')
    errorsel=~xor(facSeq(:,5)==facSeq(:,6) , facSeq(:,7)>0); % borrow DNMS rule, as in SBCs
    out=facSeq(errorsel,:);
else
    i=40;
    ncol=width(facSeq);
    while i<=length(facSeq)
        good=xor(facSeq(i-39:i,5)==facSeq(i-39:i,6) , facSeq(i-39:i,7)>0); % borrow DNMS rule, as in SBCs
        facSeq(i-39:i,(ncol+2))=good;   % end-1->well-train, end->correct response
        if nnz(good)>=24 % 60pct correct rate
            facSeq(i-39:i,(ncol+1))=1;
        end
        i=i+1;
    end
    if strcmp(opt.mode,'correct') % rtn correct trial only
        out=facSeq(all(facSeq(:,end-1:end),2),:);
    else % 'all'
        out=facSeq;
    end
end
end



