classdef TaskJudgerPer5Trials
    %TASKJUDGERPER5TRIALS このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        tap_interval_list
        trial_task_time

        current_trial
        interval_index
        success_duration

        txt
    end

    methods
        function obj = TaskJudgerPer5Trials(current_trial, interval_index, success_duration, tap_interval_list, trial_task_time)
            %TASKJUDGERPER5TRIAL このクラスのインスタンスを作成
            obj.tap_interval_list = tap_interval_list;
            obj.trial_task_time = trial_task_time;

            obj.current_trial = current_trial;
            obj.interval_index = interval_index;
            obj.success_duration = success_duration;
        end

        % TaskJudgerPer5Trialの全体を一貫して実行
        function [practice_terminater, next_interval_index, determined_interval_index] = run_task_judger_per_5trials(obj, txt)
            obj.txt = txt;
            fprintf("\n速度レベル適合判定_P\n")
            fprintf("試験した速度レベルは%d\n", obj.interval_index)

            [practice_terminater, next_interval_index, determined_interval_index] = obj.retry_end_judger();
        end
    end

    methods (Access = private)
        % 1周(5trial)の打鍵成功持続時間から、もう1周再挑戦するか、練習blockを終了するかを判定
        function [practice_terminater, next_interval_index, determined_interval_index] = retry_end_judger(obj)

            practice_terminater = 0; % practice_blockの終了判定、0で継続、1で終了
            determined_interval_index = 0; % 初期値を仮置き

            % 直近5trialの打鍵成功持続時間
            last_5_success_durations = obj.success_duration(obj.current_trial-4:obj.current_trial);
            fprintf('直近5trialの打鍵成功持続時間 = %d, %d, %d, %d, %d\n', last_5_success_durations);

            if obj.current_trial == 25 % 5周目の場合。最大5周まで。6周目以降はやらせない
                % クリア判定のみ行う
                if sum(last_5_success_durations >= obj.trial_task_time*0.9) >= 3 % 直近5trial中 3trial以上で打鍵成功持続時間が20秒間以上になったら終了
                    fprintf("打鍵成功持続時間が18秒以上のtrialが3つ以上です。\n");

                    if sum(last_5_success_durations >= obj.trial_task_time*0.5) >= 4
                        fprintf("打鍵成功持続時間が10秒未満のtrialが1つ以下です。\n");
                        fprintf("\n練習blockのクリア条件達成。\n");
                        next_interval_index = 0; % 仮置き
                        determined_interval_index = obj.interval_index; % main block開始時の要求打鍵速度を今の速度に決定
                        fprintf('determined_interval_index = %d\n', determined_interval_index);
                        fprintf("ワークスペースで、block.success_durationの全貌を確認し、本当にこの要求打鍵速度で決定してよいのか検討せよ\n")
                        % sendCommand(daq,7);  % practice_blockの終了
                        obj.txt.String = 'Practice Block Completed';
                        pause(2);
                        practice_terminater = 1; % practice_blockの終了
                    end

                else % クリアでなかった場合
                    determined_interval_index = obj.interval_index; % 速度レベルを仮置き
                    next_interval_index = 0; % 仮置き

                    fprintf("5周目まで終了しましたが、打鍵基準は達成されませんでした");
                    % sendCommand(daq,7);  % practice_blockの終了
                    obj.txt.String = 'Practice Block Terminated';
                    pause(2);
                    practice_terminater = 1; % practice_blockの終了
                end


            else % 4周目までの場合
                if sum(last_5_success_durations >= obj.trial_task_time*0.9) == 5 % 直近5trial全てで打鍵成功持続時間が18秒間以上になったら速度レベルを1つ上げて再挑戦（ただし、5周目では速度を変えない）
                    fprintf("5trial全てで打鍵成功持続時間が18秒間以上です。速度を1段階上げて再挑戦します。\n");
                    obj.txt.String = 'Speed Up! & Try Again!';
                    pause(2);
                    if obj.interval_index ~= length(obj.tap_interval_list) % 最大の打鍵速度ではないことを確認
                        next_interval_index = obj.interval_index + 1; % 打鍵速度増加
                    end

                elseif sum(last_5_success_durations >= obj.trial_task_time*0.9) >= 3 % 直近5trial中 3trial以上で打鍵成功持続時間が20秒間以上になったら終了
                    fprintf("打鍵成功持続時間が18秒以上のtrialが3つ以上です。\n");

                    if sum(last_5_success_durations >= obj.trial_task_time*0.5) >= 4
                        fprintf("打鍵成功持続時間が10秒未満のtrialが1つ以下です。\n");
                        fprintf("\n練習blockのクリア条件達成。\n");
                        next_interval_index = 0; % 仮置き
                        determined_interval_index = obj.interval_index; % main block開始時の要求打鍵速度を今の速度に決定
                        fprintf('determined_interval_index = %d\n', determined_interval_index);
                        fprintf("ワークスペースで、block.success_durationの全貌を確認し、本当にこの要求打鍵速度で決定してよいのか検討せよ\n")
                        % sendCommand(daq,7);  % practice_blockの終了
                        obj.txt.String = 'Practice Block Completed';
                        pause(2);
                        practice_terminater = 1; % practice_blockの終了

                    else
                        next_interval_index = obj.interval_index; % 打鍵速度維持
                        fprintf("打鍵成功持続時間が10秒未満のtrialが2つ以上あります。速度を変えずに再挑戦します。\n");
                        obj.txt.String = 'Try Again!';
                        pause(2);
                    end

                elseif sum(last_5_success_durations < obj.trial_task_time*0.5) >= 3 % 5trial中 3trial以上で打鍵成功持続時間が10秒間未満でかつそれが初めての周でない場合、速度を下げる
                    fprintf("打鍵成功持続時間が10秒未満のtrialが3つ以上です。速度を1段階下げて再挑戦します。\n")
                    obj.txt.String = 'Speed Down & Try Again!';
                    pause(2);

                    if obj.interval_index ~= 1 % 最小の打鍵速度ではないことを確認
                        next_interval_index = obj.interval_index - 1; % 打鍵速度減少
                    end

                else
                    next_interval_index = obj.interval_index; % 打鍵速度維持
                    fprintf("打鍵成功持続時間が18秒以上のtrialが2つ以下です。速度を変えずに再挑戦します。\n");
                    obj.txt.String = 'Try Again!';
                    pause(2);
                end
            end
        end
    end
end
