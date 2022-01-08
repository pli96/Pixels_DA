function TitleName=ConstructDecodingTitle(TargetBrainID,DecodingForSamTestDecisionTrialType,IsLaserTrial,IsShffleDecoding,num_neuron_ForDecoding...
    ,IsNormalizedData,DecodingTimes,TestingTimes,DecodingTemplateTrialNum,LearningPhase,DecodingWithNeuronWithOdorSelectivity...
    ,DecodingForLearningOrWellTrainedPhase,GroupID,IsExcludedLickAffectedNeuron,DayID,bin_width,IsCorrectOrErrorOrAllTrials,CellType...
    ,AddSustainedNeuronWithSigBinNum,ExcludeTransientSustainedNeu,ExcludeNeuronWithReversedOdorSelectivity,IsCalculateTCTDecodingResults)

if DecodingForSamTestDecisionTrialType==1
    Title=['Decoding-' TargetBrainID '-for Sample Odor-'];
elseif DecodingForSamTestDecisionTrialType==2;
    Title=['Decoding-' TargetBrainID '-for Test Odor-'];
elseif DecodingForSamTestDecisionTrialType==3;
    Title=['Decoding-' TargetBrainID '-for Decision-'];
elseif DecodingForSamTestDecisionTrialType==4
    Title=['Decoding-' TargetBrainID '-for Trial Type-'];
end
TitleName=[Title num2str(DecodingTimes) '-' num2str(TestingTimes) '-' num2str(DecodingTemplateTrialNum) '-' num2str(bin_width) '-' num2str(num_neuron_ForDecoding)];
if IsShffleDecoding==1
    TitleName=['Shuffle' TitleName];
end

if ~isempty(LearningPhase)
    TitleName=[TitleName '-' LearningPhase];
end
if IsLaserTrial~=0
    TitleName=[TitleName '-LaserTrial'];
end
if DecodingWithNeuronWithOdorSelectivity==1
    TitleName=[TitleName '-SelecNeu'];
end
if DecodingForLearningOrWellTrainedPhase==2
    TitleName=[TitleName '-WellTrainedPhase'];
end
if IsExcludedLickAffectedNeuron==1
    TitleName=[TitleName '-ExcludedLickNeurons'];
end
if ~isempty(DayID)
    TitleName=[TitleName DayID];
end
if IsNormalizedData==1
    TitleName=[TitleName '-Norm'];
end
if IsCorrectOrErrorOrAllTrials==1
    TitleName=[TitleName '-CorrTrials'];
elseif IsCorrectOrErrorOrAllTrials==2
    TitleName=[TitleName '-ErrorTrials'];
elseif IsCorrectOrErrorOrAllTrials==3
    TitleName=[TitleName '-AllTrials'];
elseif IsCorrectOrErrorOrAllTrials==4
    TitleName=[TitleName '-Corr-ErrorTrials'];
end
if IsCalculateTCTDecodingResults==1
   TitleName=[TitleName '-TCT'];
end
TitleName=[TitleName GroupID];
if min(AddSustainedNeuronWithSigBinNum)>0&&max(AddSustainedNeuronWithSigBinNum)<=5
    TitleName=[TitleName '-AddSustEqual' num2str(AddSustainedNeuronWithSigBinNum)];
    TitleName=strrep(TitleName,'  ','-');
elseif AddSustainedNeuronWithSigBinNum==0
    TitleName=[TitleName '-NonSelectNeu'];
end
if CellType==2
    TitleName=[TitleName '-PC Neu'];
elseif CellType==3
    TitleName=[TitleName '-FSI Neu'];
end
if ExcludeTransientSustainedNeu==1%exclude transient selective neurons
    TitleName=[TitleName '-ExcTransientNeu'];
elseif ExcludeTransientSustainedNeu==2%exclude sustained selective neurons
    TitleName=[TitleName '-ExcSustainedNeu'];
elseif ExcludeTransientSustainedNeu==3%Only with transient selective neurons
    TitleName=[TitleName '-WithTransientNeu'];
elseif ExcludeTransientSustainedNeu==4%Only with sustained selective neurons
    TitleName=[TitleName '-WithSustainedNeu'];    
end
if ExcludeNeuronWithReversedOdorSelectivity==1
    TitleName=[TitleName '-ExcDelayReversedNeu'];
elseif ExcludeNeuronWithReversedOdorSelectivity==2
    TitleName=[TitleName '-ExcSam-DelayReversedNeu'];
elseif ExcludeNeuronWithReversedOdorSelectivity==3
    TitleName=[TitleName '-ExcAllReversedNeu'];
elseif ExcludeNeuronWithReversedOdorSelectivity==4
    TitleName=[TitleName '-OnlyWithAllReversedNeu'];
end