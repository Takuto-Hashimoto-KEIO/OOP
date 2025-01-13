classdef SpeedChangeToReady
    %SpeedChangeToReady 速度変更、Rest、Readyの提示までを一括で行う
    %   詳細説明をここに記述

    properties
        speed_changer
        % current_trial
        txt
    end

    methods (Access = public)
        function obj = SpeedChangeToReady(speed_changer)
            %SpeedChangeToReady このクラスのインスタンスを作成
            %A% オブジェクトを初期化しない理由＆方法は？ → コンストラクトの引数がないことを統一、＆　コンストラクトだけをしても動く
            obj.speed_changer = speed_changer;
            % obj.current_trial = current_trial;
        end

        function obj = trialStartToTask(obj, current_trial, txt)
            % trialの開始からtask開始直前までを一括で行う
            obj.txt = txt;

            obj = speedChangeNotifier(obj, current_trial);

            % obj.restNotifier(txt);
            % 
            % obj.readyNotifier(txt)
        end
    end

    methods (Access = private)
        function obj = speedChangeNotifier(obj, current_trial)
            % pause_rest_time = 7; % "Rest"を表示する時間の初期値（速度変更がある場合）

            % 速度変更を被験者に通知
            if obj.speed_changer == 1
                speed_change = 'Speed Up';

            elseif obj.speed_changer == -1
                speed_change = 'Speed Down';
            else
                speed_change = [];
                % pause_rest_time = 9; % 速度変更がない場合は、"Rest"を表示する時間を変更している
            end
            obj.txt.String = sprintf('Trial %d\n%d', current_trial, speed_change);
            drawnow;
            pause(1);
        end
    end

    methods (Static, Access = private) % Staticは静的メソッドを設定、objを入力に必要としない
        function restNotifier(txt)
            txt.Color = 'b';
            txt.String = 'Rest';
            drawnow; % 青色の"Rest"を表示
            % global DaqInstance;
            % sendCommand(DaqInstance,2); % Rest
            pause(10); % 速度変更の通知を含めず10秒間待機
        end

        function readyNotifier(txt)
            txt.Color = 'r';
            txt.String = 'Ready';
            drawnow; % 赤色の"Ready"を表示
            % global DaqInstance;
            % sendCommand(DaqInstance,3); % Ready
            pause(2); % 2秒間待機
        end
    end
end

