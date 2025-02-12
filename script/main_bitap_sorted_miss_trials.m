clear
addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20240111 codes with Class\Tapping_Analysis\Tapping Analysis with Class");
add_basic_path
addpath(genpath("../src/"));
addpath(genpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc"));
cfg.device = "egi";

keystroke_data_file_path = "C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Results\20250114~ 予備実験4\20250205_Y412\tapping_data\Keystroke_Block_Summary\Sorted_all_trials_Result_Y412.mat"; % 打鍵解析結果のファイルパスを指定
folderPath = "C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Results\20250114~ 予備実験4\20250205_Y412\EEGdata\mat\Main"; % 脳波データのフォルダパスを指定

%% 打鍵解析結果の取得
keystroke_data = load_data(keystroke_data_file_path);

%% 脳波解析
fileList = dir(fullfile(folderPath, '*.mat')); % フォルダ内の.matファイルを取得

ersp_all = [];

for fileIdx = 1:length(fileList)
    close all
    cfg.datapath = fullfile(folderPath, fileList(fileIdx).name); % 各.matファイルのパスを指定
    fprintf('Processing file: %s\n', cfg.datapath); % 処理中のファイル名を表示

    cfg.coi=36;
    cfg.coi2=104;

    % 解析処理
    data_eeg = EEGProcessor;
    data_eeg.epocher = Rest2TaskEpocher; %???
    data_eeg = data_eeg.processing(cfg);
    ersp = data_eeg.ersp; % 時間×周波数(40)×チャンネル数(129)×trial数の配列

    % サイズ確認
    fprintf("ersp size: %s\n", mat2str(size(ersp)));

    if fileIdx == 1
        % 初回はそのまま設定
        ersp_all = ersp;
    else
        % 1時限目（最初の次元）のサイズを調整
        min_dim1 = min(size(ersp_all, 1), size(ersp, 1));
        
        % サイズを統一（大きい方をカット）
        ersp_all = ersp_all(1:min_dim1, :, :, :);
        ersp = ersp(1:min_dim1, :, :, :);

        % 4次元目(trial番号)で全block(100trial)を結合
        ersp_all = cat(4, ersp_all, ersp);
    end

    fprintf("ersp_all size: %s\n", mat2str(size(ersp_all))); % 検証用
end

ersp_target_trials = ersp_all(:,:,:,sort(keystroke_data.data.num_target_trials));
fprintf("ersp_target_trials size: %s\n", mat2str(size(ersp_target_trials))); % 検証用

% α,βそれぞれのFOIを決定
addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc\all_level_src\subSrc\fcn_findFOI.m");
[FOI, ~] = fcn_findFOI(squeeze(median(ersp_target_trials(:, :, cfg.coi, :), 4, "omitnan"))', ...
    size(ersp_target_trials, 1)-200:size(ersp_target_trials, 1), 1); % 2次元目はtaskの時間窓のindex
alphaFOI = mean(FOI(1,:));
betaFOI = mean(FOI(2,:));

% TF
% Alphaについては、IAF±1Hz, Betaについては±2 HzでERSPの平均をとる
ersp_c3_alpha = squeeze(mean(ersp_target_trials(:, alphaFOI-1:alphaFOI+1, cfg.coi, :), 2)); % 時間（100ms）×trial数の配列に変換
ersp_c4_alpha = squeeze(mean(ersp_target_trials(:, alphaFOI-1:alphaFOI+1, cfg.coi2, :), 2)); % 時間（100ms）×trial数の配列に変換
ersp_c3_beta = squeeze(mean(ersp_target_trials(:, betaFOI-2:betaFOI+2, cfg.coi, :), 2)); % 時間（100ms）×trial数の配列に変換
ersp_c4_beta = squeeze(mean(ersp_target_trials(:, betaFOI-2:betaFOI+2, cfg.coi2, :), 2)); % 時間（100ms）×trial数の配列に変換

% TF描画の旧コード
% ersp_c3 = ersp_c3'; % 1,2次元目を逆転させ、(frq,time)にする
% TFDrawer.draw(ersp_c3, size(ersp_c3, 1) / 10);

ersp_c3_alpha = fillmissing(ersp_c3_alpha, 'linear', 1); % NaN値を線形補間で補完
ersp_c4_alpha = fillmissing(ersp_c4_alpha, 'linear', 1); % NaN値を線形補間で補完
ersp_c3_beta = fillmissing(ersp_c3_beta, 'linear', 1); % NaN値を線形補間で補完
ersp_c4_beta = fillmissing(ersp_c4_beta, 'linear', 1); % NaN値を線形補間で補完

fig_title = {['ERSP C3 alpha ' num2str(alphaFOI) ' Hz'] ['ERSP C4 alpha ' num2str(alphaFOI) ' Hz']
    ['ERSP C3 beta ' num2str(betaFOI) ' Hz'] ['ERSP C4 beta ' num2str(betaFOI) ' Hz']}; % グラフタイトルを作成
num_all_trials = keystroke_data.data.num_all_trials;
success_duration_end_time = calculate_success_duration_end_time(num_all_trials, keystroke_data);
end_time = NaN(length(success_duration_end_time), 1);
for trial_idx = 1:length(success_duration_end_time)
    end_time(trial_idx) = success_duration_end_time(trial_idx)*10 + (size(ersp_c3_alpha, 1) - success_duration_end_time(end)*10);
end

[~, ~] = draw_ersp_tf(ersp_c3_alpha, 1:size(ersp_c3_alpha, 2), fig_title{1}, num_all_trials, end_time);
[~, ~] = draw_ersp_tf(ersp_c4_alpha, 1:size(ersp_c4_alpha, 2), fig_title{2}, num_all_trials, end_time);
[~, ~] = draw_ersp_tf(ersp_c3_beta, 1:size(ersp_c3_beta, 2), fig_title{3}, num_all_trials, end_time);
[~, ~] = draw_ersp_tf(ersp_c4_beta, 1:size(ersp_c4_beta, 2), fig_title{4}, num_all_trials, end_time);

% 出力した図の保存
figHandles = findall(0, 'Type', 'figure'); % 開いている全てのfigureを取得

for i = 1:length(figHandles)
    fig = figHandles(i);
    figure(fig); % アクティブ化
    fig.Units = 'normalized';
    fig.OuterPosition = [0 0 1 1]; % 全画面表示
    drawnow; % 画面更新を強制
    pause(0.1); % 描画の安定のための一時停止   
    
    % 保存ファイル名の作成
    saveFileName = fullfile(folderPath, sprintf('figure%d.png', i));
    
    % 図を保存（例: 'figure1.png', 'figure2.png', ...）
    saveas(fig, saveFileName);
end
% save_all_fig('jpg', fullfile(folderPath, fileList(fileIdx).name));
% save_all_fig('fig', fullfile(folderPath, fileList(fileIdx).name)); , keystroke_data.success_duration_end

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