classdef ResultsKeeper
    %RESULTSKEEPER このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        trial
        judge
        success_duration
        current_trial

        % 保存したすべての値
        saved_results
    end

    methods
        function obj = ResultsKeeper(trial)
            %RESULTSKEEPER このクラスのインスタンスを作成
            obj.trial = trial; % 引数のオブジェクトを一括して格納
            obj.judge = trial.Results.judge;
            obj.success_duration = trial.Results.success_duration;
            obj.current_trial = trial.current_trial;
        end

        % ResultsKeeper全体を一括して実行
        function obj = run_results_keeper(obj, judge_range_parameters)
            performance = calculate_results(obj);
            obj = save_results(obj, performance, judge_range_parameters);
        end
    end

    methods (Access = private)
        % 結果に保存する値の算出とコマンドウィンドウへの表示
        function performance = calculate_results(obj)
            % 各種値の算出
            sum_success_keystrokes = sum(obj.judge == 1, "all"); % 全trialの成功打鍵の合計数
            num_required_keystrokes = sum(obj.judge == 0 | obj.judge == 1, "all"); % 全trialでの打鍵すべき回数の合計
            overall_sucesss_rate = sum_success_keystrokes/num_required_keystrokes; % block全体での打鍵成功率：成功打鍵数を打鍵すべき回数で割る
            overall_mean_success_duration = mean(obj.success_duration(1:obj.current_trial)); % block全体での打鍵成功持続時間の平均

            % 完遂trialについて算出
            is_1_or_NaN = all(isnan(obj.judge) | obj.judge == 1, 2); % 全要素が1またはNaN
            has_at_least_one_1 = any(obj.judge == 1, 2); % 少なくとも1つ1が含まれる

            % 完遂trialの番号（何trial目か）
            idx_of_perfect_trials = find(is_1_or_NaN & has_at_least_one_1); % 条件を満たす行のインデックスを取得

            % 完遂trial数
            num_perfect_trials = numel(idx_of_perfect_trials); % 条件を満たす行の個数

            % 算出した値を構造体にまとめる
            performance = struct( ...
                'overall_sucesss_rate', overall_sucesss_rate, ...
                'overall_mean_success_duration', overall_mean_success_duration, ...
                'idx_of_perfect_trials', idx_of_perfect_trials, ...
                'num_perfect_trials', num_perfect_trials ...
                );

            % 算出した値をコマンドウィンドウに表示
            fprintf('\n block results: sum_success_keystrokes = %d, num_required_keystrokes = %d\n', ...
                sum_success_keystrokes, num_required_keystrokes)
            fprintf('overall_sucesss_rate = %d, overall_mean_success_duration = %d\n', ...
                overall_sucesss_rate, overall_mean_success_duration);

            if isempty(idx_of_perfect_trials)
                fprintf('Perfect trials are Nothing!\n');
            else
                fprintf('Perfect trials are %d times\n', num_perfect_trials);
                fprintf('Perfect trials are = trial %s\n', mat2str(idx_of_perfect_trials));
            end
        end

        function obj = save_results(obj, performance, judge_range_parameters)
            % 保存用のデータを取得
            num_participant = obj.trial.settings.ParticipantNumber;
            num_block = obj.trial.settings.BlockNumber;
            block_type = obj.trial.settings.block_type;

            % 保存用の構造体を作成
            block = struct( ...
                'tap_interval_list', obj.trial.Results.tap_interval_list, ...
                'interval_index_recorder', obj.trial.Results.interval_index_recorder, ...
                'tap_intervals', obj.trial.Results.tap_intervals, ...
                'beep_times_keys', obj.trial.Results.beep_times_keys, ...
                'pressed_times', obj.trial.Results.pressed_times, ...
                'keystrokes', obj.trial.Results.keystrokes, ...
                'window_delimiters', obj.trial.Results.window_delimiters, ...
                'judge', obj.judge, ...
                'success_duration', obj.success_duration, ...
                'num_last_trial', obj.current_trial ...
                );

            if block_type == 'S2'
                block.S2_results = obj.trial.Results.S2_results;
            elseif block_type == 'P'
                block.P_determined_interval_index = obj.trial.Results.P_determined_interval_index;
            end

            % 保存先のフォルダの作成
            save_path = obj.create_save_folder(block_type, num_block, num_participant);

            % .matファイルでの保存の実行
            save( ...
                save_path, ...
                'num_participant', ...
                'num_block', ...
                'block', ...
                'judge_range_parameters', ...
                'performance' ...
                );

            % 保存した値を構造体としてobj.saved_resultsに格納
            obj.saved_results = struct( ...
                'num_participant', num_participant, ...
                'num_block', num_block, ...
                'block', block, ...
                'judge_range_parameters', judge_range_parameters, ...
                'performance', performance ...
                );
        end
    end

    methods (Static, Access = private)
        % 保存先のフォルダの作成
        function save_path = create_save_folder(block_type, num_block, num_participant)
            % "Results"フォルダの作成
            results_folder = fullfile(pwd, 'Results'); % 現在のフォルダに"Results"を作成
            if ~exist(results_folder, 'dir')
                mkdir(results_folder);
            end

            % 日付と参加者番号でサブフォルダ名を作成
            current_date = char(datetime('now', 'Format', 'yyyyMMdd')); % 現在の日付を取得
            participant_folder = fullfile(results_folder, sprintf('%s_%s', current_date, num_participant));
            if ~exist(participant_folder, 'dir')
                mkdir(participant_folder); % フォルダが存在しない場合は作成
            end

            % 保存先のファイル名とパスを作成
            block_date = datetime('now', 'Format', 'yyyyMMdd_HHmmss');
            block_filename = sprintf('Block_Result_%s_%s_block%s_%s.mat', ...
                num_participant, block_type, num_block, block_date);
            save_path = fullfile(participant_folder, block_filename);
        end
    end
end
