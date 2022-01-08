%the code was used to calculate the decoding efficiency(template matching)
TargetDayID=[{[1,2]};{3};{[4,5]}];%define the group days used to perform decoding analysis
All_num_neuron_ForDecoding=[130 90 110];

PlotFigure=1;
PlotMouseBasedPerformance=0;

TargetBrainID='AI';%define the brain area for summary
ConstructRawData=1;
%%
DecodingForSamTestDecisionTrialType=1;% Decoding for 1-sample odor,2-test odor, 3-decision(FC or CR in nonpair trials), 4-trial type(Pair-Nonpair)

num_resample_runs=20;%define the decoding times
num_cv_splits=10;%affect the decoding variations, not the absolute the decoding accuracy
num_trial_ForEachCondition=40;

bin_width=150;%ms
step_size=50;%ms
%%
UnitSummaryFile=dir(['*' TargetBrainID '-DPA-AllUnitsSummary*.mat']);
if size(UnitSummaryFile,1)~=0
    load(UnitSummaryFile.name);
    TimeGain=TotalUnitSplitData.TimeGain{1}(1);
    if ConstructRawData==1
        %%
        %get the Mice ID and training day ID
        [MiceID,TargetTrainingDay]=GetTrainingDay(TotalUnitSplitData);
        %get the performance and neuron ID for each training day
        DayBasedPerformanceNeuron=DayBasedPerAndNeuronInfo(TotalUnitSplitData,TargetTrainingDay);
        %get all the neuron index in the traget training day
        [NeuronIndexInEachTrainingDay,MiceBasedPerformance]=GetNeuronIndexInEachTrainingDay(DayBasedPerformanceNeuron,MiceID);
        %%
        %Plot cross day performance for each mouse
        if PlotMouseBasedPerformance==1
            for iMouse=1:size(MiceBasedPerformance,1)
                PlotCrossDayPerForDayBasedDecoding(MiceBasedPerformance(iMouse,:))
                saveas(gcf,[ 'CrossDayPer-' MiceBasedPerformance{iMouse,1}],'fig')
                saveas(gcf,[ 'CrossDayPer-' MiceBasedPerformance{iMouse,1}],'png')
                close all
            end
        end
        %plot cross day performance of all Mice
        PlotPhasePerformance(NeuronIndexInEachTrainingDay,1)
        saveas(gcf,'Cross day performance.fig')
        saveas(gcf,'Cross day performance.png')
        close all
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%
        for iTargetDay=1:length(TargetDayID)%go through each target day group
            DayID=ConstructDayID(TargetDayID{iTargetDay});
            %plot average performance in target days
            TargetPhasePerformance=NeuronIndexInEachTrainingDay(4,TargetDayID{iTargetDay});
            TargetPhasePerformance=vertcat(TargetPhasePerformance{:});
            PlotTargetPhasePerformanceForDecoding(TargetPhasePerformance,DayID)
            saveas(gcf,[DayID '-Performance'],'fig')
            saveas(gcf,[DayID '-Performance'],'png')
            close all
            %extract the neurons in the target training day
            num_neuron_ForDecoding=All_num_neuron_ForDecoding(iTargetDay);
            TargetNeuronID=NeuronIndexInEachTrainingDay(1,TargetDayID{iTargetDay});
            tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,vertcat(TargetNeuronID{:}));
            %%
            SPlen=min(vertcat(tempTotalUnitSplitData.ShortSPlen{:}));
            MeanTrialLength=SPlen/TimeGain;
            Bin_Num=length(0:step_size:MeanTrialLength*1000-bin_width);
            TotalSingleUnitNum=length(tempTotalUnitSplitData.AllSequentialAllSP);
            TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{1};            
            LaserPhase=unique(TrialLaserDelay(:,2));%2 for laser in block design
            IsLaserGroup=max(LaserPhase);%0 no laser condition, 1 for laser condition
            %%
            for IsLaserTrial=1:length(LaserPhase)%go through laser or no laser trial
                %Construct the raw trial matrix
                TitleName=ConstructDecodingTitle(TargetBrainID,DecodingForSamTestDecisionTrialType,IsLaserTrial...
                    ,0,num_resample_runs,num_cv_splits,num_trial_ForEachCondition,[],0,0,IsLaserGroup,0,DayID);
                Rule1FR=cell(1,TotalSingleUnitNum);
                Rule2FR=cell(1,TotalSingleUnitNum);
                ShuffleRule1FR=cell(1,TotalSingleUnitNum);
                ShuffleRule2FR=cell(1,TotalSingleUnitNum);
                AllNeuronTrialNumber=zeros(2,TotalSingleUnitNum);
                for iNeuron=1:size(tempTotalUnitSplitData.AllSequentialAllSP,1)% go through each neuron
                    SequentialAllSP=tempTotalUnitSplitData.AllSequentialAllSP{iNeuron};
                    TrialsJudgement=tempTotalUnitSplitData.TrialsJudgement{iNeuron}(1:size(SequentialAllSP,2),:);
                    TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{iNeuron}(1:size(SequentialAllSP,2),:);
                    %%
                    %get the target trial index according to the identity of the first odorant
                    [TrialIndex1,TrialIndex2,TrialType]= GetTrialIndexForDecoding(DecodingForSamTestDecisionTrialType,TrialsJudgement); 
                    AllNeuronTrialNumber(1,iNeuron)=length(TrialIndex1);
                    AllNeuronTrialNumber(2,iNeuron)=length(TrialIndex2);
                    %%
                    %Select the target trials from each neuron
                    Rule1FR{1,iNeuron}=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex1,bin_width,step_size,MeanTrialLength);
                    Rule2FR{1,iNeuron}=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex2,bin_width,step_size,MeanTrialLength);
                    %%
                    %shuffle the data
                    TrialIndex=[TrialIndex1;TrialIndex2];
                    temp=randperm(length(TrialIndex));
                    ShuffleSample1=temp(1:round(length(temp)/2));
                    ShuffleSample2=temp(round(length(temp)/2)+1:length(temp));
                    ShuffleRule1FR{1,iNeuron}=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex(ShuffleSample1),bin_width,step_size,MeanTrialLength);
                    ShuffleRule2FR{1,iNeuron}=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex(ShuffleSample2),bin_width,step_size,MeanTrialLength);
                end
                %%
                %exclud the neurons with two few trials
                [~,TwoFewTrialNeuronIndex]=find(min(AllNeuronTrialNumber)<num_trial_ForEachCondition);
                %AllNeuronTrialNumber(:,TwoFewTrialNeuronIndex)=[];
                Rule1FR(:,TwoFewTrialNeuronIndex)=[];
                Rule2FR(:,TwoFewTrialNeuronIndex)=[];
                ShuffleRule1FR(:,TwoFewTrialNeuronIndex)=[];
                ShuffleRule2FR(:,TwoFewTrialNeuronIndex)=[];
                %%
                %calculate the decoding accuracy by using correct tirals
                DecodingAccuracy=zeros(num_resample_runs,Bin_Num);
                ShuffleDecodingAccuracy=zeros(num_resample_runs,Bin_Num);
                RandomlyNeuronID=randperm(length(Rule1FR));
                for iResample=1:num_resample_runs%go through each resample run
                    if length(Rule1FR)>num_neuron_ForDecoding
                        temp=randperm(length(Rule1FR));
                        TargetNeuronID=temp(1:num_neuron_ForDecoding);%randomly pick up the specified neuron number
                    else
                        num_neuron_ForDecoding=length(Rule1FR);
                        TargetNeuronID=1:length(Rule1FR);
                    end
                    [CV_results]=CrossValidationTest(Rule1FR(TargetNeuronID),Rule2FR(TargetNeuronID),num_cv_splits,Bin_Num,num_trial_ForEachCondition,0);
                    DecodingAccuracy(iResample,:)=mean(CV_results);
                    [ShuffleCV_results]=CrossValidationTest(ShuffleRule1FR(TargetNeuronID),ShuffleRule2FR(TargetNeuronID),num_cv_splits,Bin_Num,num_trial_ForEachCondition,0);
                    ShuffleDecodingAccuracy(iResample,:)=mean(ShuffleCV_results);
                end
                %%
                if PlotFigure==1
                    MeanTargetPhasePer=NeuronIndexInEachTrainingDay(2,TargetDayID{iTargetDay});
                    MeanTargetPhasePer=mean(vertcat(MeanTargetPhasePer{:}));
                    PlotCurveWithArea(DecodingAccuracy,ShuffleDecodingAccuracy,step_size,OdorMN,DelayMN,ResponseMN,WaterMN,ITIMN...
                        ,TargetNeuronID,TitleName,MeanTargetPhasePer)
                    saveas(gcf,['Decoding-' TitleName '-' num2str(TotalSingleUnitNum-1)],'fig')%
                    saveas(gcf,['Decoding-' TitleName '-' num2str(TotalSingleUnitNum-1)],'png')%
                    close all
                end
                if ConstructRawData==1
                    save(['Decoding-' TitleName '-' num2str(TotalSingleUnitNum-1)],'DecodingAccuracy','ShuffleDecodingAccuracy'...
                        ,'Rule1FR','Rule2FR','AllNeuronTrialNumber','num_trial_ForEachCondition','TimeGain','OdorMN','DelayMN','ResponseMN'...
                        ,'WaterMN','ITIMN','num_resample_runs','num_cv_splits','num_trial_ForEachCondition','bin_width','step_size'...
                        ,'NeuronIndexInEachTrainingDay','MiceBasedPerformance','TargetNeuronID','TargetPhasePerformance','UnitSummaryFile')
                end
            end
        end
    end
end