function PlotCurveWithArea(DecodingAccuracy,ShuffleDecodingAccuracy,bin_width,step_size,OdorMN,DelayMN,ResponseMN,WaterMN,ITIMN...
    ,num_neuron_ForDecoding,TitleName,AveraPer,Legend)

figure('color',[1 1 1])
AddLegend(Legend,[[0 0 1];[0 0 0]],'northeast');
hold on

ProceedingBinNum=bin_width/step_size;
X=-4+step_size/1000:step_size/1000:(size(DecodingAccuracy,2)*step_size/1000-4);
X=X+ProceedingBinNum*step_size/1000;
[Y1Min,Y1Max]=PlotMeanSEM(DecodingAccuracy,X,[[0.4 0.4 1];[0 0 1]]);

plot([-3 2*OdorMN+DelayMN+ResponseMN+WaterMN+ITIMN-0.5],[0.5 0.5],'k','linewidth',2)
[Y2Min,Y2Max]=PlotMeanSEM(ShuffleDecodingAccuracy,X,[[0.4 0.4 0.4];[0 0 0]]);
YMax=max([max(Y1Max) max(Y2Max)]);% max(y5) max(y7)
YMin=min([Y1Min min(Y2Min)]);% max(y6) max(y8)
EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,YMax,YMin);
%% do rank sumation test
for iBin=1:size(DecodingAccuracy,2)%go through each bin
    p2=length(find(ShuffleDecodingAccuracy(:,iBin)>mean(DecodingAccuracy(:,iBin))))/size(ShuffleDecodingAccuracy,1);%permutation test
    p3=length(find(ShuffleDecodingAccuracy(:,iBin)<mean(DecodingAccuracy(:,iBin))))/size(ShuffleDecodingAccuracy,1);%permutation test
    p1=min([p2 p3]);
    if p1<0.005
        %plot(iBin/TimeGain-4-0.1,0.99,'b.','markersize',15)
        plot(iBin*step_size/1000-4+step_size/1000,min([0.3 min(YMin)]),'b.','markersize',15)
    end
end
plot([-3 2*OdorMN+DelayMN+ResponseMN+WaterMN+ITIMN],[0.5 0.5],'-k','linewidth',2)
text(2*OdorMN+DelayMN+ResponseMN+WaterMN+1,YMax*0.95,['UnitNum=' num2str(num_neuron_ForDecoding)],'fontsize',14)
text(2*OdorMN+DelayMN+ResponseMN+WaterMN+1,YMax*0.9,'p<0.005','fontsize',14)
if AveraPer~=0
    text(2*OdorMN+DelayMN+ResponseMN+WaterMN+1,YMax*0.85,['Avera.Per.=' num2str(AveraPer)],'fontsize',14)%
end
set(gca,'fontsize',12)
xlabel('Time from sample onset(s)','fontsize',14)
ylabel('Decoding Accuracy','fontsize',14)
set(gca,'fontsize',14,'TickDir','out')
axis([-4 2*OdorMN+DelayMN+ResponseMN+WaterMN+ITIMN-0.5 min([0.3 min(YMin)*0.9]) min([YMax*1.1 1])])
box off
title(TitleName,'fontsize',14)