classdef JudgeWindowShiftRate
    %JUDGEWINDOWSHIFTRATE このクラスの概要をここに記述
    %   詳細説明をここに記述
    
    properties
        % 外部入力
        judge
        pressed_times
        beep_times_keys
        window_delimiters
        current_trial
        tap_interval

        % 内製変数
        num_success_windows
        success_keystrokes
    end
    
    methods
        function obj = JudgeWindowShiftRate()
            %JUDGEWINDOWSHIFTRATE このクラスのインスタンスを作成
        end

        % JudgeWindowShifRateの全機能を一貫して実行
        function [mean_delays_per_5trials, window_shift_rate] = run_judge_window_shift_rate( ...
                obj, judge, pressed_times, beep_times_keys, window_delimiters, last_trial, tap_interval)

            fprintf('\n打鍵判定区間のシフト判定_P\n');

            % 外部入力の格納
            obj.judge = judge;
            obj.pressed_times = pressed_times;
            obj.beep_times_keys = beep_times_keys;
            obj.window_delimiters = window_delimiters;            
            obj.tap_interval = tap_interval;

            obj.num_success_windows = NaN(5,1); % 各trialで成功打鍵数

            mean_delays_per_5trials = obj.calculate_mean_delays(last_trial);
            window_shift_rate = obj.calculate_window_shift_rate(mean_delays_per_5trials);
        end
    end

    methods (Access = private)
        % 成功打鍵のbeep音に対する遅れについて、5trialの平均を算出
        function mean_delays_per_5trials = calculate_mean_delays(obj, last_trial)
            % all_central_press_times = NaN(5,1); % 初期化
            all_press_delays = []; % 初期化
            
            for count_trial = 1:5
                obj.current_trial = (last_trial - 5) + count_trial; % 調べるtrialの番号
                [obj, central_press_times] = obj.calculate_central_press_times(count_trial);
                % all_central_press_times(count_trial) = central_press_times;

                if obj.num_success_windows(count_trial) == 0
                    fprintf('よって、%dtrial目の打鍵遅れ算出処理をスキップします\n', count_trial);
                    continue; % 現在の反復を終了して次の反復に移る
                end

                % 打鍵遅れの1trial平均を算出、trialごとに格納
                press_delays = obj.calculate_press_delays(central_press_times, count_trial);
                all_press_delays = press_delays;
            end

            % 5trialの平均を算出(press_delaysが全てNaNの場合、mean_delays_per_5trialsの値はNaNになる)
            mean_delays_per_5trials = mean(all_press_delays(~isnan(all_press_delays)));
        end

        % 成功打鍵1つの押し下しの中央の時間を算出
        function [obj, central_press_times] = calculate_central_press_times(obj, count_trial)
            % 以下全てtrialごとに実行

            % 現在のtrialにおいて、成功した打鍵（judgeが1）のインデックスを取得
            success_indices = find(obj.judge(obj.current_trial, :) == 1);
            obj.num_success_windows(count_trial) = length(success_indices);
            sum_success = obj.num_success_windows(count_trial); % 長いし頻出なので短縮置換

            if isempty(success_indices) % このtrialでは成功打鍵が一つもない
                fprintf('\nこの周のtrial%dでは成功打鍵が一つもありません！\n', count_trial);
                central_press_times = NaN;
                return; % 関数calculate_central_press_timesを強制終了
            end

            % key番号＆ループ数のペアを算出
            % 新しい配列を格納するための初期化
            obj.success_keystrokes = NaN(sum_success, 2); % 2列(loopとkeyに対応)の配列を用意

            % 商+1と余りを計算し、result配列に格納
            for i = 1:sum_success
                loop = floor(success_indices(i) / 4) + 1; % 商+1
                key = mod(success_indices(i), 4);   % 余り
                if key == 0
                    loop = loop - 1; % 余りが0の場合はloop数は1戻す
                    key = 4; % 余りが0の場合はkey番号は4に置き換える
                end
                obj.success_keystrokes(i, :) = [loop, key]; % 商+1と余りをペアとして格納
            end

            % 新しい配列の初期化
            central_press_times = NaN(sum_success, 3); % 3は。loop×key×時間に対応する
            window_start = NaN(sum_success, 1);
            window_end = NaN(sum_success, 1);            
            
            % 以下、1打鍵区間ごとにfor文で繰り返す
            % success_loop_and_keysを基に成功打鍵区間の時刻データを格納
            for i = 1:sum_success
                loop = obj.success_keystrokes(i, 1); % ループ番号
                key = obj.success_keystrokes(i, 2); % キー番号

                % (key番号＆ループ数のペアから、beep_times_keysを参照してbeep時刻を算出)

                % acception_window_startとacception_window_endから対応する時刻を取得
                window_start(i) = obj.window_delimiters.acception_window_start(obj.current_trial, loop, key);
                window_end(i) = obj.window_delimiters.acception_window_end(obj.current_trial, loop, key);

                % window_startとwindow_endに挟まれたpressed_timesをvalid_timesに取得
                time_data = obj.pressed_times(obj.current_trial, key, :); % 特定のtrialとkeyの時系列データ
                time_data = squeeze(time_data); % 3次元から1次元に変換
                valid_times = time_data(time_data >= window_start(i) & time_data <= window_end(i)); % 範囲内の時刻を抽出

                % 1打鍵区間のpressed_timesの中央値を計算しcentral_press_timesに格納
                if ~isempty(valid_times)
                    central_press_times(i, 1) = loop;
                    central_press_times(i, 2) = key;
                    central_press_times(i, 3) = median(valid_times); % 1打鍵の中央値を格納
                end
            end
        end

        % 1trialでの全打鍵の平均打鍵遅れを算出
        function press_delays = calculate_press_delays(obj, central_press_times, count_trial)
            if ~ isnan(central_press_times)
                press_delays = NaN(obj.num_success_windows(count_trial), 1); % 初期化
                for i = 1:obj.num_success_windows(count_trial)
                    loop = obj.success_keystrokes(i, 1); % ループ番号
                    key = obj.success_keystrokes(i, 2); % キー番号

                    % 1打鍵の中央値とbeep時刻との差分を計算
                    press_delays(i) = central_press_times(i, 3) - obj.beep_times_keys(obj.current_trial, loop, key);
                end
            else
                press_delays = NaN;
            end
        end

        % 次trialでの打鍵判定区間のずらし幅を算出
        function window_shift_rate = calculate_window_shift_rate(obj, mean_delays_per_5trials)
            if ~ isnan(mean_delays_per_5trials)
                window_shift_rate = mean_delays_per_5trials/(obj.tap_interval/2); % [要検討]「打鍵区間の半分の長さ」に比した「平均打鍵遅れ」で算出
            else
                window_shift_rate = 0;
                fprintf('\nWarning!:直近5trialの全ての打鍵に失敗しています！\n')
            end
            fprintf('\n次trial以降、打鍵判定区間を後ろに%dの割合でずらす\n', window_shift_rate);
        end
    end
end