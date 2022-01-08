function [OptoGroupSigBinDuration,NLSignificantBinDuration]=CalculateThePersistenceOfTCTDecoding(CrossGroupClusterBasedPermuTestIsSignificant...
    ,TestPeriod,X,step_size)

StartBin=find(X>=TestPeriod(1),1);
EndBin=find(X<TestPeriod(2), 1, 'last' );
PlotSigBinRange=StartBin:EndBin;
SignificantBinNum=zeros(length(CrossGroupClusterBasedPermuTestIsSignificant),EndBin-StartBin+1);
for iTrainBin=StartBin:EndBin
    for i=1:length(CrossGroupClusterBasedPermuTestIsSignificant)
        SignificantBinNum(i,iTrainBin-StartBin+1)=length(find(CrossGroupClusterBasedPermuTestIsSignificant{i}(iTrainBin,PlotSigBinRange)==1));
    end
end
SignificantBinNum=SignificantBinNum*step_size/1000;
%SignificantBinNum(SignificantBinNum~=0)=SignificantBinNum(SignificantBinNum~=0)+bin_width/1000;
OptoGroupSigBinDuration=SignificantBinNum(1,:);
NLSignificantBinDuration=SignificantBinNum(2,:);

