function [ZStatistics,ShuffledZStatistics,IsTransientDelayFR1,P,IsSignificant1,IsSignificantLess1]=TestSecondSelectivityChange(Samp1TrialsFR...
    ,Samp2TrialsFR,WorkerNum,temp_X,OdorMN,DelayMN,ResponseMN,WaterMN,UnitID,PlotDiffFRZStatisticsTCT,ShuffleTimes,Permuted_BinID,DelayBinID)

if length(Permuted_BinID)==DelayMN    
    PostFix='Permu Delay';
elseif length(Permuted_BinID)==DelayMN+1
    PostFix='Permu Delay-Sample';
else
    PostFix='Permu WholeTrial';
end 
Samp1TrialsFR = Samp1TrialsFR(:,Permuted_BinID); 
Samp2TrialsFR = Samp2TrialsFR(:,Permuted_BinID); 
%% construct difference score matrix for each trial
% Stable and dynamic coding for working memory in primate prefrontal cortex,
% Eelke Spaak,Kei Watanabe,Shintaro Funahashi,and Mark G. Stokes
% construct the FR difference score matrix for each trial and each bin during delay period: nTrialNum X DelayBinNum X DelayBinNum
BinNum=size(Samp1TrialsFR,2); 
Sam1DiffScore=zeros(size(Samp1TrialsFR,1),BinNum,BinNum);
for i=1:size(Samp1TrialsFR,1)%go through each trial
    tempTrialBinnedFR=Samp1TrialsFR(i,:);
    for iBin=1:BinNum
        Sam1DiffScore(i,iBin,:)=tempTrialBinnedFR-tempTrialBinnedFR(iBin);
    end
end
Sam2DiffScore=zeros(size(Samp2TrialsFR,1),BinNum,BinNum);
for i=1:size(Samp2TrialsFR,1)%go through each trial
    tempTrialBinnedFR=Samp2TrialsFR(i,:);
    for iBin=1:BinNum
        Sam2DiffScore(i,iBin,:)=tempTrialBinnedFR-tempTrialBinnedFR(iBin);
    end
end
%% construct the Z-stastics (based on ranksum test) for each nTimeBins X nTimeBins matrix
ZStatistics=zeros(BinNum,BinNum);
for i=1:BinNum
    for j=1:BinNum
        if j~=i
            [~,~,stats] =ranksum(Sam1DiffScore(:,i,j),Sam2DiffScore(:,i,j));
            ZStatistics(i,j)=stats.zval;
        end
    end
end
%% construct the shuffled difference score and Z-statistics by permuting the time labels for ShuffleTimes times
if WorkerNum>1
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        myCluster=parcluster('local'); myCluster.NumWorkers=WorkerNum; parpool(myCluster,WorkerNum)
    end
    ShuffledZStatistics=zeros(ShuffleTimes,BinNum,BinNum);
    for iShuffleTimes=1:ShuffleTimes
        f(iShuffleTimes) = parfeval(@ComputeFRDiffScore,1,Samp1TrialsFR,Samp2TrialsFR,BinNum);
    end
    for iShuffleTimes=1:ShuffleTimes
        [~,tempShuffledZStatistics] = fetchNext(f);  % Collect the results as they become available.
        ShuffledZStatistics(iShuffleTimes,:,:)= tempShuffledZStatistics;
    end
else
    ShuffledZStatistics=zeros(ShuffleTimes,BinNum,BinNum);
    for iShuffleTimes=1:ShuffleTimes
        tempShuffledZStatistics=ComputeFRDiffScore(Samp1TrialsFR,Samp2TrialsFR,BinNum);
        ShuffledZStatistics(iShuffleTimes,:,:)= tempShuffledZStatistics;
    end
end
%% perform cluster-based permutation test
% [~,IsSignificant,~,~,~,~,~,IsSignificantLess,~]=TCTClusterBasedPermutationTest(ZStatistics,ShuffledZStatistics,BinNum,ShuffleTimes,2); 
% DelayIsSignificant=IsSignificant(Permuted_BinID,Permuted_BinID); 
% DelayIsSignificantLess=IsSignificantLess(Permuted_BinID,Permuted_BinID); 
% if sum(sum(DelayIsSignificant+DelayIsSignificantLess))>0
%     IsTransientDelayFR=1;
% else
%     IsTransientDelayFR=0;
% end

DelayBinIndex=find(Permuted_BinID>=min(DelayBinID)&Permuted_BinID<=max(DelayBinID));
%% perform permutation test
[IsSignificant1,IsSignificantLess1,P]=PermutationTest(ZStatistics,ShuffledZStatistics,1); 
DelayIsSignificant=IsSignificant1(DelayBinIndex,DelayBinIndex); 
DelayIsSignificantLess=IsSignificantLess1(DelayBinIndex,DelayBinIndex); 
if sum(sum(DelayIsSignificant+DelayIsSignificantLess))-sum(diag(DelayIsSignificant))-sum(diag(DelayIsSignificantLess))>0
    IsTransientDelayFR1=1; 
else 
    IsTransientDelayFR1=0; 
end  
DelayPValue=P(DelayBinIndex,DelayBinIndex);
%% plot the Z-score of Delay Firing Rate difference
Max=ceil(max(max(ZStatistics)));
Min=floor(min(min(ZStatistics)));
if PlotDiffFRZStatisticsTCT==1
    figure('visible','off')
    imagesc(temp_X(Permuted_BinID),temp_X(Permuted_BinID),ZStatistics,[Min Max]);%[45 85]
    hold on
    contour(temp_X(Permuted_BinID),temp_X(Permuted_BinID),IsSignificant1,[1 1],'-','color',[1 1 1],'linewidth',2)
    contour(temp_X(Permuted_BinID),temp_X(Permuted_BinID),IsSignificantLess1,[1 1],'-','color',[0 0 0],'linewidth',2)
    
    for i=1:size(DelayPValue,1) 
        for j=1:size(DelayPValue,2) 
            if i~=j 
                if ZStatistics(i,j)>0&&ZStatistics(i,j)<Max/2||(ZStatistics(i,j)<0&&ZStatistics(i,j)>Min/2)
                    Color=[0 0 0];
                else
                    Color=[1 1 1];
                end 
              text(temp_X(Permuted_BinID(DelayBinIndex(i)))-0.4,j+0.5,num2str(DelayPValue(i,j)),'fontsize',8,'color',Color)  
            end 
        end 
    end 
%     contour(temp_X,temp_X,IsSignificant1,[1 1],'-','color',[1 0 1],'linewidth',2)
%     contour(temp_X,temp_X,IsSignificantLess1,[1 1],'-','color',[0 1 0],'linewidth',2)
%     contour(temp_X(Permuted_BinID),temp_X(Permuted_BinID),DelayIsSignificant,[1 1],'-','color',[1 1 1],'linewidth',2)
%     contour(temp_X(Permuted_BinID),temp_X(Permuted_BinID),DelayIsSignificantLess,[1 1],'-','color',[0 0 0],'linewidth',2)
    significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
    for iEvent = 1:length(significant_event_times)
        plot([significant_event_times(iEvent), significant_event_times(iEvent)], [-0.5 DelayMN+OdorMN*2],'--k','linewidth',1)
        plot([-0.5 DelayMN+OdorMN*2], [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
    end
    colorbar('ytick',Min:2:Max,'yticklabel',Min:2:Max)
    set(gca,'xtick',[0 2 4 6 8 10 12], 'XTickLabel', [0 2 4 6 8 10 12],'ytick',[0 2 4 6 8 10 12], 'yTickLabel', [0 2 4 6 8 10 12],'TickLength',[0.025, 0.025],'linewidth',1);%add by CQ
%     axis([-0.5 DelayMN+OdorMN*2+0.5 -0.5 DelayMN+OdorMN*2+0.5])
    axis([-1 DelayMN+OdorMN*2+1.5 -1 DelayMN+OdorMN*2+1.5])
    xlabel('Test time (s)','fontsize',12)
    ylabel('Reference time (s)','fontsize',12)
    axis xy
    title([{UnitID '-Delay Diff FR Z-Score'} {PostFix}])   
    saveas(gcf,[UnitID '-Delay Diff FR Z-Score-' PostFix],'fig')
    saveas(gcf,[UnitID '-Delay Diff FR Z-Score-' PostFix],'png')
    close all
end