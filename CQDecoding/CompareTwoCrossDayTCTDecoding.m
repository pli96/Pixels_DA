%this code was used to compare the cross-day TCT persistence
clear;clc;close all; 
%CompareTwoCrossDayDecoding PlotCQTCTDecoding
LaserEffectsFiles=dir('*Laser effects on TCT decoding*.mat'); 
DecodingTimesToCompare=50;

if ~isempty(regexpi(LaserEffectsFiles(1).name,'ChR')) 
    Legends=[{'ChR2'};{'NoLaser'}]; 
    FaceColors=[[0.6 0.6 1];[0.4 0.4 0.4]]; 
    Colors=[[0 0 1];[0 0 0]]; 
else
    Legends=[{'NpHR'};{'NoLaser'}]; 
    FaceColors=[[0.4 1 0.4];[0.4 0.4 0.4]]; 
    Colors=[[0 0.5 0];[0 0 0]];
end
TargetDayID=[{[1]};{[2]};{[3]};{[4]};{[5]}];%;{3};{[4]};{[5]};{[6]};{[7]}define the group days used to perform decoding analysis
XLabel=[{'Day1'};{'Day2'};{'Day3'};{'Day4'};{'Day5'}]; 
load(LaserEffectsFiles(1).name,'AllNLSignificantBinDuration','LaserDelayTCTDecoding')
TestTimes=size(AllNLSignificantBinDuration,1);
DecodingTimes=length(LaserDelayTCTDecoding);
%% group cross day results
CrossDayPersistence=zeros(2,size(LaserEffectsFiles,1),TestTimes);
CrossDayDelayDecodingAccuracy=zeros(2,size(LaserEffectsFiles,1),DecodingTimes);
for iDay=1:size(LaserEffectsFiles,1)%go each day
    load(LaserEffectsFiles(iDay).name)
    
    CrossDayPersistence(1,iDay,:)=mean(AllOptoGroupSigBinDuration,2);
    CrossDayPersistence(2,iDay,:)=mean(AllNLSignificantBinDuration,2);
    CrossDayDelayDecodingAccuracy(1,iDay,:)=LaserDelayTCTDecoding;   
    CrossDayDelayDecodingAccuracy(2,iDay,:)=NLDelayTCTDecoding; 
end
%% plot laser effects on the persistence of cross-day TCT decoding 
PlotLaserEffectsOnTCTPersistence(CrossDayPersistence,Colors)
saveas(gcf,['Laser effects on the persistence of TCT decoding-' Legends{1} '-' Legends{2} '-TestTime-' num2str(TestTimes)],'fig')%  
saveas(gcf,['Laser effects on the persistence of TCT decoding-' Legends{1} '-' Legends{2} '-TestTime-' num2str(TestTimes)],'png')%  
close all
%% Plot laser effects on delay decoding accuracy of TCT decoding results
CrossDayDelayDecodingAccuracy=CrossDayDelayDecodingAccuracy*100;
PlotLaserEffectsOnTCTDelayDecodingResults(CrossDayDelayDecodingAccuracy,DecodingTimesToCompare,Colors)
saveas(gcf,['Laser effects on the Delay TCT decoding results-' Legends{1} '-' Legends{2} '-DecodingTimes-' num2str(DecodingTimesToCompare)],'fig')%  
saveas(gcf,['Laser effects on the Delay TCT decoding results-' Legends{1} '-' Legends{2} '-DecodingTimes-' num2str(DecodingTimesToCompare)],'png')%  
close all