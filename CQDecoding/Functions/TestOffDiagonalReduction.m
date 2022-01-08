function BothSigReduction=TestOffDiagonalReduction(RealDecodingResults,TestBinID)

%Reference: Stable and dynamic coding for working memory in primate prefrontal cortex

ShuffleTimes=1000;
BinNum=length(TestBinID);
DecodingResults=RealDecodingResults(TestBinID,TestBinID);

OffDiagonalReduction=zeros(2,BinNum,BinNum);
for i=1:BinNum
    for j=1:BinNum
         OffDiagonalReduction(1,i,j)=DecodingResults(i,i)-DecodingResults(i,j); 
         OffDiagonalReduction(2,i,j)=DecodingResults(j,j)-DecodingResults(i,j);     
    end
end
%% calculate shuffled off-diagonal reduction
ShuffleedOffDiagonalReduction=zeros(2,ShuffleTimes,BinNum,BinNum);
for iShuffle=1:ShuffleTimes    
    ShuffledDecodingResults=zeros(BinNum,BinNum);      
    for i=1:BinNum%go through each train bin
        tempDecodingResults=DecodingResults(i,:);
        ID=randperm(BinNum);
        if ID(i)~=i
            ShuffledDecodingResults(i,:)=tempDecodingResults(ID);
        else
            ID=fliplr(ID);
            ShuffledDecodingResults(i,:)=tempDecodingResults(ID);
        end
    end    
    %%
    for i=1:BinNum%go through each train bin         
        for j=1:BinNum% go through each test bin
            ShuffleedOffDiagonalReduction(1,iShuffle,i,j)=ShuffledDecodingResults(i,i)-ShuffledDecodingResults(i,j);
            ShuffleedOffDiagonalReduction(2,iShuffle,i,j)=ShuffledDecodingResults(j,j)-ShuffledDecodingResults(i,j);
        end
    end
end
%% perform pemutation test
IsSigReduction=zeros(2,BinNum,BinNum);
for i=1:2
    tempOffDiagonalReduction=OffDiagonalReduction(i,:,:);
    tempOffDiagonalReduction=reshape(tempOffDiagonalReduction,BinNum,BinNum);
    tempShuffleedOffDiagonalReduction=ShuffleedOffDiagonalReduction(i,:,:,:);
    tempShuffleedOffDiagonalReduction=reshape(tempShuffleedOffDiagonalReduction,ShuffleTimes,BinNum,BinNum);
    
    The_95Percentile=prctile(tempShuffleedOffDiagonalReduction,95,1);
    The_95Percentile=reshape(The_95Percentile,BinNum,BinNum);
    
    for j=1:BinNum%go through each train bin
        IsSigReduction(i,j,tempOffDiagonalReduction(j,:)>The_95Percentile(j,:))=1;
    end
end
%% Define the sig. reduction time point (t(i,i)>t(i,j)&&t(j,j)>t(i,j))
BothSigReduction=IsSigReduction(1,:,:).*IsSigReduction(2,:,:);
BothSigReduction=reshape(BothSigReduction,BinNum,BinNum);
%%
% figure
% imagesc(X(TestBinID),X(TestBinID),DecodingResults*100,[35 85]);%[45 85]
% hold on
% contour(X(TestBinID),X(TestBinID),BothSigReduction,[1 1],'-','color',[0 0 0],'linewidth',2)
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