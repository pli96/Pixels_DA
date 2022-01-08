function [AllPeakTroughDuration,FSIID,PCID]=IdentifyCellTypeBasedOnWaveform(AllWaveForm,Threshold)

AllPeakTroughDuration=zeros(length(AllWaveForm),1);
for iNeuron=1:length(AllWaveForm)
    WaveForm=AllWaveForm{iNeuron};
    [PeakTroughDuration,~,~,~,~,~]=CalculatePeakTroughDuration(WaveForm);
    AllPeakTroughDuration(iNeuron)=PeakTroughDuration;
end

FSIID=find(AllPeakTroughDuration<=Threshold);
PCID=find(AllPeakTroughDuration>Threshold);