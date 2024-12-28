classdef TrialMaster
    %TRIALMASTER このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        settings
        BeepPatterns

        current_trial
        speed_changer
        consecutive_same_speeds
        interval_index
        tap_interval
        Results
    end

    methods
        function obj = TrialMaster(settings) %A% ここsettingまるごと入れていい？　→　OK
            %TRIALMASTER このクラスのインスタンスを作成
            %   詳細説明をここに記述
            obj.settings = settings;

            % run_trial内で変更していく値
            obj.speed_changer = 0; % 速度変更を指示する変数　0で維持、1で加速、-1で減速
            obj.consecutive_same_speeds = 1;
            obj.interval_index = settings.IntervalIndexAtStart;
            obj.tap_interval = settings.TapIntervalList(obj.interval_index);
            obj.Results = settings.Results;
        end

        % trialの開始～終了までを一貫して実行
        function obj = run_trial(obj, current_trial) %%% ここで変更したobjを外で保存するには？

            cfg = obj.settings; % 文字数削減のため、置換。主に% run_trial内で不変の値を呼び出す際に使用

            % Pretaskフォルダにパスをつなぐ
            addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\PreTask");

            % 現在のtrial数を更新
            obj.current_trial = current_trial;

            % コマンドウィンドウにtrial開始と速度レベルを表示
            fprintf("\n trial%d, 速度レベル = %d \n", obj.current_trial, obj.interval_index)

            % 速度変更、Rest、Readyの提示までを一括で行う
            speed_change = SpeedChangeToReady(obj.speed_changer);
            speed_change = speed_change.trialStartToTask(obj.current_trial);
            obj.speed_changer = speed_change.speed_changer; %A% この行は省略したい→　無理

            % ビープ音の提示開始 & ビープ音の提示開始時刻を保存（即時性担保のため、不可分）
            beep_player = Beep_Player();
            obj.Results.beep_start_times(obj.current_trial) = beep_player.play_beep_pattern(cfg.BeepPatterns, obj.interval_index);

            % 2ループで速度提示（黄色数字）
            rhythm_presenter = RhythmPresenter(obj.tap_interval, obj.Results.beep_start_times(obj.current_trial)); %% 0.5は要変更
            %%% いちいちsettingから引数を出さず、このスクリプト内で変数を出した方がいい？
            rhythm_presenter.keystrokeSpeedPrompter();


            % Taskフォルダにパスをつなぐ
            addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\Task");

            % 打鍵taskの開始から時間経過による終了までを一貫して行う
            task = TaskMaster(obj.Results, cfg.TrialTaskTime, obj.current_trial, obj.tap_interval, cfg.KeyMapping); %A% Results丸ごと渡していいの？ → 仕方ない
            task = task.run_task();
            obj.Results.pressed_times = task.Results.pressed_times; %%%% TaskMasterで保存した値を移し替える手間！

            
            % PostTaskフォルダにパスをつなぐ
            addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\PostTask");

            % 1task終了時にそのtaskの打鍵判定を行う
            task_ev = TaskEvaluator(obj.Results, obj.current_trial, obj.tap_interval, cfg.judge_range_parameters, task.keystrokes, cfg.TrialTaskTime);
            task_ev = task_ev.run_post_task();

            % 速度変更有無の判定と適用を行う（Main blockだけで実行するため、関数run_post_taskには含めない）
            [obj.speed_changer, obj.consecutive_same_speeds, obj.interval_index] = task_ev.speed_regulator(obj.speed_changer, obj.consecutive_same_speeds, obj.interval_index, cfg.num_reference_trials, cfg.speed_changer_activate_points);

            % 再生終了操作 [検証用]
            % clear sound % [検証用]
            % cla; % [検証用]

            % 出力する値を整理　　　%A% 二度手間では？　→ 仕方ない
            obj.Results.interval_index_recorder(obj.current_trial) = obj.interval_index;
            obj.Results.tap_intervals(obj.current_trial) = obj.tap_interval;
            obj.Results.judge = task_ev.Results.judge;
            obj.Results.success_duration = task_ev.Results.success_duration;
        end
    end
end

