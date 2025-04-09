clear
addpath('C:\Users\takut\OneDrive - keio.jp\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc\all_level_src\add_basic_path\');
savepath % パスを保存する
addpath("C:\Users\takut\OneDrive - keio.jp\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20240111 codes with Class\Tapping_Analysis\Tapping Analysis with Class");
add_basic_path
addpath(genpath("../src/"));
% addpath(genpath("C:\Users\takut\OneDrive - keio.jp\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc"));
cfg.device = "egi";

% 打鍵解析結果のファイルパスを指定(例 ~/Sorted_all_trials_Result_Y413.mat)
keystroke_data_file_path = "C:\Users\takut\OneDrive - keio.jp\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Results\20250114~ 予備実験4\20250130_Y408\tapping_data\Keystroke_Block_Summary\Sorted_all_trials_Result_Y408.mat"; % 打鍵解析結果のファイルパスを指定
folderPath = "C:\Users\takut\OneDrive - keio.jp\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Results\20250114~ 予備実験4\20250130_Y408\EEGdata\mat\Main"; % 脳波データのフォルダパスを指定

%% 打鍵解析結果の取得
keystroke_data = load_data(keystroke_data_file_path);

%% 脳波解析
fileList = dir(fullfile(folderPath, '*.mat')); % フォルダ内の.matファイルを取得

cfg.coi=36;
cfg.coi2=104;
cfg.hpfrq = 14; % 岩間先生の指示で実装（20250212）
cfg.lpfrq = 30;
ersp_all = [];
frqfiled_all = [];

% 各ファイルを読み込み、必要なデータを被験者ごとにtrial方向に連結（）
for fileIdx = 1:length(fileList)
    close all
    cfg.datapath = fullfile(folderPath, fileList(fileIdx).name); % 各.matファイルのパスを指定
    fprintf('Processing file: %s\n', cfg.datapath); % 処理中のファイル名を表示

    % 解析処理
    data_eeg = EEGProcessor;
    data_eeg.epocher = Rest2TaskEpocher; %???
    data_eeg = data_eeg.processing(cfg);
    ersp = data_eeg.ersp; % 時間(100ms)×周波数(1~40Hz)×チャンネル数(129)×trial数の配列
    frqfiled = data_eeg.frqfiled; % 時間(1ms)×チャンネル数(129)×trial数の配列
    spafiled = data_eeg.spafiled;

    fprintf("ersp size: %s\n", mat2str(size(ersp))); % サイズ確認 [検証用]

    if fileIdx == 1
        % 初回はそのまま設定
        ersp_all = ersp;
        frqfiled_all = frqfiled;
        spafiled_all = spafiled;
    else
        % 1次元目（最初の次元）のサイズを調整し、サイズを統一（大きい方に合わせる）
        max_dim1 = max(size(ersp_all, 1), size(ersp, 1));

        % NaN埋めのためのパディング
        if size(ersp_all, 1) < max_dim1
            pad_size = max_dim1 - size(ersp_all, 1);
            ersp_all = padarray(ersp_all, [pad_size, 0, 0, 0], NaN, 'post');
        end
        if size(ersp, 1) < max_dim1
            pad_size = max_dim1 - size(ersp, 1);
            ersp = padarray(ersp, [pad_size, 0, 0, 0], NaN, 'post');
        end

        max_dim1 = max(size(frqfiled_all, 1), size(frqfiled, 1));
        if size(frqfiled_all, 1) < max_dim1
            pad_size = max_dim1 - size(frqfiled_all, 1);
            frqfiled_all = padarray(frqfiled_all, [pad_size, 0, 0, 0], NaN, 'post');
        end
        if size(frqfiled, 1) < max_dim1
            pad_size = max_dim1 - size(frqfiled, 1);
            frqfiled = padarray(frqfiled, [pad_size, 0, 0, 0], NaN, 'post');
        end

        max_dim1 = max(size(spafiled_all, 1), size(spafiled, 1));
        if size(spafiled_all, 1) < max_dim1
            pad_size = max_dim1 - size(spafiled_all, 1);
            spafiled_all = padarray(spafiled_all, [pad_size, 0, 0, 0], NaN, 'post');
        end
        if size(spafiled, 1) < max_dim1
            pad_size = max_dim1 - size(spafiled, 1);
            spafiled= padarray(spafiled, [pad_size, 0, 0, 0], NaN, 'post');
        end

        % trialの次元で全block(100trial)を結合
        ersp_all = cat(4, ersp_all, ersp);
        frqfiled_all = cat(3, frqfiled_all, frqfiled);
        spafiled_all = cat(3, spafiled_all, spafiled);
    end
    fprintf("ersp_all size: %s\n", mat2str(size(ersp_all))); % 検証用
end

%%
% もつれの時刻を取得
num_all_trials = keystroke_data.data.num_all_trials;
success_duration_end_idx = keystroke_data.success_duration_end; % 打鍵もつれの番号
success_duration_end_time = calculate_success_duration_end_time(num_all_trials, keystroke_data); % 単位は秒

% 図の保存先の指定
% 相対パスの設定
relativePath = fullfile(folderPath, "..", "Analysis");

% 絶対パスに変換
savePath = fullfile(folderPath, "..\..", "Analysis");
savePath = char(java.io.File(savePath).getCanonicalPath());

%%
%% 生波形
draw_raw_wave_per_trial(frqfiled_all, keystroke_data, cfg, success_duration_end_time, savePath);
close all

%% fBosc
% 関心trialの生波形だけ取り出す
% % Rest時
% eeg_data = spafiled_all(1000:10000, :, sort(keystroke_data.data.num_target_trials)); % 時間窓は1ms
% task時
eeg_data = spafiled_all(end-20000:end, :, sort(keystroke_data.data.num_target_trials)); % 時間窓は1ms


% NaN値を線形補間で補間
for t = 1:size(eeg_data, 3)
    eeg_data(:, cfg.coi, t) = fillmissing(eeg_data(:, cfg.coi, t), 'linear');
    eeg_data(:, cfg.coi2, t) = fillmissing(eeg_data(:, cfg.coi2, t), 'linear');
end
sample1 = squeeze(eeg_data(:, cfg.coi, :));
sample2 = squeeze(eeg_data(:, cfg.coi2, :));
[fBOSC1,cfg_fbosc1,TFR1]=run_fbosc(sample1,1000);
[fBOSC2,cfg_fbosc2,TFR2]=run_fbosc(sample2,1000);


%% fBOSC描画
fBOSC_fooof_plot(cfg_fbosc1,fBOSC1)
fBOSC_fooof_plot(cfg_fbosc2,fBOSC2)

%% もつれ時刻とバーストのマッチング
matching_burst_times_with_miseed_times(success_duration_end_time, fBOSC1, sample1);

%% TF
draw_trial_freq_map(ersp_all, keystroke_data, cfg, success_duration_end_time, savePath);

%% 検定
% kentei(frqfiled_all, keystroke_data, success_duration_end_time, savePath);
kentei_C3_C4(frqfiled_all, keystroke_data, success_duration_end_time, success_duration_end_idx, savePath, cfg);

%%
fprintf('このフォルダの解析は終了しました\n\n');

function data = load_data(filePath)
data = load(filePath);
data = data.save_data;
end

function end_time = calculate_success_duration_end_time(num_all_trials, keystroke_data)
for trial_idx = 1:num_all_trials
    end_time(trial_idx) = keystroke_data.data.acceptance_end(trial_idx, keystroke_data.success_duration_end(trial_idx));
end
end