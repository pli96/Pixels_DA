function CompareThePersistenceOfTwoTCTDecoding(OptoGroupSigBinDuration,NLSignificantBinDuration,TestPeriod,Legends,DayID)

[p1,~] = signrank(OptoGroupSigBinDuration,NLSignificantBinDuration);
figure('position',[350 250 800 500])
subplot('position',[0.08 0.1 0.68 0.8])

plot(NLSignificantBinDuration,OptoGroupSigBinDuration,'.','color',[0 0 0])
% scatter(NLSignificantBinDuration,OptoGroupSigBinDuration,[],[0 0 0],'Marker','.','markerfacecolor',[0 0 0])
hold on
plot([0 TestPeriod(2)],[0 TestPeriod(2)],'--k')
text(0.2,TestPeriod(2)-0.2,['p=' num2str(p1)])
text(0.2,TestPeriod(2)-0.5,['n=' num2str(length(OptoGroupSigBinDuration))])
axis([0 TestPeriod(2) 0 TestPeriod(2)])
xlabel(['Persistence (s)-' Legends{2}])
ylabel(['Persistence (s)-' Legends{1}])
title(['The duration of TCT decoding-' Legends{1} '-' Legends{2} DayID])
%%
subplot('position',[0.83 0.1 0.1 0.8])
hArray =bar([mean(OptoGroupSigBinDuration) mean(NLSignificantBinDuration)]);
set(hArray(1),'facecolor',[0 0 0],'EdgeColor',[0 0 0]);
hold on
for i=1:length(OptoGroupSigBinDuration)
    plot(1:2,[OptoGroupSigBinDuration(i) NLSignificantBinDuration(i)],'-k','Marker','o','markersize',2,'linewidth',0.5)    
end
Max=max([max(NLSignificantBinDuration) max(OptoGroupSigBinDuration)]);
plot([1 2],[1 1 ]*Max*1.02,'-k')
text(0.5,Max*1.04,['p=' num2str(p1)])

ylabel(['Persistence (s)-' Legends{1}])
set(gca,'xtick',[1 2],'xticklabel',[{Legends{1}(1:end-6)} {Legends{2}(1:end-6)}])
axis([0.3 2.7 0 max([max(OptoGroupSigBinDuration) max(NLSignificantBinDuration)])*1.2])


% SecondColors=[[0 0 1];[0 0 0];[0.2 0.2 0.2];[0.4 0.4 0.4];[0.6 0.6 0.6];[0.8 0.8 0.8];[1 0 1]];%
% SecondLegends=[{'Sample'};{'Delay1'};{'Delay2'};{'Delay3'};{'Delay4'};{'Delay5'};{'Test'}];% 
% BlockNum=ceil(length(OptoGroupSigBinDuration)/10);
%     for j=1:BlockNum
% %         scatter(NLSignificantBinDuration((j-1)*10+1:j*10),OptoGroupSigBinDuration((j-1)*10+1:j*10),[],SecondColors(j,:),'Marker','.','markerfacecolor',SecondColors(j,:))
%         scatter(NLSignificantBinDuration((j-1)*10+1:j*10),OptoGroupSigBinDuration((j-1)*10+1:j*10),[],[0 0 0],'Marker','.','markerfacecolor',[0 0 0])
%     end