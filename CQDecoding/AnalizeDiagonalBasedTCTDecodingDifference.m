%This code was used to compute the difference of TCT decoding accuracy based
% on the separation from the diagonal after removing different groups of neurons
clc;close all; %clear;
%PlotTCTTargetBin PlotTCT PlotTCTDecodingPermutationTest %DiffNeuGroupContriInTCTDecoding
%CompareTwoCrossDayTCTDecoding PlotCQTCTDecoding
DecodingResults=dir('*CrossTemporalDecoding*.mat');

CrossGroupDecodingResults=cell(1,size(DecodingResults,1));
for i=1:size(DecodingResults,1)    
    load(DecodingResults(i).name,'RealCrossReSampleDecodingResults','GroupID','X','DelayMN','OdorMN')
    CrossGroupDecodingResults{i}=RealCrossReSampleDecodingResults;
end
TimeLampsedSampleDelayBinID = find(X>0&X<OdorMN+DelayMN+OdorMN);
SampleDelayTCTDecodingResults=cell(1,size(DecodingResults,1));
for i=1:length(CrossGroupDecodingResults)
    SampleDelayTCTDecodingResults{i}=CrossGroupDecodingResults{i}(:,TimeLampsedSampleDelayBinID,TimeLampsedSampleDelayBinID);
end
%% compute the difference of decoding accuracy after removing transient or sustained neurons
SamDelayBinNum=length(TimeLampsedSampleDelayBinID);
ReSampleTimes=size(RealCrossReSampleDecodingResults,1);
DiffControlTransientRemovedGroups=zeros(ReSampleTimes,SamDelayBinNum);
DiffControlSustainedRemovedGroups=zeros(ReSampleTimes,SamDelayBinNum);
for iResample=1:ReSampleTimes
    %% compute the difference of TCT decoding between control and transient-neu-removed group
    tempContTransDiff=SampleDelayTCTDecodingResults{1}(iResample,:,:)-SampleDelayTCTDecodingResults{3}(iResample,:,:);
    tempContTransDiff=reshape(tempContTransDiff,SamDelayBinNum,SamDelayBinNum);
    
    tempDiffContTransientDecoding=cell(1,SamDelayBinNum);
    for iTrainBin=1:SamDelayBinNum%go through each train bin
        for iTestBin=1:SamDelayBinNum%go through each test bin
            TimeSeparation=abs(iTestBin-iTrainBin);
            tempDiffContTransientDecoding{TimeSeparation+1}=[tempDiffContTransientDecoding{TimeSeparation+1};tempContTransDiff(iTrainBin,iTestBin)];
        end
    end
    MeanDiffContTransDecoding=cellfun(@mean,tempDiffContTransientDecoding);
    DiffControlTransientRemovedGroups(iResample,:)=MeanDiffContTransDecoding;
    %% compute the difference of TCT decoding between control and sustained-neu-removed group
    tempContSustDiff=SampleDelayTCTDecodingResults{1}(iResample,:,:)-SampleDelayTCTDecodingResults{2}(iResample,:,:);
    tempContSustDiff=reshape(tempContSustDiff,SamDelayBinNum,SamDelayBinNum);
    
    tempDiffContSustainedDecoding=cell(1,SamDelayBinNum);
    for iTrainBin=1:SamDelayBinNum%go through each train bin
        for iTestBin=1:SamDelayBinNum%go through each test bin
            TimeSeparation=abs(iTestBin-iTrainBin);
            tempDiffContSustainedDecoding{TimeSeparation+1}=[tempDiffContSustainedDecoding{TimeSeparation+1};tempContSustDiff(iTrainBin,iTestBin)];
        end
    end
    MeanDiffContSustDecoding=cellfun(@mean,tempDiffContSustainedDecoding);
    DiffControlSustainedRemovedGroups(iResample,:)=MeanDiffContSustDecoding;
end
%% plot the difference of TCT decoding results according to the separation time to the diagonal
DiffControlTransientRemovedGroups1=DiffControlTransientRemovedGroups*100;
DiffControlSustainedRemovedGroups1=DiffControlSustainedRemovedGroups*100;
tempX=X(TimeLampsedSampleDelayBinID);
figure
AddLegend([{'Control-TransiendNeuronRemoved'};{'Control-SustainedNeuronRemoved'}],[1 0 0;0 0 0],'northeast',10,[{'-'};{'-'}])
hold on
% Control vs transient-neuron removed groups
% SEM1=std(DiffControlTransientRemovedGroups)/sqrt(size(DiffControlTransientRemovedGroups,1))*100;
CI1=prctile(DiffControlTransientRemovedGroups1,[2.5 97.5],1);CI1=flipud(CI1);
[YMin,YMax]=PlotMeanSEM(DiffControlTransientRemovedGroups1,tempX,[1 0.6 0.6;1 0 0],[tempX(1) tempX(end)],'-',1,CI1,0);
SigBinID=find(CI1(2,:)>0);
plot(tempX(SigBinID),-5*ones(1,length(SigBinID)),'.r','markersize',5)
%  Control vs sustained-neuron removed groups
% SEM2=std(DiffControlSustainedRemovedGroups)/sqrt(size(DiffControlSustainedRemovedGroups,1))*100;
CI2=prctile(DiffControlSustainedRemovedGroups1,[2.5 97.5],1);CI2=flipud(CI2);
PlotMeanSEM(DiffControlSustainedRemovedGroups1,tempX,[0.6 0.6 0.6;0 0 0],[tempX(1) tempX(end)],'-',1,CI2,0);
SigBinID2=find(CI2(2,:)>0);
if ~isempty(SigBinID2)
plot(tempX(SigBinID2),-5*ones(1,length(SigBinID2)),'.r','markersize',5)
end
ylim([floor(YMin) ceil(YMax)])
xlabel('Time separation from diagonal (s)')
ylabel('Decoding difference')
title('Difference of TCT decoding accuracy')
saveas(gcf,'Difference of decoding accuracy based on the separation time to diagonal','fig')%
saveas(gcf,'Difference of decoding accuracy based on the separation time to diagonal','png')%
close all
%%
% tempDecodingResults=SampleDelayTCTDecodingResults{1};
% tempDecodingResults=mean(tempDecodingResults,1);
% tempDecodingResults=reshape(tempDecodingResults,size(tempDecodingResults,2),size(tempDecodingResults,3));% 
% imagesc(tempX,tempX,tempDecodingResults*100,[35 85]);%[45 85]
% hold on
% significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
% for iEvent = 1:length(significant_event_times)
%     plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
%     plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
% end
% colorbar('ytick',[30 40 50 60 70 80],'yticklabel',[30 40 50 60 70 80])
% set(gca,'xtick',[0 2 4 6 8 10 12 14], 'XTickLabel', [0 2 4 6 8 10 12 14],'ytick',[0 2 4 6 8 10 12 14], 'yTickLabel', [0 2 4 6 8 10 12 14],'TickLength',[0.025, 0.025],'linewidth',1);%add by CQ
% axis([-0.5 DelayMN+OdorMN*2+0.5 -0.5 DelayMN+OdorMN*2+0.5])
% xlabel('Test time (s)','fontsize',12)
% ylabel('Train time (s)','fontsize',12)
% axis xy