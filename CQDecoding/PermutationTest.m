function [IsSignificant,IsSigLessThanChance,P]=PermutationTest(ZStatistics,ShuffledZStatistics,IsSingleOrTwoSidesTest)

ShuffleTimes=size(ShuffledZStatistics,1);
TrainBinNum=size(ZStatistics,1);
TestBinNum=1;%size(ZStatistics,2)-1;
IsSignificant=zeros(TrainBinNum,TrainBinNum);
IsSigLessThanChance=zeros(TrainBinNum,TrainBinNum);
P=zeros(TrainBinNum,TrainBinNum);
for iTrainBin=1:TrainBinNum
    for iTestBin = 1:TrainBinNum
        %% permutation test
        if IsSingleOrTwoSidesTest==1%single side test
%             temp95Percentile= prctile(ShuffledZStatistics(:,iTrainBin,iTestBin),95);
%             temp5Percentile = prctile(ShuffledZStatistics(:,iTrainBin,iTestBin),5);
%             if ZStatistics(iTrainBin,iTestBin)>temp95Percentile||ZStatistics(iTrainBin,iTestBin)<temp5Percentile
%                 IsSignificant(iTrainBin,iTestBin)=1;
%             end
            if ZStatistics(iTrainBin,iTestBin)>=mean(ShuffledZStatistics(:,iTrainBin,iTestBin))
                P(iTrainBin,iTestBin)=sum(ShuffledZStatistics(:,iTrainBin,iTestBin)>ZStatistics(iTrainBin,iTestBin))/ShuffleTimes;
                if TestBinNum*P(iTrainBin,iTestBin)<0.05%Boferroni correction
                    IsSignificant(iTrainBin,iTestBin)=1;
                end
            else
                P(iTrainBin,iTestBin)=sum(ShuffledZStatistics(:,iTrainBin,iTestBin)<ZStatistics(iTrainBin,iTestBin))/ShuffleTimes;
                if TestBinNum*P(iTrainBin,iTestBin)<0.05%Boferroni correction
                    IsSigLessThanChance(iTrainBin,iTestBin)=1;
                end
            end
        else%two sides test
            temp95Percentile= prctile(ShuffledZStatistics(:,iTrainBin,iTestBin),[97.5 2.5]);           
            if ZStatistics(iTrainBin,iTestBin)>temp95Percentile(1)
                IsSignificant(iTrainBin,iTestBin)=1;
            elseif ZStatistics(iTrainBin,iTestBin)<temp95Percentile(2)
                IsSigLessThanChance(iTrainBin,iTestBin)=1;
            end
        end
        %temp=find(ShuffledZStatistics(:,iTrainBin,iTestBin)>temp95Percentile);
    end
end
