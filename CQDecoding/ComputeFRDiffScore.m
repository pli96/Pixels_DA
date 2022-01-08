function ShuffledZStatistics = ComputeFRDiffScore(Sam1DelayTrialFR,Sam2DelayTrialFR,DelayBinNum)

Sam1DiffScore=zeros(size(Sam1DelayTrialFR,1),DelayBinNum,DelayBinNum);
for i=1:size(Sam1DelayTrialFR,1)%go through each trial
    ShuffledBinID=randperm(DelayBinNum);
    tempTrialBinnedFR=Sam1DelayTrialFR(i,ShuffledBinID);
    for iBin=1:DelayBinNum
        Sam1DiffScore(i,iBin,:)=tempTrialBinnedFR-tempTrialBinnedFR(iBin);
    end
end

Sam2DiffScore=zeros(size(Sam2DelayTrialFR,1),DelayBinNum,DelayBinNum);
for i=1:size(Sam2DelayTrialFR,1)%go through each trial
    ShuffledBinID=randperm(DelayBinNum);
    tempTrialBinnedFR=Sam2DelayTrialFR(i,ShuffledBinID);
    for iBin=1:DelayBinNum
        Sam2DiffScore(i,iBin,:)=tempTrialBinnedFR-tempTrialBinnedFR(iBin);
    end
end
%% compute the shuffled Z-score
ShuffledZStatistics=zeros(DelayBinNum,DelayBinNum);
for i=1:DelayBinNum
    for j=1:DelayBinNum
        if j~=i
            [~,~,stats] =ranksum(Sam1DiffScore(:,i,j),Sam2DiffScore(:,i,j),'method','approximate');
            if isfield(stats,'zval') && ~isnan(stats.zval)
                ShuffledZStatistics(i,j)=stats.zval;
            else
                ShuffledZStatistics(i,j)=0;
            end
        end
    end
end
