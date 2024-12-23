classdef TextVisualizer
    %TEXTVISUALIZER このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        speed_change
        num_trials
    end

    methods (Access = public)
        function obj = TextVisualizer(speed_change, num_trials)
            %TEXTVISUALIZER このクラスのインスタンスを作成
            obj.speed_change = speed_change;
            obj.num_trials = num_trials;
        end

        function TrialStartToTask(obj)
            % trialの開始からtask開始直前までを一括で行う
            % sendCommand(daq,2); % Rest
            text(0.5, 0.5, sprintf('Trial %d', obj.num_trials), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色のセッション番号を表示
            pause(1);
            cla;
            [pause_rest_time, ~] = SpeedChangeNotifier(obj); %%%?
            RestNotifier(pause_rest_time); %%%Gptに聞く

            % sendCommand(daq,3); % Ready
            ReadyNotifier()
        end
    end

    methods (Access = private)
        function [pause_rest_time, obj] = SpeedChangeNotifier(obj)
            pause_rest_time = 7; % 初期値（速度変更がある場合）

            % 速度変更を被験者に通知
            if obj.speed_change == 1
                text(0.5, 0.5, sprintf('Speed Up'), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色のセッション番号を表示
                pause(2);
                cla;
                obj.speed_change = 0;

            elseif obj.speed_change == -1
                text(0.5, 0.5, sprintf('Speed Down'), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色のセッション番号を表示
                pause(2);
                cla;
                obj.speed_change = 0;
            else
                pause_rest_time = 9; % 速度変更がない場合は変更している
            end
        end
    end

    methods (Static, Access = private)
        function RestNotifier(pause_rest_time)
            text(0.5, 0.5, 'Rest', 'Color', 'b', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 青色の"Rest"を表示
            pause(pause_rest_time); % 速度変更の通知と合わせて10秒間待機
            cla;
        end

        function ReadyNotifier()
            text(0.5, 0.5, 'Ready', 'Color', 'r', 'FontSize', 100,'HorizontalAlignment', 'center'); % 赤色の"Ready"を表示
            pause(2); % 2秒間待機
            cla;
        end
    end
end

