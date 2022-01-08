function [TrialIndex1,TrialIndex2,TrialBinnedFR]=ConstrucSingleNeuForDecoding...
    (DecodingForSamTestDecisionTrialType,TrialsJudgement,IsCorrectOrErrorOrAllTrials,SequentialAllSP...
    ,bin_width,step_size,MeanTrialLength,Decodingclassifier,NotComputeLastSecondNum,StartTime)

%% get the target trial index according to the identity of the first odorant
if IsCorrectOrErrorOrAllTrials==4%correct trials as template, error trials as test
   IsCorrectOrErrorOrAllTrials=1;%correct trials only 
end
[TrialIndex1,TrialIndex2]= GetTrialIndexForDecoding(DecodingForSamTestDecisionTrialType,TrialsJudgement,IsCorrectOrErrorOrAllTrials);
TrialBinnedFR=ConstructBinnedDataForNDT(SequentialAllSP,1:size(SequentialAllSP,2),bin_width,step_size,MeanTrialLength,Decodingclassifier);

StartBinNum=StartTime/(step_size/1000)+1;
EndBinNum=size(TrialBinnedFR,2)-NotComputeLastSecondNum/(step_size/1000);
TrialBinnedFR=TrialBinnedFR(:,StartBinNum:EndBinNum);

% %shuffle the data
% TrialIndex=[TrialIndex1;TrialIndex2];
% temp=randperm(length(TrialIndex));
% ShuffleSample1=temp(1:round(length(temp)/2));
% ShuffleSample2=temp(round(length(temp)/2)+1:length(temp));
% tempShuffleRule1FR=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex(ShuffleSample1),bin_width,step_size,MeanTrialLength,Decodingclassifier);
% tempShuffleRule2FR=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex(ShuffleSample2),bin_width,step_size,MeanTrialLength,Decodingclassifier);
% tempShuffleRule1FR=tempShuffleRule1FR(:,StartBinNum:EndBinNum);
% tempShuffleRule2FR=tempShuffleRule2FR(:,StartBinNum:EndBinNum);