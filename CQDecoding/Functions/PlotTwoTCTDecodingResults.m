function PlotTwoTCTDecodingResults(TotalDecodingResults,X,significant_event_times,ColorBarRange,Legends)

figure('position',[150 250 1200,600])
for i=1:size(TotalDecodingResults,2)
    subplot(1,2,i);%[left bottom width height]
    
    imagesc(X,X,TotalDecodingResults{1,i}*100,ColorBarRange);
    hold on
    AllIsSignificantMatrix=zeros(size(TotalDecodingResults{1,1}));
    %     StartBin=(4-StartTime-1)*10+1;
    StartBin=find(X>=-0.5,1);
    EndBin=length(find(X<=7));
    PlotSigBinRange=StartBin:EndBin;
    AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)=AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)...
        +TotalDecodingResults{3,i}(PlotSigBinRange,PlotSigBinRange);
    if max(max(AllIsSignificantMatrix))>0
        contour(X,X,AllIsSignificantMatrix,[1 1],'-w','linewidth',1)
    end
    for iEvent = 1:length(significant_event_times)
        %         line([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'), 'color', [0 0 0])
        %         line(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)], 'color', [0 0 0])
        plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
        plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
    end
    axis xy
    colorbar('ytick',[30 40 50 60 70 80],'yticklabel',[30 40 50 60 70 80])
    set(gca,'xtick',[0 2 4 6], 'XTickLabel', [0 2 4 6],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6]);%add by CQ
    axis([-0.5 7.2 -0.5 7.2])
    title(Legends{i},'fontsize',12)
end
