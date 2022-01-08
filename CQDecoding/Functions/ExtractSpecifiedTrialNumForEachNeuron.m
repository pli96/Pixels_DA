function [RandomlyPickedRule1FR,RandomlyPickedRule2FR]=ExtractSpecifiedTrialNumForEachNeuron(tempTrialBinnedFR,AllNeuSampleTrialID...
    ,num_trial_ForEachCondition,IsShffleDecoding)

RandomlyPickedRule1FR=cell(size(tempTrialBinnedFR));
RandomlyPickedRule2FR=cell(size(tempTrialBinnedFR));
for iNeuron=1:size(tempTrialBinnedFR,2)%go through each neuron
    
    TrialIndex1=AllNeuSampleTrialID{1,iNeuron};
    TrialIndex2=AllNeuSampleTrialID{2,iNeuron};
    if IsShffleDecoding==1
        TrialIndex=[TrialIndex1;TrialIndex2];
        temp=randperm(length(TrialIndex));
        TrialIndex1=temp(1:length(TrialIndex1));
        TrialIndex2=temp(length(TrialIndex1)+1:end);
    end
    temp=randperm(length(TrialIndex1));
    if ~isempty(num_trial_ForEachCondition)
        Template1TrialIndex=TrialIndex1(temp(1:num_trial_ForEachCondition));
    else
        Template1TrialIndex=TrialIndex1;
    end
    RandomlyPickedRule1FR{1,iNeuron}=tempTrialBinnedFR{iNeuron}(Template1TrialIndex,:);
    temp2=randperm(length(TrialIndex2));
    if ~isempty(num_trial_ForEachCondition)
        Template1TrialIndex2=TrialIndex2(temp2(1:num_trial_ForEachCondition));
    else
        Template1TrialIndex2=TrialIndex2;
    end
    RandomlyPickedRule2FR{1,iNeuron}=tempTrialBinnedFR{iNeuron}(Template1TrialIndex2,:);
end
