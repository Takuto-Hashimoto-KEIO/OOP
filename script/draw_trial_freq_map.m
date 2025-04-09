function draw_trial_freq_map(ersp_all, keystroke_data, cfg, success_duration_end_time, savePath)

% 保存用フォルダの作成
savePath = fullfile(savePath, 'ERSP_of_taget_trials');
if ~exist(savePath, 'dir')
    mkdir(savePath);
end

% 関心trialのERSPだけ取り出す
ersp_target_trials = ersp_all(:,:,:,sort(keystroke_data.data.num_target_trials));
fprintf("ersp_target_trials size: %s\n", mat2str(size(ersp_target_trials))); % 検証用

% α,βそれぞれのFOIを決定
addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc\all_level_src\subSrc\fcn_findFOI.m");
[FOI, ~] = fcn_findFOI(squeeze(median(ersp_target_trials(:, :, cfg.coi, :), 4, "omitnan"))', ...
    size(ersp_target_trials, 1)-200:size(ersp_target_trials, 1), 1); % 2次元目はtaskの時間窓のindex
alphaFOI = mean(FOI(1,:));
betaFOI = mean(FOI(2,:));

% Alphaについては、IAF±1Hz, Betaについては±2 HzでERSPの平均をとる
ersp_c3_alpha = squeeze(mean(ersp_target_trials(:, alphaFOI-1:alphaFOI+1, cfg.coi, :), 2)); % 時間（100ms）×trial数の配列に変換
ersp_c4_alpha = squeeze(mean(ersp_target_trials(:, alphaFOI-1:alphaFOI+1, cfg.coi2, :), 2)); % 時間（100ms）×trial数の配列に変換
ersp_c3_beta = squeeze(mean(ersp_target_trials(:, betaFOI-2:betaFOI+2, cfg.coi, :), 2)); % 時間（100ms）×trial数の配列に変換
ersp_c4_beta = squeeze(mean(ersp_target_trials(:, betaFOI-2:betaFOI+2, cfg.coi2, :), 2)); % 時間（100ms）×trial数の配列に変換

% NaN行(同一時間で全trialがNaN)の削除処理
ersp_c3_alpha(all(isnan(ersp_c3_alpha), 2), :) = [];
ersp_c4_alpha(all(isnan(ersp_c4_alpha), 2), :) = [];
ersp_c3_beta(all(isnan(ersp_c3_beta), 2), :) = [];
ersp_c4_beta(all(isnan(ersp_c4_beta), 2), :) = [];

% TF描画の旧コード
% ersp_c3 = ersp_c3'; % 1,2次元目を逆転させ、(frq,time)にする
% TFDrawer.draw(ersp_c3, size(ersp_c3, 1) / 10);

ersp_c3_alpha = fillmissing(ersp_c3_alpha, 'linear', 1); % NaN値を線形補間で補間
ersp_c4_alpha = fillmissing(ersp_c4_alpha, 'linear', 1); % NaN値を線形補間で補間
ersp_c3_beta = fillmissing(ersp_c3_beta, 'linear', 1); % NaN値を線形補間で補間
ersp_c4_beta = fillmissing(ersp_c4_beta, 'linear', 1); % NaN値を線形補間で補間

fig_title = {
    [sprintf('Subject %s ERSP C3 alpha %d～%d Hz',keystroke_data.data.participant_name, FOI(1,1) ,FOI(1,end))]
    [sprintf('Subject %s ERSP C4 alpha %d～%d Hz',keystroke_data.data.participant_name, FOI(1,1) ,FOI(1,end))] 
    [sprintf('Subject %s ERSP C3 beta %d～%d Hz',keystroke_data.data.participant_name, FOI(2,1) ,FOI(2,end))]
    [sprintf('Subject %s ERSP C4 betaa %d～%d Hz',keystroke_data.data.participant_name, FOI(2,1) ,FOI(2,end))] 
    }; % グラフタイトルを作成
num_all_trials = keystroke_data.data.num_all_trials;
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
    pause(0.05); % 描画の安定のための一時停止

    % 保存ファイル名の作成
    saveFileName = fullfile(savePath, sprintf('ERSP_%d.png', i));

    % 図を保存（例: 'figure1.png', 'figure2.png', ...）
    saveas(fig, saveFileName);
end
% save_all_fig('jpg', fullfile(folderPath, fileList(fileIdx).name));
% save_all_fig('fig', fullfile(folderPath, fileList(fileIdx).name)); , keystroke_data.success_duration_end

end