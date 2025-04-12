% 1被験者について、打鍵もつれ時サンプルM（1個）・ランダム時のサンプルMR（5000個）を取得
function [med_env_data, med_rand_env_data, num_miss_trials] = generate_misstap_EEG_data( ...
    EEG_data, tap_end_hand_labels, first_misstap_time, num_trials)
% EEG_dataは時間×ch×trial数の配列、first_misstap_timeは1列のデータ、tap_end_hand_labelsはtrialごとのもつれ時の関心chを記録（EEG_dataの2次元目のidxに対応）

% first_misstap_timeからNaNが格納されていないtrial（打鍵もつれが無かったtrial or データのない余剰trial）の番号だけ除外
miss_trial_indeces = find(~isnan(first_misstap_time) == 1 & first_misstap_time >= 0.5); % 打鍵もつれのあったtrialの番号を取得
% → つまり、打鍵がすべて成功したtrialとtask開始3秒以上経過してから打鍵に初めて成功したtrialの番号を除く

num_miss_trials = length(miss_trial_indeces); % 打鍵もつれのあったtrialの総数
fprintf("\n打鍵もつれのあったtrialの総数は、%d\n", num_miss_trials)
fprintf("打鍵もつれのなかったtrialの総数は、%d\n\n", num_trials - num_miss_trials)

% 値の設定
fs = 1000; % サンプリング周波数 (例: 1000Hz)
t_window = 0.499 * fs; % もつれ前後のデータポイント数
task_time = 20; % 1taskの所要時間（秒)

end_time = first_misstap_time * fs + ( ...
    size(EEG_data, 1) - task_time * fs); % もつれの時刻：beep_times_keysのfirst_misstap_indices番目の時刻、task開始時刻を0とする

num_counts = 5000; % rand_env_dataを1trialあたりに作る回数

[num_samples, ~, ~] = size(EEG_data);

% 計算結果を格納する配列の初期化
env_data = NaN(num_trials, 1);
rand_env_data = NaN(num_trials, num_counts);

% もつれ前後の振幅中央値の算出
for i = 1:length(miss_trial_indeces) % もつれたtrialについてのみ振幅中央値の算出
    trial_idx = miss_trial_indeces(i);

    time_point = end_time(trial_idx); % このtrialのもつれの時刻の取得
    elec = tap_end_hand_labels(trial_idx); % このtrialのもつれた手の支配半球chの対応番号1 or 2を取得

    if time_point - t_window > 0 && time_point + t_window <= num_samples
        segment = EEG_data(time_point-t_window:time_point+t_window, elec, trial_idx);
        env_signal = segment;
        env_data(trial_idx) = median(env_signal, "omitmissing"); % 振幅の時間方向の中央値を算出
    end

    % ランダム時間の振幅抽出
    for iter = 1:num_counts % 5000回繰り返す

        valid_rand_time = false;

        while ~valid_rand_time % もつれ時刻とは重なっていない時間窓を選択するまで繰り返す
            rand_time = randi([t_window+1 + (num_samples-task_time*fs), num_samples-t_window]); % 1秒分の余裕を持ってランダム選択

            if abs(rand_time - time_point) > 2*t_window % もつれ時刻とは重なっていない時間窓を選択
                valid_rand_time = true;
            end

        end

        rand_segment = EEG_data(rand_time-t_window:rand_time+t_window, elec, trial_idx);
        rand_env_signal = rand_segment;
        rand_env_data(trial_idx, iter) = median(rand_env_signal, "omitmissing"); % 振幅の時間方向の中央値を算出
    end
end

med_env_data = median(env_data, "omitmissing"); % trial方向の中央値を算出
med_rand_env_data = median(rand_env_data, 1, "omitmissing"); % trial方向の中央値を算出

end
