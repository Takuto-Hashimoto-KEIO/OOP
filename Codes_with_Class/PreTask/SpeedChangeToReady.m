classdef SpeedChangeToReady
    %SpeedChangeToReady 速度変更、Rest、Readyの提示までを一括で行う
    %   詳細説明をここに記述

    properties
        speed_changer
        % current_trial
    end

    methods (Access = public)
        function obj = SpeedChangeToReady(speed_changer)
            %SpeedChangeToReady このクラスのインスタンスを作成
            %A% オブジェクトを初期化しない理由＆方法は？ コンストラクトの引数がないことを統一、＆　コンストラクトだけをしても動く
            obj.speed_changer = speed_changer;
            % obj.current_trial = current_trial;
        end

        function obj = trialStartToTask(obj, current_trial)
            % trialの開始からtask開始直前までを一括で行う
            % sendCommand(daq,2); % Rest
            text(0.5, 0.5, sprintf('Trial %d', current_trial), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色のセッション番号を表示
            pause(1);
            cla;

            % [pause_rest_time, obj] = speedChangeNotifier(obj);
            % obj.restNotifier(pause_rest_time);
            % 
            % % sendCommand(daq,3); % Ready
            % obj.readyNotifier()
        end
    end

    methods (Access = private)
        function [pause_rest_time, obj] = speedChangeNotifier(obj)
            pause_rest_time = 7; % 初期値（速度変更がある場合）

            % 速度変更を被験者に通知
            if obj.speed_changer == 1
                text(0.5, 0.5, sprintf('Speed Up'), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色のセッション番号を表示
                pause(2);
                cla;
                obj.speed_changer = 0;

            elseif obj.speed_changer == -1
                text(0.5, 0.5, sprintf('Speed Down'), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色のセッション番号を表示
                pause(2);
                cla;
                obj.speed_changer = 0;
            else
                pause_rest_time = 9; % 速度変更がない場合は変更している
            end
        end
    end

    methods (Static, Access = private) % Staticは静的メソッドを設定、objを入力に必要としない
        function restNotifier(pause_rest_time)
            text(0.5, 0.5, 'Rest', 'Color', 'b', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 青色の"Rest"を表示
            pause(pause_rest_time); % 速度変更の通知と合わせて10秒間待機
            cla;
        end

        function readyNotifier()
            text(0.5, 0.5, 'Ready', 'Color', 'r', 'FontSize', 100,'HorizontalAlignment', 'center'); % 赤色の"Ready"を表示
            pause(2); % 2秒間待機
            cla;
        end
    end
end

