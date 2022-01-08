function DECODING_RESULTS=CQCrossValidationTest(TrialBinnedFR,AllNeuSampleTrialID,num_trial_ForEachCondition,num_neuron_ForDecoding...
    ,IsNormalizedData,num_resample_runs,IsShffleDecoding,IsCalculateTCTDecodingResults)
%%
BinNum=size(TrialBinnedFR{1},2);
if IsCalculateTCTDecodingResults~=1
    DECODING_RESULTS=zeros(num_resample_runs,BinNum);
else
    DECODING_RESULTS=zeros(num_resample_runs,BinNum,BinNum);
end
for i=1:num_resample_runs
    
    [~,RAMMem]=memory;
    MemAvailable=RAMMem.PhysicalMemory.Available/1024/1024/1024;
    if MemAvailable<10
        error('Out of memory')        
    end    
    
    if length(TrialBinnedFR)>num_neuron_ForDecoding
        temp=randperm(length(TrialBinnedFR));
        TargetNeuronID=temp(1:num_neuron_ForDecoding);%randomly pick up the specified neuron number
    else
        num_neuron_ForDecoding=length(TrialBinnedFR);
        TargetNeuronID=1:length(TrialBinnedFR);        
    end
    tempTrialBinnedFR=TrialBinnedFR(TargetNeuronID);
    tempAllNeuSampleTrialID=AllNeuSampleTrialID(:,TargetNeuronID);
    %% Extract specified trial number for each neuron
    [tempRule1FR,tempRule2FR]=ExtractSpecifiedTrialNumForEachNeuron(tempTrialBinnedFR,tempAllNeuSampleTrialID,num_trial_ForEachCondition,IsShffleDecoding);
    %%
    RandomlyPickedTestTrial=randperm(num_trial_ForEachCondition);
    if IsCalculateTCTDecodingResults~=1
        CV_results=zeros(num_trial_ForEachCondition,BinNum);
    else
        CV_results=zeros(num_trial_ForEachCondition,BinNum,BinNum);
    end
    for iCV=1:num_trial_ForEachCondition % go through cross-validation test
        
        TestTrialID=RandomlyPickedTestTrial(iCV);
        TemplateTrialID=setdiff(RandomlyPickedTestTrial,TestTrialID);
        %construct test trial
        TestTrialID=repmat({TestTrialID},size(tempRule1FR));
        TestTrial1=cellfun(@(x,y) x(y,:),tempRule1FR,TestTrialID,'uniformoutput',0);
        TestTrial1=vertcat(TestTrial1{:});
        TestTrial2=cellfun(@(x,y) x(y,:),tempRule2FR,TestTrialID,'uniformoutput',0);
        TestTrial2=vertcat(TestTrial2{:});
        %construct template trial
        TemplateTrialID=repmat({TemplateTrialID},size(tempRule1FR));
        Template1=cellfun(@(x,y) x(y,:),tempRule1FR,TemplateTrialID,'uniformoutput',0);
        Template2=cellfun(@(x,y) x(y,:),tempRule2FR,TemplateTrialID,'uniformoutput',0);
        
        if IsNormalizedData==1%normalize the cross trial data for each bin for both training and test trials
            CombinedTemplate=cellfun(@(x,y) [x;y],Template1,Template2,'uniformoutput',false);
            Mean=cellfun(@mean,CombinedTemplate,'uniformoutput',0);
            Std=cellfun(@std,CombinedTemplate,'uniformoutput',0);
            Std=cellfun(@(x) x+~x,Std,'uniformoutput',0);
            %Max=cellfun(@max,Std1,'uniformoutput',0);
            for iNeuron=1:length(Template1)%go through each neuron
                Template1{iNeuron}=(Template1{iNeuron}-repmat(Mean{iNeuron},size(Template1{1},1),1))./repmat(Std{iNeuron},size(Template1{1},1),1);
                Template2{iNeuron}=(Template2{iNeuron}-repmat(Mean{iNeuron},size(Template1{2},1),1))./repmat(Std{iNeuron},size(Template1{2},1),1);
                TestTrial1(iNeuron,:)=(TestTrial1(iNeuron,:)-Mean{iNeuron})./Std{iNeuron};
                TestTrial2(iNeuron,:)=(TestTrial2(iNeuron,:)-Mean{iNeuron})./Std{iNeuron};
            end
        end
        Template1=cellfun(@mean,Template1,'uniformoutput',0);
        Template2=cellfun(@mean,Template2,'uniformoutput',0);
        Template1=vertcat(Template1{:});
        Template2=vertcat(Template2{:});
        %% Calculate the correlation coefficient between test trial and template.
        if IsCalculateTCTDecodingResults~=1
            Test1Template1Corr=zeros(1,BinNum);Test1Template2Corr=zeros(1,BinNum);
            Test2Template1Corr=zeros(1,BinNum);Test2Template2Corr=zeros(1,BinNum);
            for iBin=1:BinNum%go through each time bin
                %% max_correlation_coefficient_CL
                Test1Template1Corr(iBin)=min(min(corrcoef(TestTrial1(:,iBin),Template1(:,iBin))));
                Test1Template2Corr(iBin)=min(min(corrcoef(TestTrial1(:,iBin),Template2(:,iBin))));
                Test2Template1Corr(iBin)=min(min(corrcoef(TestTrial2(:,iBin),Template1(:,iBin))));
                Test2Template2Corr(iBin)=min(min(corrcoef(TestTrial2(:,iBin),Template2(:,iBin))));
            end
            temp=Test1Template1Corr-Test1Template2Corr;
            temp(temp>0)=1;temp(temp<0)=0;
            temp1=Test2Template2Corr-Test2Template1Corr;
            temp1(temp1>0)=1;temp1(temp1<0)=0;
            CV_results((iCV-1)*2+1:iCV*2,:)=[temp;temp1];  
            %CV_results((iCV-1)*2+1:iCV*2,:)=[ceil(Test1Template1Corr-Test1Template2Corr);ceil(Test2Template2Corr-Test2Template1Corr)];            
        else
            Test1Template1Corr=zeros(BinNum,BinNum);Test1Template2Corr=zeros(BinNum,BinNum);
            Test2Template1Corr=zeros(BinNum,BinNum);Test2Template2Corr=zeros(BinNum,BinNum);
            for iTrainBin=1:BinNum%go through each time bin
                for iTestBin=1:BinNum
                    Test1Template1Corr(iTrainBin,iTestBin)=min(min(corrcoef(Template1(:,iTrainBin),TestTrial1(:,iTestBin))));
                    Test1Template2Corr(iTrainBin,iTestBin)=min(min(corrcoef(Template2(:,iTrainBin),TestTrial1(:,iTestBin))));
                    Test2Template1Corr(iTrainBin,iTestBin)=min(min(corrcoef(Template1(:,iTrainBin),TestTrial2(:,iTestBin))));
                    Test2Template2Corr(iTrainBin,iTestBin)=min(min(corrcoef(Template2(:,iTrainBin),TestTrial2(:,iTestBin))));
                end
            end
            % Cross-validation results
            temp=Test1Template1Corr-Test1Template2Corr;
            temp(temp>0)=1;temp(temp<0)=0;
            CV_results((iCV-1)*2+1,:,:)=temp;
            temp1=Test2Template2Corr-Test2Template1Corr;
            temp1(temp1>0)=1;temp1(temp1<0)=0;
            CV_results(iCV*2,:,:)=temp1;
        end
    end    
    MeanCV_results=mean(CV_results);
    if IsCalculateTCTDecodingResults==1
        MeanCV_results=reshape(MeanCV_results,size(MeanCV_results,2),size(MeanCV_results,3));
    end
    if IsCalculateTCTDecodingResults~=1
        DECODING_RESULTS(i,:)=MeanCV_results;
    else
        DECODING_RESULTS(i,:,:)=MeanCV_results;
    end
end