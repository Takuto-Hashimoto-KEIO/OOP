classdef TrialMaster
    %TRIALMASTER このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        settings
        BeepPatterns

        current_trial
        speed_changer
        interval_index
        tap_interval
        Results

        trial_task_time
        KeyMapping
    end

    methods
        function obj = TrialMaster(settings) %A% ここsettingまるごと入れていい？　→　OK
            %TRIALMASTER このクラスのインスタンスを作成
            %   詳細説明をここに記述
            obj.settings = settings;

            % run_trial内で変更していく値
            obj.speed_changer = 0; % 速度変更を指示する変数　0で維持、1で加速、2で減速
            obj.interval_index = settings.IntervalIndexAtStart;
            obj.tap_interval = settings.TapIntervalList(obj.interval_index);
            obj.Results = settings.Results;
        end

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

            task = TaskMaster(obj.Results, obj.current_trial, obj.tap_interval, cfg.KeyMapping); %A% Results丸ごと渡していいの？ → 仕方ない
            task = task.beginning_to_end_of_task(cfg.TrialTaskTime);
            obj.Results.pressed_times = task.Results.pressed_times; %%%% TaskMasterで保存した値を移し替える手間！

            % 再生終了操作
            clear sound % [検証用]
            cla; % [検証用]



            % % データの準備
            % pressed_times = task.Results.pressed_times; % 配列 (20×4×11000)
            % a = pressed_times(pressed_times ~= 0);
            % 
            % % 0を白、値がある場所を黒に変換
            % binary_data = pressed_times > 0; % 0以外の要素を1、0の要素を0にする
            % 
            % % 可視化のための行列を展開 (20×(4×11000)に変換)
            % visual_data = reshape(permute(binary_data, [1, 3, 2]), 20, []);
            % 
            % % 図の描画
            % figure;
            % imagesc(~visual_data); % 白黒反転（0:白、1:黒）
            % colormap(gray); % グレースケールのカラーマップ
            % colorbar; % カラーバーを表示
            % xlabel('Columns (4×11000)'); % 列方向のラベル
            % ylabel('Rows (Trials)'); % 行方向のラベル
            % title('Pressed Times Visualization'); % タイトルの追加



            % 出力する値を整理　　　%A% 二度手間では？　→ 仕方ない
            obj.Results.interval_index_recorder(obj.current_trial) = obj.interval_index;
            obj.Results.tap_intervals(obj.current_trial) = obj.tap_interval;
        end
    end
end

