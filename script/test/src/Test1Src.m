classdef Test1Src
    % 全被験者の打鍵もつれ時1秒窓のβ振幅変化の検定の、ソースコード

    properties
    end

    methods(Access=public)
        function obj = Test1Src()
        end
    end

    methods (Static)
        % 保存した打鍵データから必要な要素の取得
        function [first_misstap_time_all_sbj, total_taget_trials, total_subjects] = load_tapping_data(tap_data_path)
            file_path = fullfile(tap_data_path, 'tap_data.mat');
            data = load(file_path);
            first_misstap_time_all_sbj = data.tap_data.first_misstap_time; % 「trial数（100）× 被験者数」の配列
            total_taget_trials = data.tap_data.total_target_trials; % 各被験者について、関心trialの総数
            total_subjects = size(first_misstap_time_all_sbj,2);
        end

        % 保存したblock別EEGデータの取得→格納
        function EEG_data_coi_all_sbj = load_EEG_data(EEG_data_path, coi, total_subjects)

            for num_sbj = 1:total_subjects
                file_path = fullfile(EEG_data_path, 'frqfiled_target_trials.mat');
                EEG_data = load(file_path);
                EEG_data = EEG_data.frqfiled_target_trials;
                EEG_data_coi = squeeze(EEG_data(:,coi,:)); % 関心chのみのデータを取得：時間×ch×trial数の配列を、時間×trial数の配列に変換
                EEG_data_coi_all_sbj{num_sbj} = EEG_data_coi;
            end
        end

        function eeg_data = preprocess_EEG(eeg_data)
            % === 包絡線の計算関数 ===
            compute_envelope = @(x) abs(hilbert(x)); % ヒルベルト変換を用いた包絡線

            % 1. 0で埋める & 0で埋めた場所を記録
            nan_mask = isnan(eeg_data); % NaNの位置を記録
            eeg_data(nan_mask) = 0; % NaNを0で埋める

            % 2. Hilbert変換
            eeg_data = compute_envelope(eeg_data); % 先にヒルベルト変換

            % 3. 0で埋めた場所をNaNに戻す
            eeg_data(nan_mask) = NaN;
        end

        % 各被験者者について、打鍵もつれ時サンプルM（1個）・ランダム時のサンプルMR（5000個）を取得
        function [med_env_data, med_rand_env_data] = generate_misstap_EEG_data(EEG_data, first_misstap_time) % first_misstap_timeは1列のデータ

            % 値の設定
            fs = 1000; % サンプリング周波数 (例: 1000Hz)
            t_window = 0.499 * fs; % もつれ前後のデータポイント数
            task_time = 20; % 1taskの所要時間（秒)

            end_time = first_misstap_time * fs + ( ...
                size(EEG_data, 1) - task_time * fs); % もつれの時刻：beep_times_keysのfirst_misstap_indices番目の時刻

            num_counts = 5000; % rand_env_dataを1trialあたりに作る回数

            [num_samples, num_trials] = size(EEG_data);

            % 計算結果を格納する配列の初期化
            env_data = NaN(num_trials, 1);
            rand_env_data = NaN(num_trials, num_counts);

            % もつれ前後の振幅抽出
            for trial = 1:num_trials
                time_point = end_time(trial); % もつれの時刻

                if time_point - t_window > 0 && time_point + t_window <= num_samples
                    segment = EEG_data(time_point-t_window:time_point+t_window, trial);
                    env_signal = segment;
                    env_data(trial) = median(env_signal, "omitmissing"); % 振幅の時間方向の中央値を算出
                end

                med_env_data = median(env_data); % trial方向の中央値を算出
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

                % 選ばれたrand_timeで包絡線計算
                rand_segment = EEG_data(rand_time-t_window:rand_time+t_window, trial);
                rand_env_signal = rand_segment;
                rand_env_data(trial, iter) = median(rand_env_signal, "omitmissing");
            end

            med_rand_env_data = median(rand_env_data, 1); % trial方向の中央値を算出
        end

        % 仮説検定：ランダム時間窓から得られたt値の分布の中で、もつれ時刻のデータのt値（一つ）がどのPercentileにくるのかを見る
        function run_hypothesis_test(t, t_random)
            p_value = sum(t >= t_random) / length(t_random);
            % データの保存
        end
    end
end

