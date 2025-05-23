classdef Test2AllChannelAmplitudeAtMiss
    % 全被験者の打鍵もつれ時1秒窓のβ振幅変化の検定

    properties
    end

    methods(Access=public)
        function obj = Test2AllChannelAmplitudeAtMiss()
        end
    end

    methods (Static)
        % このクラスのすべての処理を一貫して実行
        function p_value = run(coi, EEG_data_all_sbj, first_misstap_time_all_sbj, total_taget_trials, total_subjects, save_path)
            fprintf("processing ch%d\n", coi);

            %% ヒルベルト変換などの前処理
            processed_EEG_data_coi_all_sbj = cell(total_subjects, 1); % 出力配列の初期化
            for sbj_idx = 1:total_subjects
                EEG_data_all_ch = EEG_data_all_sbj{sbj_idx}; % 1被験者のデータを取得
                EEG_coi_data = EEG_data_all_ch(:, coi, :); % coiのみデータを取得
                processed_EEG_data_coi_all_sbj{sbj_idx} = preprocess_EEG(EEG_coi_data);
            end

            %% trialごとにβ振幅の値を正規化、REST の平均値と分散を計算して、trial全体をzスコア化する
            EEG_z_score_all_sbj = generate_EEG_z_score(processed_EEG_data_coi_all_sbj, total_subjects);

            %% 計算結果を格納する配列の初期化
            num_counts = 5000;
            misstap_EEG_data_all_sbj = NaN(total_subjects, 1);
            rand_EEG_data_all_sbj = NaN(total_subjects, num_counts);
            num_miss_trials_all_sbj = NaN(total_subjects, 1);
            t_random = NaN(num_counts, 1);

            %% 各被験者について、データ取得
            for sbj_idx = 1:total_subjects
                [misstap_EEG_data, rand_EEG_data, num_miss_trials] = generate_misstap_EEG_data_all_ch_ver( ...
                    EEG_z_score_all_sbj{sbj_idx}, squeeze(first_misstap_time_all_sbj(:,sbj_idx)), total_taget_trials(sbj_idx));
                misstap_EEG_data_all_sbj(sbj_idx) = misstap_EEG_data;
                rand_EEG_data_all_sbj(sbj_idx,:) = rand_EEG_data;
                num_miss_trials_all_sbj(sbj_idx) = num_miss_trials; % 打鍵もつれがあったtrialの総数
            end

            %% もつれの時刻でのt値を計算
            [~,~,~,stats] = ttest(misstap_EEG_data_all_sbj);
            t_miss = stats.tstat;

            %% ランダム時刻でのt値を計算            
            for i = 1:num_counts
                [~,~,~,stats] = ttest(squeeze(rand_EEG_data_all_sbj(:,i)));
                t_random(i) = stats.tstat;
            end

            %% 仮説検定：ランダム時間窓から得られたt値の分布の中で、もつれ時刻のデータのt値（一つ）がどのPercentileにくるのかを見る
            p_value = run_hypothesis_test(t_miss, t_random, save_path, coi);

            %% 出力データの整理、保存
            test2 = struct('p_value', p_value, 't_miss', t_miss, 't_random', t_random, ...
                'misstap_EEG_data_all_sbj', misstap_EEG_data_all_sbj, 'rand_EEG_data_all_sbj', ...
                rand_EEG_data_all_sbj, 'num_miss_trials_all_sbj', num_miss_trials_all_sbj, 'coi', coi);
            % save(fullfile(save_path, sprintf('alpha_burst_test_results_coi=%d.mat', coi)), 'test2');
            save(fullfile(save_path, sprintf('beta_burst_test_results_coi=%d.mat', coi)), 'test2');
            disp('OK')
        end
    end

end
