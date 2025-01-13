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
        function beep_start_time = play_beep_pattern(all_patterns, interval_index)
            sampleRate = 44100; % サンプリングレート（Hz）
            pattern_signal = all_patterns{interval_index}; % 指定されたインデックスのパターンを取得

            sound(pattern_signal, sampleRate);

            beep_start_time = GetSecs;
            % global DaqInstance;
            % sendCommand(DaqInstance,4); % pre-task提示開始時
        end
    end
end

% [検証用]
% a = GetSecs;

% b = GetSecs - a;
% fprintf("差＝%d \n", b); % 3.581890e-02 秒の遅れ