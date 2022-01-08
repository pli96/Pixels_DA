function PlotLaserEffectsOnTCTDelayDecodingResults(CrossDayDelayDecodingAccuracy,DecodingTimesToCompare,Colors)

DayNum=size(CrossDayDelayDecodingAccuracy,2);
%ReSampleTimes=size(CrossDayDelayDecodingAccuracy,3);

CrossDayMean=zeros(2,DayNum);
% CrossDaySTD=zeros(2,DayNum);
CrossDayCI=zeros(4,DayNum);
AnovaData=zeros(DayNum*DecodingTimesToCompare,2);
CrossDayPValue=zeros(1,DayNum);
for i=1:DayNum%go through each day
    CrossDayMean(1,i)=mean(CrossDayDelayDecodingAccuracy(1,i,1:DecodingTimesToCompare));
    CrossDayMean(2,i)=mean(CrossDayDelayDecodingAccuracy(2,i,1:DecodingTimesToCompare));
    
    CrossDayCI(1:2,i)=prctile(CrossDayDelayDecodingAccuracy(1,i,1:DecodingTimesToCompare),[97.5 2.5]);
    CrossDayCI(3:4,i)=prctile(CrossDayDelayDecodingAccuracy(2,i,1:DecodingTimesToCompare),[97.5 2.5]);
    
    %     CrossDaySTD(1,i)=std(CrossDayDelayDecodingAccuracy(1,i,1:DecodingTimesToCompare));
    %     CrossDaySTD(2,i)=std(CrossDayDelayDecodingAccuracy(2,i,1:DecodingTimesToCompare));
    
    tempID=(i-1)*DecodingTimesToCompare+1:i*DecodingTimesToCompare;
    tempLaserResult=CrossDayDelayDecodingAccuracy(1,i,1:DecodingTimesToCompare);
    tempLaserResult=reshape(tempLaserResult,DecodingTimesToCompare,1);
    AnovaData(tempID,1)=tempLaserResult;
    tempControlResult=CrossDayDelayDecodingAccuracy(2,i,1:DecodingTimesToCompare);
    tempControlResult=reshape(tempControlResult,DecodingTimesToCompare,1);
    AnovaData(tempID,2)=tempControlResult;
    
    %%¡¡perform test for each day
    MeanOptoGroup=mean(CrossDayDelayDecodingAccuracy(1,i,:));
    MeanControlGroup=mean(CrossDayDelayDecodingAccuracy(2,i,:));
    if MeanOptoGroup>MeanControlGroup
        OverlapDataNum=length(find(CrossDayDelayDecodingAccuracy(2,i,:)>min(CrossDayDelayDecodingAccuracy(1,i,:))));
        p=(OverlapDataNum+1)/(length(CrossDayDelayDecodingAccuracy(1,i,:))+1);%Mixed selectivity morphs population codes in prefrontal cortex
    else
        OverlapDataNum=length(find(CrossDayDelayDecodingAccuracy(1,i,:)>min(CrossDayDelayDecodingAccuracy(2,i,:))));
        p=(OverlapDataNum+1)/(length(CrossDayDelayDecodingAccuracy(2,i,:))+1);%Mixed selectivity morphs population codes in prefrontal cortex
    end
    CrossDayPValue(1,i)=p;
end

Max=max(max(CrossDayCI([1 3],:)));
Min=min(min(CrossDayCI([2 4],:)));
Min=floor(Min/10)*10;
Max=ceil(Max/10)*10;

figure
plot(1:DayNum,CrossDayMean(1,:),'-k','color',Colors(1,:))
hold on
plot(1:DayNum,CrossDayMean(2,:),'-k','color',Colors(2,:))
for i=1:DayNum%go through each day
    plot([i i],[CrossDayCI(2,i) CrossDayCI(1,i)],'-','color',Colors(1,:))
    plot([i i],[CrossDayCI(4,i) CrossDayCI(3,i)],'-','color',Colors(2,:))
end

[p,table] = anova2(AnovaData,DecodingTimesToCompare,'off');

plot([5.2 5.2],[min(CrossDayMean(:,end)) max(CrossDayMean(:,end))],'color',[0 0 0])
PlotPValueMarker(5.3,0.15,mean(CrossDayMean(:,end)),p(1),[0 0 0],2);
text(5.3,mean(CrossDayMean(:,end))+4,['F(' num2str(table{2,3}) ',' num2str(table{3,3})  ')=' num2str(table{2,5})])

for iDay=1:DayNum
    plot([iDay-0.2 iDay+0.3],[Max*1.003 Max*1.003],'-k','linewidth',1)
    PlotPValueMarker(iDay,0.15,Max*1.01,CrossDayPValue(iDay),[0 0 0],3)
end

box off
axis([0.5 DayNum+1 Min Max*1.1])
xlabel('Day')
ylabel('Decoding accuracy (%)')
set(gca,'xtick',1:DayNum,'xticklabel',1:DayNum,'ytick',Min:10:Max,'fontsize',12)
title('Laser effects on Delay TCT decoding results','fontsize',10)