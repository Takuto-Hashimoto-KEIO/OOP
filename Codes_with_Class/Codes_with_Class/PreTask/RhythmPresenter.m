classdef RhythmPresenter
    %RhythmPresenter このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        tap_interval
        first_beep_time
    end

    methods (Access = public)
        function obj = RhythmPresenter(tap_interval, beep_start_time)
            %RhythmPresenter このクラスのインスタンスを作成
            obj.tap_interval = tap_interval;
            obj.first_beep_time = beep_start_time + tap_interval/2; % 音源が1/2打鍵間隔分の空白を最初に持つため。それに合わせる
        end

        function keystrokeSpeedPrompter(obj)
            %keystrokeSpeedPrompter 2ループで速度提示（黄色数字）
            count8 = 0;
            for loops = 1:2  % 2ループで速度提示
                for keys = 1:4
                    while(1)
                        if GetSecs >= obj.first_beep_time + count8*obj.tap_interval % 最初のビープ音時を基準に、一つ前の数字提示からtap_interval経過していたら、次の数字提示に切り替える
                            cla;
                            text(0.5, 0.5, num2str(keys), 'Color', 'y', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 黄色の数字を表示
                            drawnow
                            count8 = count8 + 1;
                            break; % 数字を提示したらfor文を回す
                        end
                    end
                end
            end
        end
    end
end

