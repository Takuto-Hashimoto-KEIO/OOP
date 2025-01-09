classdef ExperimentBlock
    properties
        Settings   % ExperimentSettings オブジェクト
        Results    % 結果を格納する構造体
        CurrentTrial % 現在のトライアルインデックス
    end
    
    methods
        function obj = ExperimentBlock(settings) % 必ず必要な表記
            % コンストラクタによる初期化
            obj.Settings = settings;
            obj.Results = struct( ...
                'Judge', zeros(settings.NumTrials, 1), ...
                'TapTimes', zeros(settings.NumTrials, settings.NumKeys, 11000), ...
                'TapInterval', zeros(settings.NumTrials, 1), ...
                'IntervalIndexRecorder', zeros(settings.NumTrials, 1), ...
                'SuccessDuration', zeros(settings.NumTrials, 1), ...
                'BeepStartTime', zeros(settings.NumTrials, 1), ...
                'TapAcceptanceStartTimes', zeros(settings.NumTrials, settings.NumLoops, settings.NumKeys), ...
                'DisplayTimes', zeros(settings.NumTrials, settings.NumLoops, settings.NumKeys) ...
                );
            obj.CurrentTrial = 0;
        end

        %% 全trialの実行
        function start_block(obj)
            % 実験ブロックの開始
            disp('Starting Experiment Block for Participant: ' + string(obj.Settings.ParticipantNumber));

            % トライアルごとに処理
            for trialIdx = 1:obj.Settings.NumTrials
                obj.CurrentTrial = trialIdx;
                disp(['Running Trial ', num2str(trialIdx)]);

                % 各トライアルの処理
                obj.run_trial(trialIdx); %%% ここのobjは何でつくの？
            end

            % 結果の保存
            obj.save_results();
            disp('Experiment Block Completed.');
        end

        %% 各トライアルの実行
        function run_trial(obj, trialIdx)

            % 使う情報の整理

            % 打鍵間隔の初期設定
            tapInterval(trialIdx) = obj.Settings.TapIntervalList(obj.Settings.IntervalIndexAtStart);

            % obj.Results.TapInterval(trialIdx) = tapInterval;

            % % ビープ音の開始時刻を記録[検証用]
            % obj.Results.BeepStartTime(trialIdx) = GetSecs;

            % % 模擬データ生成（実際のタスク処理に置き換え）[検証用]
            % obj.Results.TapTimes(trialIdx, :, :) = rand(obj.Settings.NumKeys, 11000);

            % ビープ音提示開始時刻を保存[検証用]
            % start_beap_time = GetSecs;

            % 打鍵データから打鍵判定区間を決定
            decider = KeystrokeJudger(); % オブジェクトdeciderを作り、クラスを呼び出す

            % 打鍵判定の時間窓を決定するまでの全体
            [tap_window_start, tap_window_end, rejection_window_start, rejection_window_end] = decider.decide_window(start_beap_time, tapInterval(trialIdx)); % クラスの中の関数を使用

            judge = decider.judge_taps(obj.Results.TapTimes, required_taps_total);

            % % 成功持続時間や結果の記録
            % obj.Results.SuccessDuration(trialIdx) = randi([5, 20]); % 模擬値
            % obj.Results.Judge(trialIdx) = randi([0, 1]); % 0: 失敗, 1: 成功
        end

        %% 全ての結果をファイルに保存
        function save_results(obj)
            filename = ['Results_', obj.Settings.ParticipantNumber, obj.Settings.BlockNumber,'.mat'];
            results = obj.Results;
            save(filename, 'results');
            disp(['Results saved to ', filename]);
        end
    end
end

