function [LaserDelayTCTDecoding,NLDelayTCTDecoding]=CalculateDelayTCTDecodingAccuracy(AllResampleTCTDecoding,X)

DelayBinID=find(X>1&X<6);
ResampleTimes=size(AllResampleTCTDecoding{1},1);
LaserDelayTCTDecoding=zeros(1,ResampleTimes);
NLDelayTCTDecoding=zeros(1,ResampleTimes);
for i=1:ResampleTimes    
    LaserDelayTCTDecoding(1,i)=mean(mean(AllResampleTCTDecoding{1}(i,DelayBinID,DelayBinID)));
    NLDelayTCTDecoding(1,i)=mean(mean(AllResampleTCTDecoding{2}(i,DelayBinID,DelayBinID)));    
end