%% Get ready for the analysis
% clean up in prep
clc
clear all
close all

% select the input files
[insFile,insPath] = uigetfile('/media/Test_Data/Ins_*.csv','Please select the Instron data file');
insFID = fopen([insPath,insFile],'r');
instron = importdata([insPath,insFile],',');
if isstruct(instron)
    instron = instron.data;
end

%% Loadcell and displacement data conditioning
% Data collection constants
dlgPrompt = {'Enther the displacement gain in mm/V:','Enter the load gain in N/V:'};
dlgTitle = 'Input the Instron gain values';
loadGain = inputdlg(dlgPrompt,dlgTitle,1,{'0.5','400'});
samplingPeriod = (instron(5,1)-instron(1,1))/5; %s
samplingRate = 1/samplingPeriod; %Hz

% filtering constants
wFreq_cutoff = 500; % 3dB cutoff frequency Hz
cutOff_Normalized = wFreq_cutoff/(samplingRate);
[b,a] = butter(2,cutOff_Normalized);
 
% filter the strain, loadcell and displacement data
instron(:,2:6) = filtfilt(b,a,instron(:,2:6));

% convert force and displacement data to N and mm
time = instron(:,1);
displacement = instron(:,5).*str2double(loadGain{1});
force = instron(:,6).*str2double(loadGain{2});
trigger = instron(:,7);

%% Droptower strain gauge data conditioning
% Calculate principal strains
eA = instron(:,2);
eB = instron(:,3);
eC = instron(:,4);
pStrain1 = (eA+eC)./2+1/2.*sqrt((eA-eC).^2+(2.*eB-eA-eC).^2);
pStrain2 = (eA+eC)./2-1/2.*sqrt((eA-eC).^2+(2.*eB-eA-eC).^2);
phi = 1/2.*atan((eA-2.*eB+eC)./(eA-eC));

%% Save the processed Data
processedDataFileName = [insFile(1:end-4),'_Processed_filtfilt'];
readme = sprintf('This data was filtered with a cutoff frequency of %0.0f Hz. The conversion from volts to N was %0.0f N/V. The conversion from volts to mm was %0.2f mm/V.',wFreq_cutoff,str2double(loadGain{2}),str2double(loadGain{1}));
save([insPath,processedDataFileName],'time','displacement','force','pStrain1','pStrain2','phi','readme','trigger');


% %% plotting
% hF1 = figure(1);
% hA1 = axes;
% plot(hA1,-instron(:,5),-instron(:,6),'linewidth',2)
% title('Force vs Displacement','FontName','Times','Fontsize',24);
% xlabel('Compressive Displacement (mm)','FontName','Times','Fontsize',20);
% ylabel('Compressive Force (N)','FontName','Times','Fontsize',20);
% xlim([0 1])
% 
% hF2 = figure(2);
% hA2 = axes;
% plot(hA2,-instron(:,6),pStrain2.*100,'linewidth',2)
% title('Minimum Principal Strain vs Force','FontName','Times','Fontsize',24);
% xlabel('Compressive Force (N)','FontName','Times','Fontsize',20);
% ylabel('Minimum Principal Strain (%)','FontName','Times','Fontsize',20);
% 
% hF3 = figure(3);
% hA3 = axes;
% plot(hA3,instron(:,1),pStrain2.*100,'linewidth',2)
% grid
% xlabel('Time (s)','fontname','times','fontsize',20)
% ylabel('Minimum Principal Strain (%)','fontname','times','fontsize',20)
% title('Time vs Minimum Principal Strain','fontname','times','fontsize',24)
% set(hA3,'fontname','times','fontsize',18)