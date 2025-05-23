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
        relaxation_percentage % 打鍵成功判定を大きく緩和する範囲の、task全体での要求打鍵数に占める割合
        tolerance_percentage_1 % task開始直後の打鍵成功許容範囲の割合 少し緩める
        tolerance_percentage_2 % 通常の打鍵成功許容範囲の割合
        judge_range_parameters % 上記3つのパラメータをまとめてこの構造体に格納

        % 速度変更に関するパラメータ
        num_reference_trials
        speed_changer_activate_points

        % ブロックごとに代わる条件
        IntervalIndexAtStart

        % 保存用の名前
        ParticipantNumber
        BlockNumber
        BeepPatterns

        % 保存するデータ（構造体）
        Results
    end

    methods
        function obj = ParameterSettings(participantNumber, blockNumber, intervalIndexAtStart)
            % 初期化

            % 1人の実験全体で不変の条件
            obj.KeyMapping = [KbName('J'), KbName('E'), KbName('I'), KbName('F')]; %　各キーに対応するキースキャンコード（keyCode：番号）を保存
            obj.TapIntervalList = [1/2, 1/2.3, 1/2.6, 1/2.9, 1/3.2, 1/3.5, 1/3.9, 1/4.3, 1/4.7, 1/5.2, 1/5.7];
            obj.NumTrials = 20;
            obj.NumLoops = 30;
            obj.NumKeys = 4;
            obj.TrialTaskTime = 20; % 1trialのtask実行時間

            % 打鍵成功判定区間のパラメータ
            obj.relaxation_percentage = 1; % 打鍵成功判定を大きく緩和する範囲の割合　task全体での要求打鍵数に対する割合で記述
            obj.tolerance_percentage_1 = 0.5; % task開始直後の打鍵成功許容範囲の割合 少し緩める　0.5~1.0まで対応可能
            obj.tolerance_percentage_2 = 0.5; % 通常の打鍵成功許容範囲の割合　0.5~1.0まで対応可能
            obj.judge_range_parameters = struct( ...
                'relaxation_percentage', [obj.relaxation_percentage], ...
                'tolerance_percentage_1', [obj.tolerance_percentage_1], ...
                'tolerance_percentage_2', [obj.tolerance_percentage_2] ...
                );

            % 速度変更に関するパラメータ
            obj.num_reference_trials = 3; % trial間の速度変更を決める際（クラスTaskEvaluator内の関数speed_regulator）、直近何trialの打鍵成功持続時間を参照するか　[要検討] %%%
            obj.speed_changer_activate_points = 5; % trial間の速度変更を決める際（クラスTaskEvaluator内の関数speed_regulator）、直近何trialで同じ打鍵速度が続いたら速度変更を可能にするか　[要検討] %%%

            % ブロックごとに代わる条件
            obj.IntervalIndexAtStart = intervalIndexAtStart;

            % 保存用の名前
            obj.ParticipantNumber = participantNumber;
            obj.BlockNumber = blockNumber;
            obj.BeepPatterns = obj.generateAllBeepPatterns();

            % 保存するデータ（構造体）
            obj.Results = struct( ...
                'interval_index_recorder', zeros(obj.NumTrials, 1), ...
                'tap_intervals', zeros(obj.NumTrials, 1), ...
                'beep_start_times', zeros(obj.NumTrials, 1), ...
                'tap_acceptance_start_times', zeros(obj.NumTrials, obj.NumLoops, obj.NumKeys), ...
                'display_times', zeros(obj.NumTrials, obj.NumLoops, obj.NumKeys), ...
                'pressed_times', zeros(obj.NumTrials, obj.NumKeys, 18000), ...
                'judge', NaN(obj.NumTrials, obj.NumLoops * obj.NumKeys), ...
                'success_duration', NaN(obj.NumTrials, 1) ...
                );
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
