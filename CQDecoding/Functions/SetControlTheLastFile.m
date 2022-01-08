function [NewDecodingResults,Markers,Colors,AreaColors]=SetControlTheLastFile(DecodingResultsFiles,MarkerID)

DecodingResultsFiles=struct2cell(DecodingResultsFiles);
DecodingResultsFiles=DecodingResultsFiles(1,:)';
NLID=cellfun(@(x,y) regexpi(x,y),DecodingResultsFiles,repmat({'NL'},size(DecodingResultsFiles)),'uniformoutput',0);
NLFileID=~cellfun(@isempty,NLID);
OptoFileID=cellfun(@isempty,NLID);
NewDecodingResults=[DecodingResultsFiles(OptoFileID);DecodingResultsFiles(NLFileID)];

GroupMarkerID=cellfun(@(x,y) regexpi(x,y),NewDecodingResults,repmat({MarkerID},size(NewDecodingResults)),'uniformoutput',0);
% Markers=cellfun(@(x,y) x(y+7:end-19),NewDecodingResults,GroupMarkerID,'uniformoutput',0);
Markers=cellfun(@(x,y) x(y+5:end-4),NewDecodingResults,GroupMarkerID,'uniformoutput',0);

if ~isempty(regexpi(NewDecodingResults{1},'ChR'))
    Colors=[[19 130 197]/255;[0 0 0]];%Activation v.s. control
    AreaColors=[[113 180 220];[128 128 128]]/255;
else
    Colors=[[19 156 78]/255;[0 0 0]];
    AreaColors=[[113 196 149];[128 128 128]]/255;
end
