% function matching_burst_times_with_miseed_times(success_duration_end_time, FBOSC, eeg_data)
% 
% % === データの設定 ===
% fs = 1000; % サンプリング周波数 (例: 1000Hz)
% t_window = 1 * fs; % 1秒間のデータポイント数
% [num_samples, num_trials] = size(eeg_data);
% time_point = success_duration_end_time*1000;
% Burst = FBOSC.episodes(:, {'Trial', 'Channel', 'FreqGroup', 'Onset', 'Offset'});
% Burst = Burst(Burst.FreqGroup == "Beta", :); % Betaだけ抽出
% % burst_onset = FBOSC.episodes.Onset()
% % burst_offset = FBOSC.episodes.Offset()
% 
% for trial = 1:num_trials
%     burst = Burst(Burst.Trial == trial, :);
%     if time_point(trial) - t_window > 0 && time_point(trial) + t_window <= num_samples
%         burst ;
%     end
% end
% end

function matching_burst_times_with_miseed_times(success_duration_end_time, FBOSC, eeg_data)

    % === データの設定 ===
    fs = 1000; % サンプリング周波数 (例: 1000Hz)
    time_window = 0.5 * fs; % 0.5秒のデータポイント数
    [num_samples, num_trials] = size(eeg_data);
    time_point = success_duration_end_time * fs; % success_duration_end_time をミリ秒単位からサンプル単位に変換
    
    % Beta バーストのみを抽出
    Burst = FBOSC.episodes(:, {'Trial', 'Channel', 'FreqGroup', 'Onset', 'Offset'});
    Burst = Burst(Burst.FreqGroup == "Beta", :);
    
    % 結果を格納する配列
    burst_detected_trials = 0;
    valid_trials = 0;
    
    for trial = 1:num_trials
        if isnan(time_point(trial)) % NaNの場合はスキップ
            continue;
        end
        valid_trials = valid_trials + 1;
        
        % 該当 trial の Burst を抽出
        burst = Burst(Burst.Trial == trial, :);
        
        % 該当 trial の時間ウィンドウを計算
        time_start = time_point(trial) - time_window;
        time_end = time_point(trial) + time_window;

        % 時間範囲がデータ範囲内かチェック
        if time_start < 1 || time_end > num_samples
            continue;
        end

        % Onset ～ Offset が time_start ～ time_end の範囲に収まる Burst の有無をチェック
        valid_bursts = (burst.Onset*1000 >= time_start) & (burst.Offset*1000 <= time_end);

        if any(valid_bursts)
            burst_detected_trials = burst_detected_trials + 1;
        end
    end

    % 全 trial における burst 検出trialの割合を計算
    burst_detection_ratio = burst_detected_trials / valid_trials;

    % 結果の表示
    fprintf('Beta burst detected in %.2f%% of miss time points.\n', burst_detection_ratio * 100);
    
    % === ランダム時間の解析 ===
    num_iterations = 1000;
    random_burst_detected = zeros(num_trials, num_iterations);

    for iter = 1:num_iterations
        for trial = 1:num_trials
            if isnan(time_point(trial)) % NaNの場合はスキップ
                continue;
            end

            % ランダムな時間点を選択（データ範囲内でランダムなポイント）
            random_time_point = randi([1, num_samples]);
            time_start = random_time_point - time_window;
            time_end = random_time_point + time_window;

            % 時間範囲がデータ範囲内かチェック
            if time_start < 1 || time_end > num_samples
                continue;
            end

            % 該当 trial の Burst を抽出
            burst = Burst(Burst.Trial == trial, :);

            % Onset ～ Offset が time_start ～ time_end の範囲に収まる Burst の有無をチェック
            valid_bursts = (burst.Onset*1000 >= time_start) & (burst.Offset*1000 <= time_end);

            if any(valid_bursts)
                random_burst_detected(trial, iter) = 1;
            end
        end
    end

    % ランダムな時間点での burst 検出割合を計算
    random_burst_detection_ratio = sum(random_burst_detected, 'all') / (num_trials * num_iterations);

    % 結果の表示
    fprintf('Beta burst detected in %.2f%% of random time points.\n', random_burst_detection_ratio * 100);
end
