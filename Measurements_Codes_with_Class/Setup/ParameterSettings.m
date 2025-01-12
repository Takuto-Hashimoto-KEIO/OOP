classdef ParameterSettings
    properties
        KeyMapping
        block_type

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
        
        % ビープ音源
        BeepPatterns
        
        % 保存するデータ（構造体）
        Results
    end
    
    methods
        % コンストラクタによる初期化
        function obj = ParameterSettings(participantNumber, blockNumber, block_type, intervalIndexAtStart)
            
            obj.block_type = block_type;
            
            % 1人の実験全体で不変の条件
            obj.KeyMapping = [KbName('J'), KbName('E'), KbName('I'), KbName('F')]; %　各キーに対応するキースキャンコード（keyCode：番号）を保存
            % 旧リスト→obj.TapIntervalList = [1/2, 1/2.3, 1/2.6, 1/2.9, 1/3.2, 1/3.5, 1/3.9, 1/4.3, 1/4.7, 1/5.2, 1/5.7];
            obj.TapIntervalList = [1/2, 1/2.2, 1/2.4, 1/2.6, 1/2.85, 1/3.1, 1/3.4, 1/3.7, 1/4.0, 1/4.3, 1/4.65, 1/4.9];
            % 検討中の新リスト→ [1/2, 1/2.2, 1/2.4, 1/2.6, 1/2.85, 1/3.1, 1/3.4, 1/3.7, 1/4.0, 1/4.3, 1/4.3];
            
            
            if block_type == 'P'
                obj.NumTrials = 25; % 最大のtrial数（5×5）
            elseif block_type == 'S1'
                obj.NumTrials = 24;
            elseif block_type == 'S2'
                obj.NumTrials = 9;
            else
                obj.NumTrials = 20;
            end
            obj.NumLoops = 30;
            obj.NumKeys = 4;
            obj.TrialTaskTime = 20; % 1trialのtask実行時間

            % 打鍵成功判定区間のパラメータ
            obj.relaxation_percentage = 1; % 打鍵成功判定を大きく緩和する範囲の割合　task全体での要求打鍵数に対する割合で記述
            obj.tolerance_percentage_1 = 0.75; % task開始直後の打鍵成功許容範囲の割合 少し緩める　0.5~1.0まで対応可能
            obj.tolerance_percentage_2 = 0.75; % 通常の打鍵成功許容範囲の割合　0.5~1.0まで対応可能
            obj.judge_range_parameters = struct( ...
                'relaxation_percentage', obj.relaxation_percentage, ...
                'tolerance_percentage_1', obj.tolerance_percentage_1, ...
                'tolerance_percentage_2', obj.tolerance_percentage_2 ...
                );

            % 速度変更に関するパラメータ
            obj.num_reference_trials = 3; % trial間の速度変更を決める際（クラスTaskEvaluator内の関数speed_regulator）、直近何trialの打鍵成功持続時間を参照するか　[要検討] %%%
            obj.speed_changer_activate_points = 5; % trial間の速度変更を決める際（クラスTaskEvaluator内の関数speed_regulator）、直近何trialで同じ打鍵速度が続いたら速度変更を可能にするか　[要検討] %%%

            % ブロックごとに代わる条件
            obj.IntervalIndexAtStart = intervalIndexAtStart;

            % 保存用の名前
            obj.ParticipantNumber = participantNumber;
            obj.BlockNumber = blockNumber;

            % ビープ音源の作成
            obj.BeepPatterns = obj.generateAllBeepPatterns();

            % 保存するデータ（構造体）の定義
            keystrokes = struct( ...
                'num_loops', NaN(obj.NumTrials, 1), ...
                'num_keys', NaN(obj.NumTrials, 1), ...
                'num_keystroke_sections', NaN(obj.NumTrials, 1) ...
                );
            window_delimiters = struct( ...
                'acception_window_start', NaN(obj.NumTrials, obj.NumLoops, obj.NumKeys), ...
                'acception_window_end', NaN(obj.NumTrials, obj.NumLoops, obj.NumKeys), ...
                'rejection_window_start', NaN(obj.NumTrials, obj.NumLoops, obj.NumKeys), ...
                'rejection_window_end', NaN(obj.NumTrials, obj.NumLoops, obj.NumKeys) ...
                );
            if block_type == 'P'
                window_delimiters.window_shift_rates = NaN(obj.NumTrials/5, 1); % 練習trialのみ、打鍵判定区間のシフトレートを追加            
            elseif block_type == 'M'
                window_shift_rate = input('Input "mean_window_shift_rates" in practice block->');
                
                if abs(window_shift_rate) > 0.2  % 入力の絶対値は最大でも0.2
                    error("Incorrect window_shift_rate." + ...
                        " Enter a value that is less than or equal to 0.2 in absolute value");
                else
                    window_delimiters.window_shift_rate = window_shift_rate;
                end
            end

            obj.Results = struct( ...
                'tap_interval_list', obj.TapIntervalList, ...
                'interval_index_recorder', NaN(obj.NumTrials, 1), ...
                'tap_intervals', NaN(obj.NumTrials, 1), ...
                'beep_start_times', NaN(obj.NumTrials, 1), ...
                'beep_times_keys', NaN(obj.NumTrials, obj.NumLoops, obj.NumKeys), ...
                'tap_acceptance_start_times', NaN(obj.NumTrials, obj.NumLoops, obj.NumKeys), ...
                'display_times', NaN(obj.NumTrials, obj.NumLoops, obj.NumKeys), ...
                'pressed_times', NaN(obj.NumTrials, obj.NumKeys, 18000), ...
                'keystrokes', keystrokes, ...
                'window_delimiters', window_delimiters, ...
                'judge', NaN(obj.NumTrials, obj.NumLoops * obj.NumKeys), ...
                'success_duration', NaN(obj.NumTrials, 1) ...
                );

            if block_type == 'P'
                obj.Results.P_mean_delays_per_5trials = NaN(obj.NumTrials/5, 1);
            end

            %% National Insruments Data Acquisition (by S.Iwama.)[要改良]
            % DevID = 'Dev2'; % Please check
            % daq = DAQclass(DevID);
            % daq.init_output()
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
