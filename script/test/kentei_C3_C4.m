% C3,C4の脳波のみで、ミス時の制御半球の脳波のパワーを並び替え検定
function kentei_C3_C4(frqfiled_all, keystroke_data, success_duration_end_time, success_duration_end_idx, savePath, cfg)

% 関心trialの決定
target_color = 4; % 打鍵成功持続時間：1なら18秒以上、3なら5秒未満、2ならその間、4なら編集せずそのまま全体を返す
[num_target_trials,  success_duration_end_idx, success_duration_end_time] = decide_target_trials( ...
    keystroke_data.data.num_target_trials, success_duration_end_time, success_duration_end_idx, target_color);

% 関心trialの生波形や成功持続時間だけ取り出す
eeg_data = frqfiled_all(:, :, num_target_trials); % 時間窓は1ms,打鍵成功持続時間の昇順にtrialを格納

% % NaN値を線形補間で補間 岩間先生の指示で除去（20240218）
% for t = 1:size(eeg_data, 3)
%     for ch = 1:size(eeg_data, 2)
%         eeg_data(:, ch, t) = fillmissing(eeg_data(:, ch, t), 'linear');
%     end
% end

% 保存用フォルダの作成
savePath = fullfile(savePath, 'beta_burst_sorting_test_miss_point_median');
if ~exist(savePath, 'dir'), mkdir(savePath); end

% === データの設定 ===
fs = 1000; % サンプリング周波数 (例: 1000Hz)
t_window = 0.499 * fs; % もつれ前後のデータポイント数
[num_samples, ~, num_trials] = size(eeg_data);
num_permutations = 5000; % rand_env_dataを1trialあたりに作る数

% === 包絡線の計算関数 ===
compute_envelope = @(x) abs(hilbert(x)); % ヒルベルト変換を用いた包絡線

% 1. 0で埋める & 0で埋めた場所を記録
nan_mask = isnan(eeg_data); % NaNの位置を記録
eeg_data(nan_mask) = 0; % NaNを0で埋める

% 2. Hilbert変換
eeg_data = compute_envelope(eeg_data); % 先にヒルベルト変換

% 3. 0で埋めた場所をNaNに戻す
eeg_data(nan_mask) = NaN;

% === もつれ前後の包絡線解析 ===
env_data = zeros(num_trials, 1);
rand_env_data = zeros(num_trials, num_permutations);
task_time = 20; % 1taskの所要時間（秒)
end_idx = success_duration_end_time * fs + ( ...
    size(frqfiled_all, 1) - task_time * fs); % もつれの時刻：最後の打鍵成功の判定区間の終わりが中心

% trialごとにもつれた手をラベル付け
end_hand_labels = mod(success_duration_end_idx, 2); % 右手なら0、左手なら1
% end_hand_labels = mod(end_hand_labels+1, 2); % 関心半球を入れ替える処理（コントロールの検定用、通常はコメントアウト）

for trial = 1:num_trials
    time_point = end_idx(trial); % もつれの時刻 (サンプル番号)
    if end_hand_labels == 0 % 右手でもつれ
        elec = cfg.coi;
    else % 左手でもつれ
        elec = cfg.coi2;
    end
    % もつれ前後のデータ抽出
    if time_point - t_window > 0 && time_point + t_window <= num_samples
        segment = eeg_data(time_point-t_window:time_point+t_window, elec, trial);
        % env_signal = compute_envelope(segment);
        env_signal = segment;
        env_data(trial) = median(env_signal, "omitmissing"); % 平均包絡線値
    end

    % ランダム時間での包絡線解析 (5000回)
    for iter = 1:num_permutations
        valid_rand_time = false;

        while ~valid_rand_time
            % rand_time = randi([t_window+1, num_samples-t_window]); % 1秒分の余裕を持ってランダム選択 [Restも含んでいるので誤り]
            rand_time = randi([t_window+1 + (num_samples-task_time*fs), num_samples-t_window]); % 1秒分の余裕を持ってランダム選択
            % rand_time = randi([t_window+1 + (num_samples-task_time*fs*1), num_samples-task_time*fs*0.75-t_window]); % 1秒分の余裕を持ってランダム選択 [仮説検証用]

            if abs(rand_time - time_point) > 2*t_window % もつれ時刻とは異なる時間を選択
                valid_rand_time = true;
            end
        end

        % 選ばれたrand_timeで包絡線計算
        rand_segment = eeg_data(rand_time-t_window:rand_time+t_window, elec, trial);
        % rand_env_signal = compute_envelope(rand_segment);
        rand_env_signal = rand_segment;
        rand_env_data(trial, iter) = median(rand_env_signal, "omitmissing");
    end
end

valid_idx = env_data ~= 0; % [岩間先生に確認] 対象外の時間窓のtrialを削除
env_data = env_data(valid_idx);
rand_env_data = rand_env_data(valid_idx, :); % 0を除去したデータに対応
num_trials = size(env_data, 1);
fprintf('有効なtrial数は%d trial\n', num_trials);

%% === 並べ替え検定 (Permutation Test) ===
% p値の計算 関心時間窓のパワーの、ランダム時間窓のパワー分布における位置
med_env_data = median(env_data);
med_rand_env_data = median(rand_env_data, 1);
p_value = sum(med_env_data >= med_rand_env_data) / num_permutations;

% 結果の出力
fprintf('Permutation test p-value: %.5f\n', p_value);

% 結果の保存
save(fullfile(savePath, 'permutation_test_results.mat'), 'p_value', 'num_trials', 'target_color');

% p値をヒストグラムで可視化
figure;
histogram(med_rand_env_data, 20);
xlabel(sprintf('全%dtrialのβ振幅の中央値 [μV]', num_trials));
ylabel('trial数');
% title(sprintf('Subject %s 並び替え検定', keystroke_data.data.participant_name));
title(sprintf('打鍵もつれ時の並び替え検定'));
% title(sprintf('打鍵もつれ時の並び替え検定 非制御半球'));

hold on;
% med_env_data の位置に赤い破線を追加
xline(med_env_data, '--r', 'LineWidth', 3);
% p_value を med_env_data の位置に赤い文字で表示
text(med_env_data + 0.02 * range(xlim), max(ylim) * 0.9, sprintf('p = %.5f', p_value), ...
    'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
fontsize(42,"points");
hold off;

% 出力した図の保存
    figHandles = findall(0, 'Type', 'figure'); % 開いている全てのfigureを取得

for i = 1:length(figHandles)
    fig = figHandles(i);
    figure(fig); % アクティブ化
    % fig.Units = 'normalized';
    % fig.OuterPosition = [0 0 1 1]; % 全画面表示
    fig.Units = 'normalized';
    fig.OuterPosition = [0.25 0 0.5 1]; % 縦長の設定
    drawnow; % 画面更新を強制
    pause(0.05); % 描画の安定のための一時停止

    % 保存ファイル名の作成
    saveFileName = fullfile(savePath, sprintf( ...
        'beta_burst_sorting_test_control_color_%d_fig%02d.png', target_color, length(figHandles)-i+1));

    % 図を保存（例: 'figure1.png', 'figure2.png', ...）
    saveas(fig, saveFileName);
end

close all

% % === 並べ替え検定 (Permutation Test) ===
% p_values = 0;
% num_permutations = 1000;
% env_data = env_data(env_data ~= 0);
% true_diffs = mean(env_data) - mean(mean(rand_env_data(:,:),2));
% perm_diffs = zeros(num_permutations, 1);
% 
% num_trials = size(env_data, 1);
% for perm = 1:num_permutations
%     perm_idx = randperm(num_trials);
%     perm_diffs(perm) = mean(env_data(perm_idx)) - mean(mean(rand_env_data(:,:),2));
% end
%
% % p値の計算
% p_values = sum(abs(perm_diffs) >= abs(true_diffs)) / num_permutations;
%
% % === 結果の表示 ===

    % 打鍵成功持続時間に基づくtarget_trialの決定
    function [num_target_trials, success_duration_end_idx, success_duration_end_time] = decide_target_trials( ...
            num_target_trials, success_duration_end_time, success_duration_end_idx, target_color)
        trial_task_time = 20; % 1taskの所要時間（秒）
        switch target_color
            case 1 % 青
                mask = success_duration_end_time >= trial_task_time * 0.9;
            case 2 % 緑
                mask = (success_duration_end_time >= trial_task_time * 0.25) & (success_duration_end_time <= trial_task_time * 0.9);
            case 3 % 赤
                mask = success_duration_end_time < trial_task_time * 0.25;
            case 4 % 全体
                mask = success_duration_end_time >= 0;
        end

        % フィルタリング処理
        num_target_trials = num_target_trials(mask);
        success_duration_end_idx = success_duration_end_idx(mask);
        success_duration_end_time = success_duration_end_time(mask);
    end
end

