function draw_raw_wave_per_trial(frqfiled_all, keystroke_data, cfg, success_duration_end_time, savePath)

trial_task_time = 20; % 1taskの所要時間（秒）

% 保存用フォルダの作成
savePath = fullfile(savePath, 'raw_wave_of_target_trials_C3andC4_14~30Hz');
if ~exist(savePath, 'dir'), mkdir(savePath); end

% 関心trialの生波形だけ取り出す
frqfiled_target_trials = squeeze(frqfiled_all(:, cfg.coi, sort(keystroke_data.data.num_target_trials)));
frqfiled_target_trials(all(isnan(frqfiled_target_trials), 2), :) = []; % NaN行の削除

frqfiled_target_trials_c2 = squeeze(frqfiled_all(:, cfg.coi2, sort(keystroke_data.data.num_target_trials)));
frqfiled_target_trials_c2(all(isnan(frqfiled_target_trials_c2), 2), :) = []; % NaN行の削除

end_idx = success_duration_end_time * 1000 + (size(frqfiled_all, 1) - success_duration_end_time(end) * 1000);
task_start_time = size(frqfiled_target_trials, 1) - trial_task_time * 1000;

% 生波形の描画
for trial_idx = 1:size(frqfiled_target_trials, 2)
    figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);

    % 上のプロット (cfg.coi の波形)
    subplot(2,1,1); hold on;
    plot(frqfiled_target_trials(:, trial_idx)); ylim([-30 30]);
    xline(end_idx(trial_idx), '--k', 'LineWidth', 2);
    xline(task_start_time, 'k', 'LineWidth', 2);
    title(sprintf('Subject %s Trial %d C3', keystroke_data.data.participant_name, trial_idx));
    fontsize(24,"points")
    hold off;

    % 下のプロット (cfg.coi2 の波形)
    subplot(2,1,2); hold on;
    plot(frqfiled_target_trials_c2(:, trial_idx)); ylim([-30 30]);
    xline(end_idx(trial_idx), '--k', 'LineWidth', 2);
    xline(task_start_time, 'k', 'LineWidth', 2);
    title(sprintf('Subject %s Trial %d C4', keystroke_data.data.participant_name, trial_idx));
    fontsize(24,"points")
    hold off;
end

% 出力した図の保存
figHandles = findall(0, 'Type', 'figure'); % 開いている全てのfigureを取得

for i = 1:length(figHandles)
    fig = figHandles(i);
    figure(fig); % アクティブ化
    % fig.Units = 'normalized';
    % fig.OuterPosition = [0 0 1 1]; % 全画面表示
    % drawnow; % 画面更新を強制
    % pause(0.05); % 描画の安定のための一時停止

    % 保存ファイル名の作成
    saveFileName = fullfile(savePath, sprintf('raw_wave_trial_%02d.png', length(figHandles)-i+1));

    % 図を保存（例: 'figure1.png', 'figure2.png', ...）
    saveas(fig, saveFileName);
end
% save_all_fig('jpg', fullfile(folderPath, fileList(fileIdx).name));
% save_all_fig('fig', fullfile(folderPath, fileList(fileIdx).name)); , keystroke_data.success_duration_end

kentei(frqfiled_target_trials);
kentei(frqfiled_target_trials_c2);

end

