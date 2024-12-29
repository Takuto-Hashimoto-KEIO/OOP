classdef TaskEvaluator
    %TASKEVALUATOR このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        Results
        window_delimiters

        current_trial
        tap_interval
        judge_range_parameters
        keystrokes
        trial_task_time
    end

    methods
        function obj = TaskEvaluator(Results, current_trial, tap_interval, judge_range_parameters, keystrokes, trial_task_time)
            %TASKEVALUATOR このクラスのインスタンスを作成
            %   詳細説明をここに記述
            obj.Results = Results;

            obj.current_trial = current_trial;
            obj.tap_interval = tap_interval;
            obj.judge_range_parameters = judge_range_parameters;
            obj.keystrokes = keystrokes;
            obj.trial_task_time = trial_task_time;
        end

        % run_post_task 直前のtaskの打鍵判定～打鍵成功持続時間の計算を一貫して実行
        function obj = run_post_task(obj)

            % 「Blank」を画面提示
            cla;
            text(0.5, 0.5, 'Blank', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
            drawnow
            % sendCommand(daq,6); % Blank
            blank_start_time = GetSecs; % [検証用]

            % 打鍵判定
            obj = obj.run_keystrokes_judger();

            % 打鍵成功持続時間の計算
            obj = obj.calculate_success_duration();

            % 「Blank」の画面提示の終了
            blank_time_range = 5 - (GetSecs - blank_start_time); % blankの時間が全体で5秒間になるよう調整
            fprintf('打鍵判定＆解析に要した時間 = %d\n', 5 - blank_time_range); % [検証用]　だいたい20 msぐらいかかってる
            pause(blank_time_range); % 5秒間待機
            cla;
        end

        % 速度変更有無の判定と適用（Main blockだけで実行するため、関数run_post_taskには含めない）
        function [speed_changer, consecutive_same_speeds, interval_index] = speed_regulator(obj, speed_changer, consecutive_same_speeds, interval_index, num_reference_trials, speed_changer_activate_points)
            x = num_reference_trials; % 直近何trialを参照するか[要検討] %%%

            fprintf('consecutive_same_speeds = %d\n', consecutive_same_speeds);
            
            if obj.current_trial >= x % 現在がx trial以上の場合
                last_x_durations = obj.Results.success_duration(obj.current_trial - (x-1):obj.current_trial);
                fprintf('直近%dtrialの打鍵成功持続時間 = ', x);
                for i = 1:x
                    fprintf('%d, ', last_x_durations(i));
                end
                
                if consecutive_same_speeds >= speed_changer_activate_points % 最低でも連続speed_changer_activate_points trialは同じ要求打鍵速度を保つ %%%
                    if all(last_x_durations >= obj.trial_task_time * 0.9) && interval_index <= 10
                        interval_index = interval_index + 1; % 速度上昇
                        speed_changer = 1;
                    elseif all(last_x_durations <= obj.trial_task_time * 0.5) && interval_index >= 2
                        interval_index = interval_index - 1; % 速度低下
                        speed_changer = -1;
                    end
                end

            else % 現在がx trial未満の場合
                last_durations = obj.Results.success_duration(1:obj.current_trial);
                fprintf('ここまでの全trialでの打鍵成功持続時間（秒） = ');
                for i = 1:obj.current_trial
                    fprintf('%d, ', last_durations(i));
                end
            end
            fprintf('\n');

            % 同一打鍵速度継続数の加算・初期化
            if speed_changer == 0
                consecutive_same_speeds = consecutive_same_speeds + 1;
            else
                consecutive_same_speeds = 1;
            end
        end

        % % 被験者の打鍵データから、打鍵判定区間の調整（速度調節block、練習blockのときだけ実行）
        % function obj =
        % end
    end

    methods (Access = private)
        % 打鍵判定の時間窓の決定～打鍵判定（judge配列への格納）、クラスKeystrokesJudgerを起動
        function obj = run_keystrokes_judger(obj)

            judger = KeystrokesJudger(obj);
            [judger, judge_this_trial] = judger.run_keystrokes_judger();

            % このtrialで作成した打鍵判定の時間窓を、配列に格納
            obj.window_delimiters = judger.window_delimiters;

            % このtrialで作成したビープ音の時系列データを、全trialのビープ音を網羅したobj.Results.beep_times_keys配列に格納
            obj.Results.beep_times_keys(obj.current_trial, 1:size(judger.beep_times_keys, 1), :) = judger.beep_times_keys;

            % このtrialの打鍵判定を、全trialの判定結果を網羅したobj.Results.judge配列に格納
            obj.Results.judge(obj.current_trial, 1:obj.keystrokes.num_keystroke_sections) = judge_this_trial;
        end

        % 打鍵成功持続時間の計算
        function obj = calculate_success_duration(obj)

            % 現在のtrialにおいて、成功した打鍵（judgeが1）のインデックスを取得
            success_indices = find(obj.Results.judge(obj.current_trial, :) == 1);

            if ~isempty(success_indices)
                first_success = success_indices(1); % 最初の成功インデックスを取得

                % 最初の成功インデックスに基づいて、task開始～最初の打鍵成功までの時間(秒)を一時計算
                temp_duration = (first_success / obj.keystrokes.num_keystroke_sections) * obj.trial_task_time;

                % temp_durationが3秒より大きい場合は、success_durationを強制的に0とする（最初の打鍵成功が遅すぎるため）
                if temp_duration > 3
                    success_duration_of_this_trial = 0;

                    % このtrialの打鍵成功持続時間を、全trialの結果を網羅したsuccess_duration配列に格納
                    obj.Results.success_duration(obj.current_trial) = success_duration_of_this_trial;
                    return; % function obj = calculate_success_duration(obj)の強制終了
                end

                % 成功した打鍵が存在する場合のみ処理を進める

                % 最初の成功打鍵以降、連続した成功が途切れる直前の最後の成功打鍵の番号を取得
                last_success = success_indices(find(diff(success_indices) ~= 1, 1, 'first'));

                % もし間が空いた成功が見つからない場合、最後の成功打鍵を末尾の成功インデックスとする
                if isempty(last_success)
                    last_success = success_indices(end); % 連続成功が末尾まで続いた場合
                end

                % 成功した期間を、試行のタスク時間の割合から計算
                success_duration_of_this_trial = ((last_success - first_success + 1) / obj.keystrokes.num_keystroke_sections) * obj.trial_task_time;
            
            else
                success_duration_of_this_trial = 0; % 成功した打鍵が1つもない場合
            end

            % このtrialの打鍵成功持続時間を、全trialの結果を網羅したsuccess_duration配列に格納
            obj.Results.success_duration(obj.current_trial) = success_duration_of_this_trial;
        end
    end
end

