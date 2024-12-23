classdef ParameterSettings
    properties
        KeyMapping

        % 1人の実験全体で不変の条件
        TapIntervalList
        NumTrials
        NumLoops
        NumKeys
        TrialTaskTime

        % 打鍵成功判定区間のパラメータ
        keystroke_relaxation_range % 打鍵成功判定を大きく緩和する割合　task全体での要求打鍵数の1/4
        tolerance_percentage_1 % task開始直後の打鍵成功許容範囲の割合 少し緩める
        tolerance_percentage_2 % 通常の打鍵成功許容範囲の割合

        % ブロックごとに代わる条件
        IntervalIndexAtStart

        % 保存用の名前
        ParticipantNumber
        BlockNumber
        BeepPatterns
    end

    methods
        function obj = ParameterSettings(participantNumber, blockNumber, intervalIndexAtStart)
            % 初期化

            % 1人の実験全体で不変の条件
            obj.KeyMapping = [KbName('J'), KbName('E'), KbName('I'), KbName('F')];
            obj.TapIntervalList = [1/2, 1/2.3, 1/2.6, 1/2.9, 1/3.2, 1/3.5, 1/3.9, 1/4.3, 1/4.7, 1/5.2, 1/5.7];
            obj.NumTrials = 20;
            obj.NumLoops = 30;
            obj.NumKeys = 4;
            obj.TrialTaskTime = 20; % 1trialのtask実行時間

            % 打鍵成功判定区間のパラメータ
            obj.keystroke_relaxation_range = 1; % 打鍵成功判定を大きく緩和する割合　task全体での要求打鍵数の1/4
            obj.tolerance_percentage_1 = 0.75; % task開始直後の打鍵成功許容範囲の割合 少し緩める　0.5~1.0まで対応可能
            obj.tolerance_percentage_2 = 0.75; % 通常の打鍵成功許容範囲の割合　0.5~1.0まで対応可能

            % ブロックごとに代わる条件
            obj.IntervalIndexAtStart = intervalIndexAtStart;

            % 保存用の名前
            obj.ParticipantNumber = participantNumber;
            obj.BlockNumber = blockNumber;
            obj.BeepPatterns = obj.generateAllBeepPatterns();
        end

        %% ビープ音のパターン生成
        function beepPatterns = generateAllBeepPatterns(obj)

            frequency = 500; % 周波数
            beepDuration = 0.03; % 長さ（秒）
            sampleRate = 44100; % サンプリングレート

            beepPatterns = cell(1, length(obj.TapIntervalList));
            for idx = 1:length(obj.TapIntervalList)
                interval = obj.TapIntervalList(idx);
                totalDuration = 20 + 8.5 * interval; % 全体の長さ
                tBeep = linspace(0, beepDuration, round(beepDuration * sampleRate));
                beepSignal = sin(2 * pi * frequency * tBeep);
                
                % フェードイン・アウト適用
                fadeDuration = round(0.1 * length(beepSignal));
                fadeIn = linspace(0, 1, fadeDuration);
                fadeOut = linspace(1, 0, fadeDuration);
                beepSignal(1:fadeDuration) = beepSignal(1:fadeDuration) .* fadeIn;
                beepSignal(end-fadeDuration+1:end) = beepSignal(end-fadeDuration+1:end) .* fadeOut;

                % パターン生成
                patternSignal = zeros(1, round((interval / 2) * sampleRate));
                currentTime = interval / 2;
                while currentTime < totalDuration
                    patternSignal = [patternSignal, beepSignal];
                    silenceDuration = interval - beepDuration;
                    if silenceDuration > 0
                        silenceSignal = zeros(1, round(silenceDuration * sampleRate));
                        patternSignal = [patternSignal, silenceSignal];
                    end
                    currentTime = currentTime + interval;
                end
                beepPatterns{idx} = patternSignal;
            end
        end
    end
end
