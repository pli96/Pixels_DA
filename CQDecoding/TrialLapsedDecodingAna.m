%the code was used to calculate the trial-lapsed decoding efficiency(template matching)
% Question 1: how to balance the trials (unequal trial number in different phases) used to calculate the decoding power
% Solution: only use unit with at least 15 hit trials and 10 correct rejection trials
SlidingWindowTrialNum=20;%calculate the odor selectivity in every 20 trials
StepSize=4;%
TimeGain=10;
ConstructRawData=1;

DecodingContent=2;%1 for sample odor, 2 for test odor, 3 for results

DecodingTimes=20;%define the decoding times
TestingTimes=SlidingWindowTrialNum/2;

CurrentPath=pwd;
AllPath=genpath(CurrentPath);
SplitPath=strsplit(AllPath,';');
SubPath=SplitPath';
SubPath=SubPath(1:end-1);
%%
for iPath=1:size(SubPath,1)%go through each training phase
    Path=SubPath{iPath,1};
    %change the directory
    cd(Path);
    disp('---Current directory---')
    disp(Path)
    UnitSummaryFile=dir('*DPA-AllUnitsSummary.mat*');
    Temp=strsplit(Path,'\');
    LearningPhase=Temp{1,end};
    %%
    if size(UnitSummaryFile,1)~=0
        load(UnitSummaryFile.name);
        SPlen=TotalUnitSplitData.ShortSPlen{end};
        %%
        if ConstructRawData==1
            CrossNeuronTrialNum=cellfun(@size,TotalUnitSplitData.AllSequentialAllSP,'uniformOutput',0);
            CrossNeuronTrialNum=vertcat(CrossNeuronTrialNum{:});
            MinCrossNeuronTrialNum=min(CrossNeuronTrialNum(:,2));
            StepNum=floor((MinCrossNeuronTrialNum-SlidingWindowTrialNum)/StepSize+1);
            TotalSingleUnitNum=length(TotalUnitSplitData.AllSequentialAllSP);
            %%
            TrialLapsedDecodingAccuracy=zeros(StepNum,SPlen-1);
            ShuffleTrialLapsedDecodingAccuracy=zeros(StepNum,SPlen-1);
            TrialLapsedPerformance=zeros(TotalSingleUnitNum,StepNum);
            LaserTrialRatio=zeros(StepNum,1);
            for step=1:StepNum%go through each step
                iTrialIndex=(step-1)*StepSize+1:(step-1)*StepSize+SlidingWindowTrialNum;
                disp('---step number/Total StepNum---')
                disp([step StepNum])
                
                %Construct the raw trial matrix
                Rule1FR=cell(1,TotalSingleUnitNum);
                Rule2FR=cell(1,TotalSingleUnitNum);
                ShuffleRule1FR=cell(1,TotalSingleUnitNum);
                ShuffleRule2FR=cell(1,TotalSingleUnitNum);
                for iNeuron=1:TotalSingleUnitNum% go through each neuron
                    AllSequentialAllSP=TotalUnitSplitData.AllSequentialAllSP{iNeuron}(:,iTrialIndex);
                    TrialLaserDelay=TotalUnitSplitData.TrialLaserDelay{iNeuron}(iTrialIndex,:);
                    TrialsJudgement=TotalUnitSplitData.TrialsJudgement{iNeuron}(iTrialIndex,:);
                    iPerformance=length(find(TrialsJudgement(:,end-1)==1|TrialsJudgement(:,end-1)==4))/SlidingWindowTrialNum;
                    TrialLapsedPerformance(iNeuron,step)=iPerformance;
                    LaserTrialRatio(step)=length(find(TrialLaserDelay(:,2)==1))/SlidingWindowTrialNum;
                    %%
                    %get the target trial index according to the identity of the first odorant
                    if DecodingContent==1%for sample odor
                        TrialIndex1=find(TrialsJudgement(:,2)==1);%%OdorA
                        TrialIndex2=find(TrialsJudgement(:,2)==2);%%OdorB
                    elseif DecodingContent==2%for test odor
                        TrialIndex1=find(TrialsJudgement(:,3)==1);%OdorA C
                        TrialIndex2=find(TrialsJudgement(:,3)==2);%OdorA D
                    elseif DecodingContent==3%trial results
                        TrialIndex1=find(TrialsJudgement(:,2)==1&TrialsJudgement(:,4)==3);%OdorA FC 
                        TrialIndex2=find(TrialsJudgement(:,2)==1&TrialsJudgement(:,4)==4);%OdorA CR 
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%
                    %Select the target trials from each unit
                    TempA=GetDecodingTrials(AllSequentialAllSP,TrialIndex1,SPlen);
                    TempB=GetDecodingTrials(AllSequentialAllSP,TrialIndex2,SPlen);
                    Rule1FR{1,iNeuron}=TempA;
                    Rule2FR{1,iNeuron}=TempB;
                    %%
                    %shuffle the data
                    TrialIndex=[TrialIndex1;TrialIndex2];
                    temp=randperm(length(TrialIndex));
                    ShuffleSample1=temp(1:round(length(temp)/2));
                    ShuffleSample2=temp(round(length(temp)/2)+1:length(temp));
                    ShuffleRule1FR{1,iNeuron}=GetDecodingTrials(AllSequentialAllSP,TrialIndex(ShuffleSample1),SPlen);
                    ShuffleRule2FR{1,iNeuron}=GetDecodingTrials(AllSequentialAllSP,TrialIndex(ShuffleSample2),SPlen);
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%
                EmptyInd=cellfun(@isempty,Rule2FR);Rule2FR(EmptyInd)=[];Rule1FR(EmptyInd)=[];
                ShuffleRule1FR(:,EmptyInd)=[];ShuffleRule2FR(:,EmptyInd)=[];
                %calculate the decoding accuracy by using correct tirals(hit and correct rejection within steady state)
                CrossNeuronTrialNum=cellfun(@size,Rule1FR,'uniformOutput',0);
                CrossNeuronTrialNum=vertcat(CrossNeuronTrialNum{:});
                CrossNeuronTrialNum1=cellfun(@size,Rule2FR,'uniformOutput',0);
                CrossNeuronTrialNum1=vertcat(CrossNeuronTrialNum1{:});
                MinCrossNeuronTrialNum=min([CrossNeuronTrialNum(:,1);CrossNeuronTrialNum1(:,1)]);
                AllScore=zeros(DecodingTimes,SPlen-1);
                for iDecoding=1:DecodingTimes
                    [Score]=CalculateTrialLapsedDecodingPower(Rule1FR,Rule2FR,TestingTimes,SPlen,MinCrossNeuronTrialNum);
                    AllScore(iDecoding,:)=mean(Score);
                end
                CorrectTrialAllScore=AllScore;
                AveragedCorrectTrialAllScore=smooth(mean(CorrectTrialAllScore))';
                %%
                %Average each shuffle event of correct tirals
                CrossNeuronTrialNum=cellfun(@size,ShuffleRule1FR,'uniformOutput',0);
                CrossNeuronTrialNum=vertcat(CrossNeuronTrialNum{:});
                CrossNeuronTrialNum1=cellfun(@size,ShuffleRule2FR,'uniformOutput',0);
                CrossNeuronTrialNum1=vertcat(CrossNeuronTrialNum1{:});
                MinCrossNeuronTrialNum=min([CrossNeuronTrialNum(:,1);CrossNeuronTrialNum1(:,1)]);
                AllShuffleScore=zeros(DecodingTimes,SPlen-1);
                for iDecoding=1:DecodingTimes
                    [ShuffleScore]=CalculateTrialLapsedDecodingPower(ShuffleRule1FR,ShuffleRule2FR,TestingTimes,SPlen,MinCrossNeuronTrialNum);
                    AllShuffleScore(iDecoding,:)=mean(ShuffleScore);
                end
                CorrectTrialAllScoreShuffle=AllShuffleScore;
                AveragedCorrectTrialAllScoreShuffle=smooth(mean(CorrectTrialAllScoreShuffle))';
                %%
                TrialLapsedDecodingAccuracy(step,:)=AveragedCorrectTrialAllScore;
                ShuffleTrialLapsedDecodingAccuracy(step,:)=AveragedCorrectTrialAllScoreShuffle;
            end
        end
        TrialLapsedDecodingFile=dir('*Trial lapsed decoding*.mat');
        if size(TrialLapsedDecodingFile,1)>0||ConstructRawData==1
            if size(TrialLapsedDecodingFile,1)>0
                load(TrialLapsedDecodingFile.name)
            end
            figure
            %real data
            subplot('position',[0.15,0.57,0.6,0.36])%[left bottom width height]
            imagesc(-4:0.1:(size(TrialLapsedDecodingAccuracy,2)/TimeGain-4)-0.1,1:StepNum,TrialLapsedDecodingAccuracy,[0.45 0.85]);
            YTicklabel=SetTick(0,StepNum);
            XTick=SetTick(-4,size(TrialLapsedDecodingAccuracy,2)/TimeGain-4);
            XTickLebel=cell(1,length(XTick));
            set(gca,'xtick',XTick,'xticklabel',XTickLebel,'ytick',YTicklabel,'yticklabel',YTicklabel)
            hold on
            ylabel('Trial lapsed index')
            if DecodingContent==1
                title(['Sample odor decoding accuracy-' LearningPhase])
            elseif DecodingContent==2
                title(['Test odor decoding accuracy-' LearningPhase])
            end
            plot([0 0],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            plot([OdorMN OdorMN],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            plot([OdorMN+DelayMN OdorMN+DelayMN],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            plot([2*OdorMN+DelayMN 2*OdorMN+DelayMN],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            plot([2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            plot([2*OdorMN+DelayMN+ResponseMN+WaterMN 2*OdorMN+DelayMN+ResponseMN+WaterMN],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            %%
            %performance
            subplot('position',[0.8,0.57,0.1,0.36])
            MeanTrialLapsedPerformance=mean(TrialLapsedPerformance);
            plot(MeanTrialLapsedPerformance,StepNum:-1:1,'k','linewidth',2)
            axis([min(MeanTrialLapsedPerformance)*0.9 max(MeanTrialLapsedPerformance)*1.05  1 StepNum+1])
            YTicklabel=SetTick(0,StepNum);
            xlabel('Perf.')
            if mean(LaserTrialRatio)==0
                set(gca,'ytick',YTicklabel,'yticklabel',flip(YTicklabel))
            else
                NoLabel=cell(1,length(YTicklabel));
                set(gca,'ytick',YTicklabel,'yticklabel',NoLabel)
                subplot('position',[0.77,0.57,0.01,0.36])                 
                imagesc(LaserTrialRatio)
                Xtick=0.5;
                YTicklabel1=cell(1,length(YTicklabel));
                set(gca,'xtick',Xtick,'xticklabel',{''},'ytick',YTicklabel,'yticklabel',YTicklabel1)
            end
            %%
            %Shuffle data
            subplot('position',[0.15,0.1,0.72,0.36])%[left bottom width height]
            imagesc(-4:0.1:(size(ShuffleTrialLapsedDecodingAccuracy,2)/TimeGain-4)-0.1,1:StepNum,ShuffleTrialLapsedDecodingAccuracy,[0.45 0.85]);
            hold on
            plot([0 0],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            plot([OdorMN OdorMN],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            plot([OdorMN+DelayMN OdorMN+DelayMN],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            plot([2*OdorMN+DelayMN 2*OdorMN+DelayMN],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            plot([2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            plot([2*OdorMN+DelayMN+ResponseMN+WaterMN 2*OdorMN+DelayMN+ResponseMN+WaterMN],[1 TotalSingleUnitNum],'--k','linewidth',1.5)
            ylabel('Trial lapsed index')
            title('Shuffle data')
            xlabel('Time from sample onset')
            h=colorbar;
            ylabel(h,'Decoding accuracy','fontsize',10)
            if DecodingContent==1
                Title=['Trial lapsed decoding for Sample Odor-' LearningPhase];
            elseif DecodingContent==2
                Title=['Trial lapsed decoding for Test Odor-' LearningPhase];
            elseif DecodingContent==3
                Title=['Trial lapsed decoding for Results-' LearningPhase];
            end
            saveas(gcf,[Title '-' num2str(DecodingTimes) '-' num2str(TestingTimes) '-' LearningPhase],'fig')%
            saveas(gcf,[Title '-' num2str(DecodingTimes) '-' num2str(TestingTimes) '-' LearningPhase],'png')%
            close all
        end
        save(Title,'TrialLapsedPerformance','TrialLapsedDecodingAccuracy','ShuffleTrialLapsedDecodingAccuracy','LearningPhase','StepNum','TimeGain'...
            ,'DecodingTimes','TestingTimes','LaserTrialRatio','OdorMN','DelayMN','ResponseMN','WaterMN','TotalSingleUnitNum','DecodingContent')
    end
end