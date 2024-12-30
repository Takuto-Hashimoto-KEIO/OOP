classdef TaskJudgerPer2Trials
    %TASKJUDGERPER2TRIALS このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        current_trial
        interval_index
        last_two_success_duration

        txt
    end

    methods
        function obj = TaskJudgerPer2Trials(current_trial, interval_index, success_duration)
            %TASKJUDGERPER2TRIAL このクラスのインスタンスを作成
            obj.current_trial = current_trial;
            obj.interval_index = interval_index;
            obj.last_two_success_duration = success_duration(obj.current_trial-1:obj.current_trial);
        end

        % TaskJudgerPer2Trialの全体を一貫して実行
        function screening1_terminater = run_task_judger_per_2trials(obj, txt)
            fprintf("\n速度レベル適合判定\n")

            screening1_terminater = 0; % Screening1の終了判定。0で続行。1で終了

            if obj.interval_index ~= 1 && obj.last_two_success_duration(1) <= 15 && obj.last_two_success_duration(2) <= 15 % 2trial両方で15秒以内に打鍵失敗した場合、速度調節Screening1を一旦終了
                fprintf("Dropped out!\n")
                fprintf('直近2trialの打鍵成功持続時間 = %d, %d\n', block.success_duration(num_trials-1:num_trials));
                txt.String('Screening 1 Completed')
                drawnow;
                pause(2);
                fprintf("tap_interval = %d\n", tap_interval)
                fprintf("interval_index = %d\n", obj.interval_index)
                screening1_terminater = 1;

            elseif obj.interval_index == 1 && obj.last_two_success_duration(1) <= 15 && obj.last_two_success_duration(2) <= 15 % 初めの速度レベルで躓いたらやり直し
                fprintf("Try Again!\n")
                txt.String('Try Again!')
                drawnow;
                pause(1);

            else
                fprintf("Clear!\n")
                txt.String('Speed Up')
                drawnow;
                pause(1);
                obj.interval_index = obj.interval_index + 1; % 一つ上の速度レベルに移行
            end
            fprintf('直近2trialの打鍵成功持続時間 = %d, %d\n', obj.last_two_success_duration);
        end
    end
end
