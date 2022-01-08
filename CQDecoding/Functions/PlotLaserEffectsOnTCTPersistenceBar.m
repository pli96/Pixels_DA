function PlotLaserEffectsOnTCTPersistenceBar(CrossDayPersistence,Legends)

Max=max(max(CrossDayPersistence));
Min=min(min(CrossDayPersistence));

DisCI1=prctile(CrossDayPersistence(1,:),[97.5 2.5]);
DisCI2=prctile(CrossDayPersistence(2,:),[97.5 2.5]);

MeanOptoGroup=mean(CrossDayPersistence(1,:));
MeanControlGroup=mean(CrossDayPersistence(2,:));
if MeanOptoGroup>MeanControlGroup
    OverlapDataNum=length(find(CrossDayPersistence(2,:)>min(CrossDayPersistence(1,:))));
    p=(OverlapDataNum+1)/(length(CrossDayPersistence(1,:))+1);%
else
    OverlapDataNum=length(find(CrossDayPersistence(1,:)>min(CrossDayPersistence(2,:))));
    p=(OverlapDataNum+1)/(length(CrossDayPersistence(2,:))+1);%
end

figure
Mean=mean(CrossDayPersistence,2);
bar(1:2,Mean,'k')
hold on
plot([1 1],[DisCI1(2) DisCI1(1)])
plot([2 2],[DisCI2(2) DisCI2(1)])

plot([1 2],[Max Max],'color',[0 0 0])
PlotPValueMarker(1.2,0.05,ceil(Max)*0.9,p,[0 0 0]);

box off
axis([0.5 2.5 floor(Min) ceil(Max)])
ylabel('Difference of Sig. decoding duration after distractor (s)')
set(gca,'xtick',1:2,'xticklabel',Legends,'ytick',floor(Min):ceil(Max),'fontsize',12)
title('Laser effects on the persistence of cross day TCT decoding','fontsize',10)