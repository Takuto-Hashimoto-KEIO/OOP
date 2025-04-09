% clear
% close all
addpath(genpath("../src"));
add_basic_path;

datapath="/Volumes/NAS32/pj_corticomuscular_coherence/241019_shimizu/EMG/shimizu_s1_block3.csv";
% datapath="/Users/shimizukensuke/Documents/plug-sonification-analysis-devel-iwama_dev/data/EEG_EMG_sub3/EMG/Analysis/3_s2_pre_exercise.csv";
data_emg=EMGProcessor;
data_emg=data_emg.processing(datapath);

% PSD
figure;
power=data_emg.power;
psd=permute(power,[2,1,3,4]);
psd=reshape(psd,size(psd,1),[]);
plotMat(psd);
percentile=prctile(psd(4:end,:),[25,75]);
psd_max=max(percentile,[],"all");
psd_min=min(percentile,[],"all");
ylim([psd_min,psd_max]);
hold off

