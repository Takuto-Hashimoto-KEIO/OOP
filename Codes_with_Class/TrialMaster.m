classdef TrialMaster
    %TRIALMASTER このクラスの概要をここに記述
    %   詳細説明をここに記述
    
    properties
        current_trial
        speed_changer
        interval_index
        BeepPatterns
        Results

        tap_interval
    end

    methods
        function obj = TrialMaster(settings) %%% ここsettingまるごと入れていいの？
            %TRIALMASTER このクラスのインスタンスを作成
            %   詳細説明をここに記述
            obj.current_trial = 1; % 現在のtrial番号
            obj.speed_changer = 0; % 速度変更を指示する変数　0で維持、1で加速、2で減速
            obj.interval_index = settings.IntervalIndexAtStart;
            obj.BeepPatterns = settings.BeepPatterns;
            obj.Results = settings.Results;

            obj.tap_interval = settings.TapIntervalList(obj.interval_index);
        end

        function obj = run_trial(obj, current_trial) %%% ここで変更したobjを外で保存するには？
            % Pretaskフォルダにパスをつなぐ
            addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\PreTask");

            % 現在のtrial数を更新
            obj.current_trial = current_trial;

            % コマンドウィンドウにtrial開始と速度レベルを表示
            fprintf("\n trial%d, 速度レベル = %d \n", obj.current_trial, obj.interval_index)

            % 速度変更、Rest、Readyの提示までを一括で行う
            speed_change = SpeedChangeToReady(obj.speed_changer);
            %%% speed_changeをどこに保存する？(objectがたくさんになり、内容が重複して管理しきれない)
            speed_change = speed_change.trialStartToTask(obj.current_trial); %%% なぜ()内にspeed_changerは不要なのか？
            obj.speed_changer = speed_change.speed_changer; %%% この行は省略したい

            % ビープ音の提示開始 & ビープ音の提示開始時刻を保存（即時性担保のため、不可分）
            beep_player = Beep_Player();
            beep_start_time = beep_player.play_beep_pattern(obj.BeepPatterns, obj.interval_index);
            obj.Results.beep_start_times(obj.current_trial) = beep_start_time; %% 二度手間

            % 2ループで速度提示（黄色数字）
            rhythm_presenter = RhythmPresenter(obj.tap_interval, obj.Results.beep_start_times(obj.current_trial)); %% 0.5は要変更
            %%% いちいちsettingから引数を出さず、このスクリプト内で変数を出した方がいい？
            rhythm_presenter.keystrokeSpeedPrompter();

            % 再生終了後、ハンドルを閉じる
            clear sound % [検証用]
            cla; % [検証用]

            % 出力する値を整理　%%%　二度手間では？
            obj.Results.interval_index_recorder(obj.current_trial) = obj.interval_index;
            obj.Results.tap_intervals(obj.current_trial) = obj.tap_interval;
        end
    end
end

