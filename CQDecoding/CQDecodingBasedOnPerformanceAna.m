%the code was used to calculate the decoding efficiency(template matching)
%according to behavioral performance
%AllUnitsOdorSelectivityAna NDTDecoding CQDecodingOld DecodingAnaAccordingToPerformance
%CQDecodingWithDistractorAna PlotCQDecodingResults  %PlotCQTCTDecoding
addpath(genpath('/home/qcheng/personaldata/uploaddata/Decoding'))%ION computing center
% addpath(genpath('D:\CQ\Matlab codes'))
clear;clc;close all
PhaseCriterion=[60 60 70 85];%: NL [224 236 244];% 
WorkerNumber=17;

TargetBrainID='AI';%define the brain area for summary
UnitSummaryFile=dir(['*' TargetBrainID '-DPA-AllUnitsSummary*.mat']);
for iFile=[1]%go through each group of data
    Filename=UnitSummaryFile(iFile).name(1:end-4);
    disp(Filename)
    
    num_neuron_ForDecoding=110;% if IsCorrectOrErrorOrAllTrials=4, NL-430; ChR-380; NpHR-340
    num_trial_ForEachCondition=80;
    IsCorrectOrErrorOrAllTrials=3;%1 for correct trials, 2 for error trials , 3 for all trials, 4 for correct trials as template, error trials as test
    GroupNum=1;
    NullDistributionNum=17;
    num_resample_runs=3;%define the decoding times
    
    IsShffleDecoding=0;
    IsCalculateTCTDecodingResults=0;
    AddSustainedNeuronWithSigBinNum=[6]; % add selective neurons to non-selective pools with target bin number having sustained
    OnlyWithOrAddTargetSigBinNum=1; % 1 for only with target neurons with specific sig bins, 2 for add  target neurons to non-selective neurons
    % 1 second odor selectivity  during delay period, 0 for non-selective neurons
    ExcludeTransientSustainedNeu=0; % 0 for not exclude, 1 for excluding transient neurons, 2 for exclude sustained neurons,3 only with Transient neruons, 4 noly with Sustained neurons
    ExcludeNeuronWithReversedOdorSelectivity=0; %1 delay reversed selec neu; 2 sample-delay reversed selec neu; 3 both 1 and 2;4 for only with reversed neurons
    % ChR-569-31=538; NL:704-13=691; NpHR:451-5=446; %delay reversed selective neurons
    % ChR-569-42=527; NL-704-29=675; NpHR-451-19=432;$Sample-Delay reversed selective neurons
    % ChR-569-54=515; NL:704-32=672; NpHR-451-20=431;%3 for both
    
    PairOrNonPairTrials=3;%1 for pairing trials, 2 for non-pairing trials,3 for all trials
    bin_width=500;%define the bin width for each sliding window
    step_size=100;%ms
    StartTime=2;%start from 2 second after to 4s baseline(which means 4-2=2s before the sample odor)
    NotComputeLastSecondNum=6;
    CellType=1;% 1 for all neurons, 2 for pyramidal neurons, 3 for interneurons
    DecodingForSamTestDecisionTrialType=1;% Decoding for 1-sample odor,2-test odor, 3-decision(FC or CR in nonpair trials), 4-trial type(Pair-Nonpair)
    IsNormalizedData=1;
    
    GroupID='-NL';
    IsChR=regexpi(Filename,'ChR');
    if ~isempty(IsChR)
        GroupID='-ChR';
    end
    IsNpHR=regexpi(Filename,'NpHR');
    if ~isempty(IsNpHR)
        GroupID='-NpHR';
    end
    load(Filename);
    tempTotalUnitSplitData=TotalUnitSplitData;
    TimeGain=tempTotalUnitSplitData.TimeGain{1}(1);
    
    %  Cross day neuron number
    %  ChR2 group     [160 124 129 100  66],569 in total
    %no-laser group   [113 129,134,166,162],704 in total
    %   NpHR group    [110 100,101, 66, 75],451 in total
    
    %For reversed selectivity neuron number in each day
    %ChR:  Day1-169-27; Day2-132-19; Day3-125-13; Day4-5-176-23;
    %   :  31
    % NL:  Day1-113-10; Day2-129-13; Day3-134-8;  Day4-5-328-24;;
    %   :  13
    %NpHR: Day1-110-4; Day2-100-7;  Day3=101-5;  Day4-5-141-10;
    %   :  5
    %1 for equal in specific bin
    %after Bonferroni correction
    %   ChR2 group    [296 222(153 69),29,22(16 6)],569 in total
    %no-laser group   [423 228(148 80),31,22(13 9)],704 in total
    %   NpHR group    [300 124(82  42),19, 8(4 4)] ,451 in total
    %Exclude switched neuron
    %ChR:  Trans-222-186=36; Sus-51-33=18;
    %NL:   Trans-228-204=24; Sus-53-45=8;
    %NpHR: Trans-124-109=15; Sus-27-22=5;
    
    %Neuron Number limited by Error Trial number
    %       10   15    20    25     30     35     40
    %ChR    492  421   390   298    281    228    199
    %NL     585  485   436   373    325    252    198
    %NpHR   431  401   350   328    239    214    168
    %selective neuron limited by error trial number
    % >=  10   15    20   25   30   35    40
    % ChR:  236  214   199  159   152  122  107
    % NL:   221  190   162  144   122   90   77
    %NpHR:  134  118   107  101    79   75   62
    %Neuron number limited by correct trial
    %Number >= 40   45   50    55    60    65    70    75
    % ChR     273  272   232   166   146   137   114   91
    % NL:     281  281   257   200   161   137   129   96
    %NpHR:    151  136   133   88    73
    %Neuron Number limited by Error Trial number after removing
    %switched neurons
    %       10   15    20    25     30     35     40
    %ChR    446  377   350   262    245    202    177
    %NL     560  464   419   360    315    245    191
    %NpHR   413  387   337   317    229    206    161
    
    %% get the training day ID
    [MiceID,TargetTrainingDay]=GetTrainingDay(TotalUnitSplitData);
    %Filter the Training day for diffreent learning phase
    [PhasesNeuronID,LearningdPhaseDayBasedPerformance,WellTrainedPhasePerformance]=...
        FilterTrainingDayForDifferentPhases(TotalUnitSplitData,TargetTrainingDay,PhaseCriterion,100);
    PhaseCriterion=[60 60 70 85];%: NL [224 236 244];% 
    
    for iPhase=1:3%go through each phase
        LearningPhase=['Phase-' num2str(iPhase)];
        %% extract the neurons in this behavioral phase        
        tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,PhasesNeuronID{1,iPhase});        
        TimeGain=tempTotalUnitSplitData.TimeGain{1}(1);
        SPlen=min(vertcat(tempTotalUnitSplitData.ShortSPlen{:}));
        MeanTrialLength=SPlen/TimeGain;
        LaserPhase=unique(tempTotalUnitSplitData.TrialLaserDelay{1}(:,2));%2 for laser in block design
        IsLaserTrial=LaserPhase(1);
        
        if ExcludeNeuronWithReversedOdorSelectivity>0||ExcludeTransientSustainedNeu>0
            [NeuronIDWithDelayReversedOdorSelectivity,NonSelectiveNeuID,SampleDelayReversedSelectivityNeuID,DelaySigBinNum]...
                =FilterNeuronIDWithReversedOdorSelectivity(tempTotalUnitSplitData,TimeGain,OdorMN,DelayMN);
            BothSwithNeuID=union(NeuronIDWithDelayReversedOdorSelectivity,SampleDelayReversedSelectivityNeuID);
            
            if ExcludeNeuronWithReversedOdorSelectivity==1
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,NeuronIDWithDelayReversedOdorSelectivity);
                disp(['---- Excluded Neurons With reversed odor selectivity-' num2str(length(NeuronIDWithDelayReversedOdorSelectivity)) '----'])
            elseif ExcludeNeuronWithReversedOdorSelectivity==2
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,SampleDelayReversedSelectivityNeuID);
                disp(['---- Excluded Neurons With sample-delay reversed odor selectivity-' num2str(length(SampleDelayReversedSelectivityNeuID)) '----'])
            elseif ExcludeNeuronWithReversedOdorSelectivity==3
                AllReversedSelecNeuID=union(NeuronIDWithDelayReversedOdorSelectivity,SampleDelayReversedSelectivityNeuID);
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,AllReversedSelecNeuID);
                AllReversedSelectiveNeuNum=length(AllReversedSelecNeuID);
                disp(['---- Excluded delay reversed selec and sample-delay reversed selec neu-' num2str(AllReversedSelectiveNeuNum) '----'])
            elseif ExcludeNeuronWithReversedOdorSelectivity==4
                AllReversedSelecNeuID=union(NeuronIDWithDelayReversedOdorSelectivity,SampleDelayReversedSelectivityNeuID);
                tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,AllReversedSelecNeuID);
                disp(['---- Decoding only With reversed odor selectivity-' num2str(length(AllReversedSelecNeuID)) '----'])
            end
            TransientNeuID=find(DelaySigBinNum>=1&DelaySigBinNum<=4);
            TransientNeuID=setdiff(TransientNeuID,BothSwithNeuID);
            SustainedNeuID=find(DelaySigBinNum==5);
            SustainedNeuID=setdiff(SustainedNeuID,BothSwithNeuID);
            if ExcludeTransientSustainedNeu==1%exclude transient selective neurons
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,TransientNeuID);
                disp(['-----Exclude transient selective neurons-' num2str(length(TransientNeuID)) '-----'])
            elseif ExcludeTransientSustainedNeu==2%exclude sustained selective neurons
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,SustainedNeuID);
                disp(['-----Exclude sustained selective neurons-' num2str(length(SustainedNeuID)) '-----'])
            elseif ExcludeTransientSustainedNeu==3%Only with transient selective neurons
                tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,TransientNeuID);
                disp(['-----Only With transient selective neurons-' num2str(length(TransientNeuID)) '-----'])
            elseif ExcludeTransientSustainedNeu==4%Only with sustained selective neurons
                tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,SustainedNeuID);
                disp(['-----Only With SustainedNeuID selective neurons-' num2str(length(SustainedNeuID)) '-----'])
            end
        end
        %%
        if CellType>1%identify the cell type with the waveform,1 for all neurons, 2 for pyramidal neurons, 3 for interneurons
            AllWaveForm=tempTotalUnitSplitData.WaveForm;
            Threshold=350;%threshold seperate fast spiking interneuron and pyramidal neurons
            [AllPeakTroughDuration,FSIID,PCID]=IdentifyCellTypeBasedOnWaveform(AllWaveForm,Threshold);
            if CellType==2%2 for pyramidal neurons
                tempTotalUnitSplitData=FilterTotalUnitSplitData(tempTotalUnitSplitData,PCID);
            elseif CellType==3%3 for interneurons
                tempTotalUnitSplitData=FilterTotalUnitSplitData(tempTotalUnitSplitData,FSIID);
            end
        end
        %% add neurons with sustained odor selectivty to no selective neurons
        TotalSingleUnitNum=length(tempTotalUnitSplitData.AllSequentialAllSP);
        IsSustainedOdorSelectiveNeuron=zeros(TotalSingleUnitNum,5);
        TargetNeuronIDWithSpecificSigBin=[];
        if min(AddSustainedNeuronWithSigBinNum)>=0&&max(AddSustainedNeuronWithSigBinNum)<=5
            disp('-----Pre-processing the odor selectivity for each neuron -----')
            [TargetNeuronID,IsSustainedOdorSelectiveNeuron,DelaySigBinNum,TargetNeuronIDWithSpecificSigBin,NeuronNumWithDiffSig1SecondBin]...
                =ConstructNeuronIDWithSpecificSustainedNeu(tempTotalUnitSplitData,TimeGain,DelayMN,DecodingForSamTestDecisionTrialType...
                ,AddSustainedNeuronWithSigBinNum,IsLaserTrial,3,PairOrNonPairTrials);
            disp(['-----Target sig neuron number-' num2str(length(TargetNeuronIDWithSpecificSigBin)) '-----'])
            
            if OnlyWithOrAddTargetSigBinNum==1% only with neurons with specific sig bin during delay
                TargetNeuronID=TargetNeuronIDWithSpecificSigBin;
            elseif OnlyWithOrAddTargetSigBinNum==2% target sig neurons with non-selective neurons
                TargetNeuronID=TargetNeuronID;
            end
        else
            TargetNeuronID=1:TotalSingleUnitNum;
        end
        TotalSingleUnitNum=length(TargetNeuronID);
        
        disp(['---- GroupNum-' num2str(GroupNum) '-TotalNullDistributionNum-' num2str(NullDistributionNum) '----'] )        
        TitleName=ConstructDecodingTitle(TargetBrainID,DecodingForSamTestDecisionTrialType,IsLaserTrial,IsShffleDecoding...
                ,num_neuron_ForDecoding,IsNormalizedData,num_resample_runs,num_trial_ForEachCondition,num_trial_ForEachCondition,LearningPhase,0,0,GroupID...
                ,0,[],bin_width,IsCorrectOrErrorOrAllTrials,CellType,AddSustainedNeuronWithSigBinNum...
                ,ExcludeTransientSustainedNeu,ExcludeNeuronWithReversedOdorSelectivity);
        disp(TitleName)
        %% Construct the raw trial matrix
        disp(['-----Step 1 Construct raw data Total Neuron Number-' num2str(TotalSingleUnitNum) '-----'])
        TrialBinnedFR=cell(1,TotalSingleUnitNum);
        AllNeuronTrialNumber=zeros(2,TotalSingleUnitNum);
        AllNeuSampleTrialID=cell(2,TotalSingleUnitNum);
        for iNeuron = 1:TotalSingleUnitNum% go through each neuron
            tempNeuronID=TargetNeuronID(iNeuron);
            SequentialAllSP=tempTotalUnitSplitData.AllSequentialAllSP{tempNeuronID};
            TrialsJudgement=tempTotalUnitSplitData.TrialsJudgement{tempNeuronID}(1:size(SequentialAllSP,2),:);
            
            [TrialIndex1,TrialIndex2,tempTrialBinnedFR] =ConstrucSingleNeuForDecoding...
                (DecodingForSamTestDecisionTrialType,TrialsJudgement,IsCorrectOrErrorOrAllTrials...
                ,SequentialAllSP,bin_width,step_size,MeanTrialLength,1,NotComputeLastSecondNum,StartTime);
            
            TrialBinnedFR{1,iNeuron}=tempTrialBinnedFR;
            AllNeuSampleTrialID(:,iNeuron)=[{TrialIndex1};{TrialIndex2}];
            AllNeuronTrialNumber(:,iNeuron)=[length(TrialIndex1);length(TrialIndex2)];
        end
        [~,TooFewTrialNeuronIndex]=find(min(AllNeuronTrialNumber)<num_trial_ForEachCondition);
        TrialBinnedFR(:,TooFewTrialNeuronIndex)=[];
        disp(['-----Neuron Number With Enough Trial-' num2str(length(TrialBinnedFR)) '->=' num2str(num_trial_ForEachCondition) '-----'])
        %% calculate the decoding accuracy by using correct tirals
        if WorkerNumber>1
            poolobj = gcp('nocreate'); % If no pool, do not create new one.
            if isempty(poolobj)
                myCluster=parcluster('local'); myCluster.NumWorkers=WorkerNumber; parpool(myCluster,WorkerNumber)
            end
            disp('-----Step 2 Start decoding analysis-----')
            for iNullDis=1:NullDistributionNum
                f(iNullDis) = parfeval(@CrossValidationTest,1,TrialBinnedFR,AllNeuSampleTrialID,num_trial_ForEachCondition...
                    ,num_neuron_ForDecoding,IsNormalizedData,num_resample_runs,IsShffleDecoding,IsCalculateTCTDecodingResults);
            end
            for iNullDis=1:NullDistributionNum
                [~,DECODING_RESULTS] = fetchNext(f);  % Collect the results as they become available.
                save(['CQCV' TitleName '-' num2str(GroupNum) '-' num2str(iNullDis)], 'DECODING_RESULTS','-v7.3');
            end
        else
            for iNullDis=1:NullDistributionNum
                DECODING_RESULTS = CrossValidationTest(TrialBinnedFR,AllNeuSampleTrialID,num_trial_ForEachCondition...
                    ,num_neuron_ForDecoding,IsNormalizedData,num_resample_runs,IsShffleDecoding,IsCalculateTCTDecodingResults);
                save(['CQCV' TitleName '-' num2str(GroupNum) '-' num2str(iNullDis)], 'DECODING_RESULTS','-v7.3');
            end
        end
        BinNum=size(TrialBinnedFR{1},2);
        ProceedingBinNum=bin_width/step_size;
        X=-(4-StartTime):step_size/1000:(BinNum*step_size/1000-(4-StartTime))-step_size/1000;
        X=X+ProceedingBinNum*step_size/1000+step_size/1000/2;
        save(['CQCV' TitleName '-All Parameters'],'TitleName','DECODING_RESULTS','TrialBinnedFR','AllNeuSampleTrialID','AllNeuronTrialNumber'...
            ,'num_trial_ForEachCondition','TimeGain','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','num_resample_runs'...
            ,'num_trial_ForEachCondition','SPlen','bin_width','step_size','Filename','num_neuron_ForDecoding','NotComputeLastSecondNum'...
            ,'StartTime','X','AddSustainedNeuronWithSigBinNum','ExcludeNeuronWithReversedOdorSelectivity')
    end
end
disp(['---' Filename '-Computing End---'])