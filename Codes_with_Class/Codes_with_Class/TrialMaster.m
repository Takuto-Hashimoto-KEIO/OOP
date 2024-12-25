classdef TrialMaster
    %TRIALMASTER このクラスの概要をここに記述
    %   詳細説明をここに記述
    
    properties
        tap_interval 
    end
    
    methods
        function obj = TrialMaster()
            %TRIALMASTER このクラスのインスタンスを作成
            %   詳細説明をここに記述
        end
        
        function outputArg = prameters_keeper(obj,inputArg)
            %METHOD1 このメソッドの概要をここに記述
            %   詳細説明をここに記述
            outputArg = obj.Property1 + inputArg;
        end

        function run_trial(obj)
            % Pretaskフォルダにパスをつなぐ
            addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\PreTask");

            % 速度変更、Rest、Readyの提示までを一括で行う
            % speed_changer = SpeedChangeToReady(speedchange, current_trial);
            %%% speed_changeをどこに保存する？(objectがたくさんになり、内容が重複して管理しきれない)
            % speed_changer = speed_changer.trialStartToTask(); %%% なぜ()内にspeed_changerは不要なのか？

            % ビープ音の提示開始
            % beep_start_time = GetSecs;
            beep_player = Beep_Player();
            beep_player.play_beep_pattern(settings.BeepPatterns, interval_index);

            % ビープ音の提示開始時刻を保存
            setting.Results.beep_start_times(current_trial) = beep_player.getBeepStartime();

            % 2ループで速度提示（黄色数字）
            rhythm_presenter = RhythmPresenter(0.5, setting.Results.beep_start_times(current_trial)); %% 0.5は要変更
            %%% いちいちsettingから引数を出さず、このスクリプト内で変数を出した方がいい？
            rhythm_presenter.keystrokeSpeedPrompter();
        end


    end
end

