function [TrialIndex1,TrialIndex2]= GetTrialIndexForDecoding(DecodingForSamTestDecisionTrialType,TrialsJudgement,IsCorrectOrErrorOrAllTrials)

TrialType=unique(TrialsJudgement(:,2));
UniqueTest=unique(TrialsJudgement(:,3));
if DecodingForSamTestDecisionTrialType==1   
    if IsCorrectOrErrorOrAllTrials==1
        TrialIndex1=find(TrialsJudgement(:,2)==TrialType(1)&(TrialsJudgement(:,end-1)==1|TrialsJudgement(:,end-1)==4));
        TrialIndex2=find(TrialsJudgement(:,2)==TrialType(2)&(TrialsJudgement(:,end-1)==1|TrialsJudgement(:,end-1)==4));
    elseif IsCorrectOrErrorOrAllTrials==2
        TrialIndex1=find(TrialsJudgement(:,2)==TrialType(1)&(TrialsJudgement(:,end-1)==2|TrialsJudgement(:,end-1)==3));
        TrialIndex2=find(TrialsJudgement(:,2)==TrialType(2)&(TrialsJudgement(:,end-1)==2|TrialsJudgement(:,end-1)==3));      
    elseif IsCorrectOrErrorOrAllTrials==3
        TrialIndex1=find(TrialsJudgement(:,2)==TrialType(1));
        TrialIndex2=find(TrialsJudgement(:,2)==TrialType(2));
    end    
%     TrialIndex1=find(TrialsJudgement(:,end)==3);%only non-pairing trials
%     TrialIndex2=find(TrialsJudgement(:,end)==4);%only non-pairing trials
%     TrialType='-Non-Pair Trials';
    
%     TrialIndex1=find(TrialsJudgement(:,end)==1);%only pairing trials
%     TrialIndex2=find(TrialsJudgement(:,end)==2);%only pairing trials
%     TrialType='-Pair Trials';
    
    tempTrialType=unique(TrialsJudgement(TrialIndex1,end));
    tempResultType=unique(TrialsJudgement(TrialIndex1,end-1));    
    
elseif DecodingForSamTestDecisionTrialType==2 %decoding for test odor
    TrialIndex1=find(TrialsJudgement(:,3)==UniqueTest(1));%&(TrialsJudgement(:,end-1)==1|TrialsJudgement(:,end-1)==4));
    TrialIndex2=find(TrialsJudgement(:,3)==UniqueTest(2));%&(TrialsJudgement(:,end-1)==1|TrialsJudgement(:,end-1)==4));
elseif DecodingForSamTestDecisionTrialType==3% Decoding for Decision %noly for non-pairing trials
    TrialIndex1=find((TrialsJudgement(:,end)==3|TrialsJudgement(:,end)==4)&TrialsJudgement(:,end-1)==3);%false alarm trials
    TrialIndex2=find((TrialsJudgement(:,end)==3|TrialsJudgement(:,end)==4)&TrialsJudgement(:,end-1)==4);%correct rejection trials
elseif DecodingForSamTestDecisionTrialType==4%Decoding for Trial Type
    TrialIndex1=find(TrialsJudgement(:,end)==1|TrialsJudgement(:,end)==2);%OdorAC BD Rewarding trials
    TrialIndex2=find(TrialsJudgement(:,end)==3|TrialsJudgement(:,end)==4);%OdorAD BC No rewarding trials
end