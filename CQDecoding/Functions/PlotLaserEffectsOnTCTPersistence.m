function PlotLaserEffectsOnTCTPersistence(CrossDayPersistence,Colors)

DayNum=size(CrossDayPersistence,2);
TestTimes=size(CrossDayPersistence,3);

CrossDayMean=zeros(2,DayNum);
% CrossDaySTD=zeros(2,DayNum);
CrossDayCI=zeros(4,DayNum);
AnovaData=zeros(DayNum*TestTimes,2);
CrossDayPValue=zeros(1,DayNum);
for i=1:DayNum%go through each day
    CrossDayMean(1,i)=mean(CrossDayPersistence(1,i,:));
    CrossDayMean(2,i)=mean(CrossDayPersistence(2,i,:));
    
    CrossDayCI(1:2,i)=prctile(CrossDayPersistence(1,i,:),[97.5 2.5]);
    CrossDayCI(3:4,i)=prctile(CrossDayPersistence(2,i,:),[97.5 2.5]);
    
%     CrossDaySTD(1,i)=std(CrossDayPersistence(1,i,:));
%     CrossDaySTD(2,i)=std(CrossDayPersistence(2,i,:));
    
    tempID=(i-1)*TestTimes+1:i*TestTimes;
    tempLaserResult=CrossDayPersistence(1,i,:);
    tempLaserResult=reshape(tempLaserResult,TestTimes,1);
    AnovaData(tempID,1)=tempLaserResult;
    tempControlResult=CrossDayPersistence(2,i,:);
    tempControlResult=reshape(tempControlResult,TestTimes,1);
    AnovaData(tempID,2)=tempControlResult;
    
    %%¡¡perform test for each day       
    MeanOptoGroup=mean(CrossDayPersistence(1,i,:));
    MeanControlGroup=mean(CrossDayPersistence(2,i,:));
    if MeanOptoGroup>MeanControlGroup
        OverlapDataNum=length(find(CrossDayPersistence(2,i,:)>min(CrossDayPersistence(1,i,:))));
        p=(OverlapDataNum+1)/(length(CrossDayPersistence(1,i,:))+1);%Mixed selectivity morphs population codes in prefrontal cortex
    else
        OverlapDataNum=length(find(CrossDayPersistence(1,i,:)>min(CrossDayPersistence(2,i,:))));
        p=(OverlapDataNum+1)/(length(CrossDayPersistence(2,i,:))+1);%Mixed selectivity morphs population codes in prefrontal cortex
    end
    CrossDayPValue(1,i)=p;
end
Max=max(max(CrossDayCI([1 3],:)));
Min=min(min(CrossDayCI([2 4],:)));

figure
plot(1:DayNum,CrossDayMean(1,:),'-k','color',Colors(1,:),'linewidth',1)
hold on
plot(1:DayNum,CrossDayMean(2,:),'-k','color',Colors(2,:),'linewidth',1)
for i=1:DayNum%go through each day
    plot([i i],[CrossDayCI(2,i) CrossDayCI(1,i)],'-','color',Colors(1,:))
    plot([i i],[CrossDayCI(4,i) CrossDayCI(3,i)],'-','color',Colors(2,:))
end

[p,table] = anova2(AnovaData,TestTimes,'off');
plot([5.2 5.2],[min(CrossDayMean(:,end)) max(CrossDayMean(:,end))],'color',[0 0 0])
PlotPValueMarker(5.3,0.15,mean(CrossDayMean(:,end)),p(1),[0 0 0]);
text(5.3,mean(CrossDayMean(:,end))+0.5,['F(' num2str(table{2,3}) ',' num2str(table{3,3})  ')=' num2str(table{2,5})])

for iDay=1:DayNum
    plot([iDay-0.2 iDay+0.3],[Max*1.03 Max*1.03],'-k','linewidth',1)
    PlotPValueMarker(iDay,0.15,Max*1.05,CrossDayPValue(iDay),[0 0 0],0.2)
end

box off
axis([0.5 DayNum+1 floor(Min) ceil(Max)])
xlabel('Day')
ylabel('Persistence (s)')
set(gca,'xtick',1:DayNum,'xticklabel',1:DayNum,'ytick',floor(Min):ceil(Max),'fontsize',12)
title('Laser effects on the persistence of cross day TCT decoding','fontsize',10)