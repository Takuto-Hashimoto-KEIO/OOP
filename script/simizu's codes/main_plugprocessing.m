clear
close all
add_basic_path
addpath(genpath("../src/"));

cfg.device="plug";
cfg.datapath="/Volumes/NAS32/pj_corticomuscular_coherence/241019_shimizu/EEG/shimizu_rest_openeyes.csv";
cfg.coi=1;
cfg.rjct_ch=[];
% 
% preprocessor=PlugPreprocessor;
% preprocessor=preprocessor.preprocessing(cfg);
% data=preprocessor.data;

data_eeg=EEGProcessor;
data_eeg=data_eeg.processing(cfg);
ref_win=1:50;
data_eeg=data_eeg.calc_ersp(ref_win);

%% test
% isequal(data.eeg.epoched.filterd.C3,squeeze(data_eeg.frqfiled(:,1,:)))
% isequal(data.eeg.epoched.filterd.C3CzRef,squeeze(data_eeg.spafiled(:,1,:)))

% PSD
figure;
power=squeeze(mean(data_eeg.power(:,:,1,:),4));
rest_power=mean(power(1:50,:),1);
plot(rest_power);
hold on
task_power=mean(power(60:141,:),1);
plot(task_power);

% TF
% ersp_c3=squeeze(median(data_eeg.ersp(:,:,1,:),4));
% TFDrawer.draw(ersp_c3,11);
% 
% psd_COI = data.eeg.epoched.filterd.spctl.C3CzRef.indiv(2:end,:,:);
% ersp_calculator=ERSPcalculator(psd_COI);
% ersp_calculator=ersp_calculator.calc_ersp();
% TFDrawer.draw(permute(ersp_calculator.ersp,[2,1]),11);
