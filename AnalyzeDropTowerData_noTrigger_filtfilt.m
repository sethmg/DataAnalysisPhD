%% Get ready for the analysis
% clean up in prep
clc
clear all
close all

% select the input files
[dtFile,dtPath] = uigetfile('/media/BigToaster/Seth Project Data/12-018 Testing!/DT_*.csv','Please select the drop tower data file');
dtFID = fopen([dtPath,dtFile],'r');
droptower = importdata([dtPath,dtFile],',');
if isstruct(droptower)
    droptower = droptower.data;
end

%% Droptower loadcell data conditioning
% The 6 axis loadcell data is column delimited in Fx,Fy,Fz,Mx,My,Mz
% data collection constants
excitation = 12; %V
samplingRate = 20000; %Hz
samplingPeriod = 1/samplingRate; %s
time = 0:samplingPeriod:(length(droptower)-1)*samplingPeriod; % 1 to 100 ms
% filtering constants
wFreq_cutoff = 500; % 3dB cutoff frequency Hz
cutOff_Normalized = wFreq_cutoff/(samplingRate);
[b,a] = butter(2,cutOff_Normalized);

% find the droptower trigger signal
indexes = 1:length(droptower);

% droptower six axis loadcell
% sixAxisDC = mean(droptower(:,5:10)); % calculate the DC offset
sixAxis = droptower(indexes,5:10); % isolate the data for trigger to trigger + 100ms 
for i = 1:6 % remove the DC offset and filter the data
%     sixAxis(:,i) = sixAxis(:,i)-sixAxisDC(i);
    sixAxisFiltered(:,i) = filtfilt(b,a,sixAxis(:,i));
end
sixAxisCalibration = [13344.7/-.0023141 13344.7/.0023088 13344.7/-.0009144 451.9/-.0018758 451.9/.0019116 226/.0015509].*(1/excitation); % calibration vector
for i = 1:length(indexes) % mV to N, applied element by element
    sixAxis(i,:) = [sixAxisFiltered(i,1)*sixAxisCalibration(1) sixAxisFiltered(i,2)*sixAxisCalibration(2) sixAxisFiltered(i,3)*sixAxisCalibration(3)...
       sixAxisFiltered(i,4)*sixAxisCalibration(4) sixAxisFiltered(i,5)*sixAxisCalibration(5) sixAxisFiltered(i,6)*sixAxisCalibration(6)];
end

% droptower single axis loadcell
% oneAxisDC = mean(droptower(1:indexes(1),11)); % calculate the DC offset
oneAxis = droptower(indexes,11);%-oneAxisDC; % remove DC offset
oneAxisFiltered = filtfilt(b,a,oneAxis); % filter
oneAxisCalibration = 22241.1/(.00300293*excitation); % calibration value
oneAxis = oneAxisFiltered*oneAxisCalibration; % mV to N

%% Droptower strain gauge data conditioning
% Gauges A, B and C are defined as defined in: Budynas, Richard. 1999. 
% Advanced strength and applied stress analysis. 2nd ed. 
% Boston: WCB/McGraw-Hill. Appendix G
gAr = droptower(indexes,2);
gBr = droptower(indexes,3);
gCr = droptower(indexes,4);
% Filter the data using the same filter as for the loadcell
gA = filtfilt(b,a,gAr);
gB = filtfilt(b,a,gBr);
gC = filtfilt(b,a,gCr);
% Calculate principal strains
pStrain1 = ( (gA+gC)./2 + 1/2.*sqrt( (gA-gC).^2 + (2.*gB-gA-gC).^2 ) );
pStrain2 = ( (gA+gC)./2 - 1/2.*sqrt( (gA-gC).^2 + (2.*gB-gA-gC).^2 ) );
phi = 0.5.*atan( (2.*gB-gA-gC) ./ (gA-gC) );


%% Write the analyzed data file
processedDataFileName = [dtFile(1:end-4),'_Processed_filtfilt'];
readme = sprintf('This data was filtered with a cutoff frequency of %0.0f Hz. The excitation voltage for the loadcells was %0.0f V.  The calibration vectors are give in {FullScale}/{mV}.',wFreq_cutoff,excitation);
save([dtPath,processedDataFileName],'time','sixAxis','oneAxis','pStrain1','pStrain2','phi','sixAxisCalibration','oneAxisCalibration','readme');


