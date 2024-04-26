function [vars, Graph, EEG]= PlotSpectrogram(EEG,vars,Graph)
%plots a spectrogram every 10 minutes while LLAMAS is running
if ~isfield(vars, 'LastPlotSpec') 
    vars.LastPlotSpec = 0;
    vars.SpecPeriod = 10*60*EEG.fs; %update every 10 minutes
    addpath(genpath('/home/lewislab/Downloads/chronux_2_12.v03'));
end


if (vars.currentPosition - vars.LastPlotSpec) > vars.SpecPeriod
    
params=struct;
TK = 5;
K = 2*TK-1;
params.tapers=[TK K]; % [TW K] TK= time-bandwidth = sampling frequency*spectral width, K = 2*TW - 1

params.Fs=200;
clc
movingwin=[5 .1]; % [windowlength windowslide] 
params.fpass=[0 20]; % frequency range 
    
data = EEG.Recording';     
[s,t,f]=mtspecgramc(data(9,:),movingwin,params); %occipital channel
power=log10(s)';
figure()
imagesc(t,f,power);
axis xy
xlabel('Time(s)')
ylabel('Frequency(Hz)')
colormap('jet')
colorbar
vars.LastPlotSpec = vars.currentPosition;

end


