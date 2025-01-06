classdef TaskJudgerPer3Trials
    %TASKJUDGERPER3TRIALS このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        tap_interval_list
        current_trial
        interval_index
        success_duration
        mean_success_durations

        txt
    end

    methods
        function obj = TaskJudgerPer3Trials(current_trial, interval_index, success_duration, tap_interval_list)
            %TASKJUDGERPER3TRIAL このクラスのインスタンスを作成
            obj.tap_interval_list = tap_interval_list;
            obj.current_trial = current_trial;
            obj.interval_index = interval_index;
            obj.success_duration = success_duration;
        end

        % TaskJudgerPer3Trialの全体を一貫して実行
        function [screening2_terminater, S2_results] = run_task_judger_per_3trials(obj, txt)
            fprintf("\n速度レベル適合判定S2\n")

            fprintf("試験した速度レベルは%d, %d, %d\n", obj.interval_index-2, obj.interval_index-1 ,obj.interval_index)
            obj.mean_success_durations = obj.calculate_mean_success_durations();
            fprintf('3trialごとの平均打鍵成功持続時間 = %d, %d, %d\n', obj.mean_success_durations);

            determined_interval_index = obj.determine_interval_index();
            fprintf('determined_interval_index = %d\n', determined_interval_index);

            screening2_terminater = 1; % Screening2の終了判定。0で続行。1で終了

            % 保存する値を構造体化
            S2_results = struct( ...
                'mean_success_durations', obj.mean_success_durations, ...
                'determined_interval_index', determined_interval_index ...
                );

            txt.String = 'Screening 2 Completed';
        end
    end

    methods (Access = private)
        function mean_success_durations = calculate_mean_success_durations(obj)
            mean_success_durations = NaN(3,1);
            for num_speed = 1:3
                mean_success_durations(num_speed) = mean(obj.success_duration(num_speed * 3-2:num_speed * 3)); % この速度での打鍵成功持続時間の平均（trial3回分）
            end
        end

        function determined_interval_index = determine_interval_index(obj)
            if all(obj.mean_success_durations < 15)
                fprintf("\nどの速度でも打鍵成功持続時間は基準値以下でした\n　速度を変えてやり直しなさい\n");
                max_value = max(obj.mean_success_durations); % obj.mean_success_durationsの最大値を取得
                max_indices = find(obj.mean_success_durations == max_value); % obj.mean_success_durationsが最大値を持つ全インデックスを取得
                max_performance_index = max(max_indices); % そのうち最大のインデックス（最大の打鍵速度）を取得
                determined_interval_index = obj.interval_index - (3 - max_performance_index); % やり直しでも、一応保存（save）を動かすために仮でinterval_indexを既定

            else % Main blockでのスタート速度の決定
                max_value = max(obj.mean_success_durations); % mean_error_timeの最大値を取得
                max_indices = find(obj.mean_success_durations == max_value); % 最大値を持つ全インデックスを取得
                max_performance_index = max(max_indices); % 最大のインデックスを取得
                determined_interval_index = obj.interval_index - (3 - max_performance_index);
                fprintf("\nMain blockでの打鍵速度は、レベル%dの%d Hzで始める\n", determined_interval_index, 1/obj.tap_interval_list(determined_interval_index));
                fprintf("ワークスペースで、block.success_durationの全貌を確認し、本当にこの打鍵速度で決定してよいのか検討せよ\n")
            end
        end
    end
end
