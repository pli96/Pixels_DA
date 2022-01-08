function PlotDiffTCT(MinusControlTCT,X,significant_event_times,Marker,DayID)

% MaxMinDIff=zeros(4,length(PlotIndex));
figure
imagesc(X,X,MinusControlTCT*100,[-20 20]);
set(gca,'xticklabel',[])
hold on
% MaxMinDIff(1:2,:)=[max(MinusControlTCT(PlotIndex,PlotIndex));min(MinusControlTCT(PlotIndex,PlotIndex))]*100;
for iEvent = 1:length(significant_event_times)
    plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
    plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
end
axis xy
axis([-0.5 7.2 -0.5 7.2])
set(gca,'xtick',[0 2 4 6], 'XTickLabel', [],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6]);
title([Marker DayID],'fontsize',14)
