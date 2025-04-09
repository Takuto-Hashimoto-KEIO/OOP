% 全電極で、ミス時の脳波のパワーを並び替え検定、有意な電極を探す
function kentei(frqfiled_all, keystroke_data, success_duration_end_time, savePath)

% 関心trialの生波形だけ取り出す
eeg_data = frqfiled_all(:, :, keystroke_data.data.num_target_trials); % 時間窓は1ms
% NaN値を線形補間で補間
for t = 1:size(eeg_data, 3)
    for ch = 1:size(eeg_data, 2)
        eeg_data(:, ch, t) = fillmissing(eeg_data(:, ch, t), 'linear');
    end
end

% 保存用フォルダの作成
savePath = fullfile(savePath, 'burst_sorting_test');
if ~exist(savePath, 'dir'), mkdir(savePath); end

% === データの設定 ===
fs = 1000; % サンプリング周波数 (例: 1000Hz)
t_window = 0.5 * fs; % もつれ前後のデータポイント数
[num_samples, num_electrodes, num_trials] = size(eeg_data);

% === 包絡線の計算関数 ===
compute_envelope = @(x) abs(hilbert(x)); % ヒルベルト変換を用いた包絡線

% === もつれ前後の包絡線解析 ===
env_data = zeros(num_electrodes, num_trials);
rand_env_data = zeros(num_electrodes, num_trials, 1000);
task_time = 20; % 1taskの所要時間（秒
end_idx = success_duration_end_time * 1000 + ( ...
    size(frqfiled_all, 1) - task_time * 1000); % もつれの時刻：最後の打鍵成功の判定区間の終わりが中心

for trial = 1:num_trials
    time_point = end_idx(trial); % もつれの時刻 (サンプル番号)

    % もつれ前後のデータ抽出
    if time_point - t_window > 0 && time_point + t_window <= num_samples
        for elec = 1:num_electrodes
            segment = eeg_data(time_point-t_window:time_point+t_window, elec, trial);
            env_signal = compute_envelope(segment);
            env_data(elec, trial) = mean(env_signal); % 平均包絡線値
        end
    end

    % ランダム時間での包絡線解析 (1000回)
    for iter = 1:1000
        valid_rand_time = false;

        while ~valid_rand_time
            % rand_time = randi([t_window+1, num_samples-t_window]); % 1秒分の余裕を持ってランダム選択 [Restも含んでいるので誤り]
            rand_time = randi([t_window+1 + (num_samples-task_time*fs), num_samples-t_window]); % 1秒分の余裕を持ってランダム選択
            if abs(rand_time - time_point) > 2*t_window % もつれ時刻とは異なる時間を選択
                valid_rand_time = true;
            end
        end

        % 選ばれたrand_timeで包絡線計算
        for elec = 1:num_electrodes
            rand_segment = eeg_data(rand_time-t_window:rand_time+t_window, elec, trial);
            rand_env_signal = compute_envelope(rand_segment);
            rand_env_data(elec, trial, iter) = mean(rand_env_signal);
        end
    end
end

%% === 並べ替え検定 (Permutation Test) ===
p_values = zeros(num_electrodes, 1);
num_permutations = 5000;

for elec = 1:num_electrodes
    true_diffs = mean(env_data(elec, :)) - mean(mean(rand_env_data(elec, :, :), 3));
    perm_diffs = zeros(num_permutations, 1);
    
    for perm = 1:num_permutations % [質問]ここおかしくない？
        perm_idx = randperm(num_trials);
        perm_diffs(perm) = mean(env_data(elec, perm_idx)) - mean(mean(rand_env_data(elec, :, :), 3));
    end

    % p値の計算
    p_values(elec) = sum(abs(perm_diffs) >= abs(true_diffs)) / num_permutations;
end

% === 結果の表示 ===
significant_electrodes = find(p_values < 0.05); % 有意水準5%の電極を取得
disp('有意な電極:')
disp(significant_electrodes)

% p値をヒストグラムで可視化
figure;
histogram(p_values, 20);
xlabel('p-value');
ylabel('Number of Channnels');
title(sprintf('Subject %s Permutation Test Results', keystroke_data.data.participant_name));

% 有意な電極のマーカー
hold on;
y_limits = ylim;
plot([0.05 0.05], y_limits, 'r--', 'LineWidth', 2);
hold off;

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
    saveFileName = fullfile(savePath, sprintf( ...
        'beta_burst_sorting_test_%02d.png', length(figHandles)-i+1));

    % 図を保存（例: 'figure1.png', 'figure2.png', ...）
    saveas(fig, saveFileName);
end
% save_all_fig('jpg', fullfile(folderPath, fileList(fileIdx).name));
% save_all_fig('fig', fullfile(folderPath, fileList(fileIdx).name)); , keystroke_data.success_duration_end
end
