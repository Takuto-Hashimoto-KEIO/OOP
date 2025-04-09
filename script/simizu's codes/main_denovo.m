clear
close all
add_basic_path
addpath(genpath("../src/"));

cfg.device="egi";
cfg.datapath="/Volumes/NAS32/pj_deNovoBCI/expData/240430_otuka_NS02/h02_cal02_20041130_012642.mat";
cfg.coi=36;

data_eeg=EEGProcessor;
data_eeg=data_eeg.processing(cfg);
ref_win=15:50;
data_eeg=data_eeg.calc_ersp(ref_win);

%% visualize for quality check
% signal
frqfiled=squeeze(data_eeg.frqfiled(:,36,:));
figure
hold on
for i_trl=1:size(frqfiled,2)
    tmp=frqfiled(:,i_trl);
    plot(tmp)
end
hold off

% PSD
figure;
power=permute(squeeze(data_eeg.power(:,:,cfg.coi,:)),[2,1,3]);
rest_power=reshape(power(:,1:50,:),size(power,1),[]);
plotMat(rest_power);
hold on
task_power=reshape(power(:,60:101,:),size(power,1),[]);
col_obj=ThesisColors;
plotMat(task_power,col_obj.col(:,2));

% TF
ersp_c3=squeeze(median(data_eeg.ersp(:,:,cfg.coi,:),4));
TFDrawer.draw(ersp_c3,11);

% Topo
TopoDrawer.draw(data_eeg.ersp);
