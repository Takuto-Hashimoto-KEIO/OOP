% trialごとにβ振幅の値を正規化、REST の平均値と分散を計算して、trial全体をzスコア化する
function EEG_z_score_all_sbj = generate_EEG_z_score(EEG_data_all_sbj, total_subjects)

    % 被験者ごとのzスコアを格納するセル配列を初期化
    EEG_z_score_all_sbj = cell(total_subjects, 1);

    for sbj_idx = 1:total_subjects
        EEG_data = EEG_data_all_sbj{sbj_idx}; % EEG_data_all_sbj{sbj_idx}は時間×ch×trial数の配列
        [~, ~, num_trials] = size(EEG_data);
        
        % NaNで初期化されたzスコア配列
        EEG_z_score = NaN(size(EEG_data));
        
        % REST期間（最初の1~10秒）のインデックスを取得
        fs = 1000; % サンプリング周波数 (例: 1000Hz)
        rest_indices = 1*fs:10*fs; % 10秒 × 1000Hzと仮定
        
        for coi_idx = 1:size(EEG_data, 2) % chごとにz_scoreを計算
            for trial_idx = 1:num_trials
                trial_data = EEG_data(:, :, trial_idx);

                % NaNを除いてRESTの平均と標準偏差を計算
                rest_data = trial_data(rest_indices, coi_idx);
                rest_mean = mean(rest_data, 'omitnan');
                rest_std = std(rest_data, 'omitnan');

                % 全時間のzスコア計算（NaNはそのまま）
                if rest_std ~= 0
                    z_score = (trial_data(:, coi_idx) - rest_mean) / rest_std;
                else
                    z_score = NaN(size(trial_data)); % 標準偏差が0の場合はNaNを代入
                end

                % NaNの位置を保持
                nan_mask = isnan(trial_data(:, coi_idx));

                % zスコアを格納しつつ、元のNaNを維持
                z_score(nan_mask) = NaN;
                EEG_z_score(:, coi_idx, trial_idx) = z_score;
            end
        end

        % 被験者ごとのzスコアを保存
        EEG_z_score_all_sbj{sbj_idx} = EEG_z_score;
    end
end

