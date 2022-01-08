%this code was used to plot temporal cross-training(TCT) decoding results for specific bin
% addpath(genpath('D:\CQ\Matlab codes')) 
clc;close all; %clear;
%PlotTCTTargetBin PlotTCT PlotTCTDecodingPermutationTest %DiffNeuGroupContriInTCTDecoding
%CompareTwoCrossDayTCTDecoding PlotCQTCTDecoding AnalizeDiagonalBasedTCTDecodingDifference
DecodingResults=dir('*CrossTemporalDecoding*.mat'); 
[DecodingResults,Legends,Colors,AreaColors]=SetControlTheLastFile(DecodingResults,'Test');
Title='Laser effects on TCT decoding';
DayID=[];
DayMarker=regexpi(DecodingResults{1},'-Day');
if ~isempty(DayMarker)
    DayID=DecodingResults{1}(DayMarker:DayMarker+5);
end
IsPlotSpecificBinDecoding=0;
IsPlotDiffTCT=0;

load(DecodingResults{1},'ShuffleDecodingTimes','ShuffleTimesForTest','TestTimes')
% TestTimes=ShuffleDecodingTimes/ShuffleTimesForTest;
PlotRange=[-0.5 7.2];
ColorBarRange=[35 85];
ColorBarRangeMarker=num2str(ColorBarRange);
ColorBarRangeMarker=strrep(ColorBarRangeMarker,'  ','-');
AllTargetTimeBin=[0 0.5 1 1.5 2 2.5 3 3.5 4 4.5 5 5.5 6 100];%
% AllTargetTimeBin=[100];%
CrossGroupBinNum=zeros(1,size(DecodingResults,1));
TotalDecodingResults=cell(3,size(DecodingResults,1));
ReTestClusterBasedPermuTestIsSignificant=cell(2,TestTimes);
AllResampleTCTDecoding=cell(1,2);
for iCondiction=1:size(DecodingResults,1)
    load(DecodingResults{iCondiction})
    
    TotalDecodingResults{1,iCondiction}=RealDecodingResults;%(StartBin:EndBin,StartBin:EndBin)
    TotalDecodingResults{2,iCondiction}=RealTCTDecodingStd;%(StartBin:EndBin,StartBin:EndBin)
    TotalDecodingResults{3,iCondiction}=ClusterBasedPermuTestIsSignificant;% (StartBin:EndBin,StartBin:EndBin)
    CrossGroupBinNum(1,iCondiction)=size(RealDecodingResults,2);
    
    AllResampleTCTDecoding{1,iCondiction}=RealCrossReSampleDecodingResults;       
    ReTestClusterBasedPermuTestIsSignificant(iCondiction,:)=AllClusterBasedPermuTestIsSignificant;
end
MinBinNum=min(CrossGroupBinNum);
X=X(1:MinBinNum);
MinBinNum=repmat({MinBinNum},size(TotalDecodingResults));
TotalDecodingResults=cellfun(@(x,y) x(1:y,1:y),TotalDecodingResults,MinBinNum,'uniformoutput',0);
significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
%%
PlotTwoTCTDecodingResults(TotalDecodingResults,X,significant_event_times,ColorBarRange,Legends)
saveas(gcf,['CrossTemporalDecoding-' Title GroupID '-' ColorBarRangeMarker '-' DayID],'fig')
saveas(gcf,['CrossTemporalDecoding-' Title GroupID '-' ColorBarRangeMarker '-' DayID],'png')
close all
%% 
[LaserDelayTCTDecoding,NLDelayTCTDecoding]=CalculateDelayTCTDecodingAccuracy(AllResampleTCTDecoding,X);
DelayBinID=find(X>1&X<6);
MinusControlTCT=TotalDecodingResults{1,1}-TotalDecodingResults{1,2};%
MeanDiffTCT=mean(mean(MinusControlTCT(DelayBinID,DelayBinID)));
%% compare the persitence of TCT decoding
TestPeriod=[0 7];
if max(max(ClusterBasedPermuTestIsSignificant))>0    
    TestBinNum=length(find(X>=TestPeriod(1)&X<TestPeriod(2)));
    
    AllOptoGroupSigBinDuration=zeros(TestTimes,TestBinNum);
    AllNLSignificantBinDuration=zeros(TestTimes,TestBinNum);
    for i=1:TestTimes
        [OptoGroupSigBinDuration,NLSignificantBinDuration]=CalculateThePersistenceOfTCTDecoding(ReTestClusterBasedPermuTestIsSignificant(:,i)...
            ,TestPeriod,X,step_size);
        if mod(i,1)==0
            CompareThePersistenceOfTwoTCTDecoding(NLSignificantBinDuration,OptoGroupSigBinDuration,TestPeriod,flipud(Legends),[DayID  '-Test-' num2str(i)])
            saveas(gcf,['The duration of TCT decoding-' Legends{1} '-' Legends{2} '-' Title '-' ColorBarRangeMarker '-' DayID '-Test-' num2str(i)],'fig')
            saveas(gcf,['The duration of TCT decoding-' Legends{1} '-' Legends{2} '-' Title  '-' ColorBarRangeMarker '-' DayID '-Test-' num2str(i)],'png')
            close all
        end
        AllOptoGroupSigBinDuration(i,:)=OptoGroupSigBinDuration;
        AllNLSignificantBinDuration(i,:)=NLSignificantBinDuration;
    end
    %% plot the curve of significant duration of TCT decoding
%     plot(X(PlotSigBinRange),SignificantBinNum(1,:),'-','color',Colors(1,:))
%     hold on   
%     plot(X(PlotSigBinRange),SignificantBinNum(2,:),'color',Colors(2,:)) 
%     EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,7.5,0,4)
%     axis([-0.5 7.2 0 7.2])    
%     close all
end
save([Title '-' Legends{1} '-' Legends{2}],'AllNLSignificantBinDuration','AllOptoGroupSigBinDuration'...
    ,'TotalDecodingResults','DecodingResults','DayID','LaserDelayTCTDecoding','NLDelayTCTDecoding')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot the difference of TCT result
if IsPlotDiffTCT==1
    ID1=regexpi(TitleName,'-MCC'); ID2=regexpi(TitleName,'-Norm');
    DecodingParameters=[TitleName(1:ID1+3) TitleName(ID2:end)];
    Marker=[Legends{1} ' minus ' Legends{2}];
    PlotDiffTCT(MinusControlTCT,X,significant_event_times,Marker,DayID)
    saveas(gcf,[Marker '-TCT-' DecodingParameters '-' ColorBarRangeMarker '-' DayID],'fig')
    saveas(gcf,[Marker '-TCT-' DecodingParameters '-' ColorBarRangeMarker '-' DayID],'png')
    close all
end
%% plot the decoding accuracy at specific training bin
if IsPlotSpecificBinDecoding==1
    PlotSigBinRange1=find(X<7.5&X>=-0.5);
    NLCrossTimeDecodingAccuracy=zeros(length(AllTargetTimeBin),size(TotalDecodingResults{1,1},2));
    for iTrainBin=1:length(AllTargetTimeBin)
        
        TargetTimeBin=AllTargetTimeBin(iTrainBin);
        TargetBinIndex=find(X>=TargetTimeBin,1);
        
        YMax=zeros(1,length(DecodingResults));
        YMin=zeros(1,length(DecodingResults));
        TargetBinTCTDecodingResults=zeros(length(DecodingResults),size(TotalDecodingResults{1,1},2));
        TargetBinTCTDecodingStd=zeros(length(DecodingResults),size(TotalDecodingResults{1,1},2));
        TargetBinIsSignificant=zeros(length(DecodingResults),size(TotalDecodingResults{1,1},2));
        for iCondiction=1:size(DecodingResults,1)
            if TargetTimeBin==100%diagonal, train and test with the same time bin
                TargetBinTCTDecodingResults(iCondiction,:)=diag(TotalDecodingResults{1,iCondiction})';
                TargetBinTCTDecodingStd(iCondiction,:)=diag(TotalDecodingResults{2,iCondiction})';
                TargetBinIsSignificant(iCondiction,:)=diag(TotalDecodingResults{3,iCondiction})';
            else
                TargetBinTCTDecodingResults(iCondiction,:)=TotalDecodingResults{1,iCondiction}(TargetBinIndex,:);
                TargetBinTCTDecodingStd(iCondiction,:)=TotalDecodingResults{2,iCondiction}(TargetBinIndex,:);
                TargetBinIsSignificant(iCondiction,:)=TotalDecodingResults{3,iCondiction}(TargetBinIndex,:);
                if iCondiction==2
                    NLCrossTimeDecodingAccuracy(iTrainBin,:)=TotalDecodingResults{1,iCondiction}(TargetBinIndex,:);
                end
            end
            YMax(1,iCondiction)=max(TargetBinTCTDecodingResults(iCondiction,:)+TargetBinTCTDecodingStd(iCondiction,:));
            YMin(1,iCondiction)=min(TargetBinTCTDecodingResults(iCondiction,:)-TargetBinTCTDecodingStd(iCondiction,:));
        end
        
        figure
        AddLegend(Legends,Colors,'northeast')
        hold on
        for iCondiction=1:length(DecodingResults)
            PlotMeanSEM(TargetBinTCTDecodingResults(iCondiction,PlotSigBinRange1),X(PlotSigBinRange1)...
                ,[AreaColors(iCondiction,:);Colors(iCondiction,:)],TargetBinTCTDecodingStd(iCondiction,PlotSigBinRange1));
            for iBin=PlotSigBinRange1
                if TargetBinIsSignificant(iCondiction,iBin)==1
                    plot(X(iBin),0.35+iCondiction*0.02,'.','color',Colors(iCondiction,:),'markersize',4)
                end
            end
        end
        EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,max(YMax),min(YMin));
        plot([-2 max(X)],[0.5 0.5],'--k','linewidth',1)
        xlabel('Time from sample onset(s)','fontsize',14)
        ylabel('Decoding Accuracy','fontsize',14)
        set(gca,'fontsize',14,'TickDir','out')
        axis([-1 7.2 0.35 max(YMax)*1.05])
        if TargetTimeBin==100
            PostFix='Diagonal';
        else
            TimeMarker=num2str(TargetTimeBin);
            TimeMarker=strrep(TimeMarker,'.','-');
            PostFix=[TimeMarker ' second'];
        end
        title(['Train time the ' PostFix],'fontsize',14)
        saveas(gcf,['TCT decoding for sample odor train with the-' PostFix DayID '-' ColorBarRangeMarker],'fig')%
        saveas(gcf,['TCT decoding for sample odor train with the-' PostFix DayID '-' ColorBarRangeMarker],'png')%
        ResizeFigureForPaper(['TCT decoding for sample odor train with the-' PostFix DayID '-' ColorBarRangeMarker],[1 1],[-0.5 7.2 0.3 1]...
            ,0,[-2 0 2 4 6 8],[0.2 0.4 0.6 0.8 1])
        close all
    end
end