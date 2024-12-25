classdef Beep_Player
    %BEEP_PLAYER ビープ音の再生と再生時刻の取得
    %   詳細説明をここに記述

    properties
        all_patterns
        interval_index
        beep_start_time
        %%% オブジェクトに入れないのに作る意味は何？
    end

    methods (Access = public)
        function obj = Beep_Player()
            %BEEP_PLAYER このクラスのインスタンスを作成
        end
    end

    methods (Static, Access = public)
        function play_beep_pattern(all_patterns, interval_index)
            sampleRate = 44100; % サンプリングレート（Hz）
            pattern_signal = all_patterns{interval_index}; % 指定されたインデックスのパターンを取得
            sound(pattern_signal, sampleRate);
        end

        function beep_start_time = getBeepStartime()
            beep_start_time = GetSecs;
        end
    end
end

