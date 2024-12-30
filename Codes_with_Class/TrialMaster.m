classdef TrialMaster
    %TRIALMASTER このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        settings

        txt

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
            obj.txt = text(0.5, 0.5, num2str(0), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');

            % run_trial内で変更していく値
            obj.speed_changer = 0; % 速度変更を指示する変数　0で維持、1で加速、-1で減速
            obj.consecutive_same_speeds = 1;
            obj.interval_index = settings.IntervalIndexAtStart;
            obj.Results = settings.Results;
        end

        % trialの開始～終了までを一貫して実行
        function obj = run_trial(obj, current_trial)

            cfg = obj.settings; % 文字数削減のため、置換。主に% run_trial内で不変の値を呼び出す際に使用

            obj.tap_interval = cfg.TapIntervalList(obj.interval_index); % 打鍵間隔を更新

            % 現在のtrial数を更新
            obj.current_trial = current_trial;

            % コマンドウィンドウにtrial開始と速度レベルを表示
            fprintf("\n trial%d, 速度レベル = %d \n", obj.current_trial, obj.interval_index)

            % 速度変更、Rest、Readyの提示までを一括で行う
            speed_change = SpeedChangeToReady(obj.speed_changer);
            speed_change = speed_change.trialStartToTask(obj.current_trial, obj.txt);
            obj.speed_changer = speed_change.speed_changer; %A% この行は省略したい→　無理

            % ビープ音の提示開始 & ビープ音の提示開始時刻を保存（即時性担保のため、不可分）
            beep_player = Beep_Player();
            obj.Results.beep_start_times(obj.current_trial) = beep_player.play_beep_pattern(cfg.BeepPatterns, obj.interval_index);

            % 2ループで速度提示（黄色数字）
            rhythm_presenter = RhythmPresenter(obj.tap_interval, obj.Results.beep_start_times(obj.current_trial)); %% 0.5は要変更
            %%% いちいちsettingから引数を出さず、このスクリプト内で変数を出した方がいい？
            rhythm_presenter.run_rhythm_presenter(obj.txt);



            % 打鍵taskの開始から時間経過による終了までを一貫して行う
            task = TaskMaster(obj.Results, cfg.TrialTaskTime, obj.current_trial, obj.tap_interval, cfg.KeyMapping); %A% Results丸ごと渡していいの？ → 仕方ない
            task = task.run_task(obj.txt);
            obj.Results.pressed_times = task.Results.pressed_times; %%%% TaskMasterで保存した値を移し替える手間！

            % 1task終了時にそのtaskの打鍵判定を行う
            task_ev = TaskEvaluator(obj.Results, obj.current_trial, obj.tap_interval, ...
                cfg.judge_range_parameters, task.keystrokes, cfg.TrialTaskTime);
            task_ev = task_ev.run_post_task(obj.txt);

            % 速度変更有無の判定と適用を行う（Main blockだけで実行するため、関数run_post_taskには含めない）
            [obj.speed_changer, obj.consecutive_same_speeds, obj.interval_index] = task_ev.speed_regulator( ...
                obj.speed_changer, obj.consecutive_same_speeds, obj.interval_index, cfg.num_reference_trials, cfg.speed_changer_activate_points);

            % 再生終了操作 [検証用]
            % clear sound % [検証用]
            % cla; % [検証用]

            % 出力する値を整理　　　%A% 二度手間では？　→ 仕方ない
            obj.Results.interval_index_recorder(obj.current_trial) = obj.interval_index;
            obj.Results.tap_intervals(obj.current_trial) = obj.tap_interval;
            obj.Results.beep_times_keys = task_ev.Results.beep_times_keys;
            obj.Results.keystrokes.num_loops(obj.current_trial) = task.keystrokes.num_loops;
            obj.Results.keystrokes.num_keys(obj.current_trial) = task.keystrokes.num_keys;
            obj.Results.keystrokes.num_keystroke_sections(obj.current_trial) = task.keystrokes.num_keystroke_sections;
            obj.Results.window_delimiters.acception_window_start = task_ev.window_delimiters.acception_window_start;
            obj.Results.window_delimiters.acception_window_end = task_ev.window_delimiters.acception_window_end;
            obj.Results.judge = task_ev.Results.judge;
            obj.Results.success_duration = task_ev.Results.success_duration;
        end
    end
end

