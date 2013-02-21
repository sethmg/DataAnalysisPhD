%% House keeping
clc
clear all
close all

%% Read the data file

[inFile,inPath] = uigetfile('/media/Test_Data/*TEMA*.txt','Please select a TEMA data file');
data = importdata([inPath,inFile],'\t');

% extract time data
timeDisp = data.data(:,1);

% extract position data
% TrackedPoint = zeros((size(data.data,2)-1)/2,size(data.data,1),2);
TrackedImpac = [data.data(~isnan(data.data(:,2)),2),data.data(~isnan(data.data(:,2)),3)];
TrackedTroch = [data.data(~isnan(data.data(:,4)),4),data.data(~isnan(data.data(:,4)),5)];

%% Filter the data
% filtering constants
samplingRateDisp = 9216;
wFreq_cutoffDisp = 500; % 3dB cutoff frequency Hz (same as the force filter)
cutOff_Normalized = wFreq_cutoffDisp/(samplingRateDisp);
[b,a] = butter(1,cutOff_Normalized);

TrackedImpacFilt = filtfilt(b,a,TrackedImpac);
TrackedTrochFilt = filtfilt(b,a,TrackedTroch);

%% Save the data
readmeDisp = sprintf('This data was filtered using a fourth order butterworth filter with a -3dB cutoff frequency of %0.0f Hz. ''Tracked*'' is the raw TEMA data, ''Tracked*Filt'' is the filtered data, order the same. Time is in ms, and positions are in m.',wFreq_cutoffDisp);
outFile = [inFile(1:end-4),'_Processed_filtfilt'];
save([inPath,outFile],'samplingRateDisp','timeDisp','TrackedImpac','TrackedImpacFilt','TrackedTroch','TrackedTrochFilt','wFreq_cutoffDisp','readmeDisp')
% figure(2)
% foamAX = axes;
% plot(foamAX,timeDisp,(TrackedFilt(1,:,1)-TrackedFilt(2,:,1)).*1000);
% grid
% title('Time vs Foam Compression','Fontname','Times','Fontsize',20);
% xlabel('Time (ms)','Fontname','Times','Fontsize',18);
% ylabel('Compression (mm)','Fontname','Times','Fontsize',18);
% ylims = ylim;
% ylim([0 ylims(2)]);
% set(foamAX,'FontName','Times','Fontsize',16);

%% Plot the data
figure(1)
dispAX = axes;
plot(dispAX,timeDisp(1:length(TrackedImpac)),TrackedImpacFilt(:,1).*1000,timeDisp(1:length(TrackedTroch)),TrackedTrochFilt(:,1).*1000,'linewidth',2);
grid
title('Time vs Displacement','Fontname','Times','Fontsize',20);
xlabel('Time (ms)','Fontname','Times','Fontsize',18);
ylabel('Displacement (mm)','Fontname','Times','Fontsize',18);
set(dispAX,'FontName','Times','Fontsize',16);


