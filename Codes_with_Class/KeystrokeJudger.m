classdef KeystrokeJudger

    properties % 保存しておきたい変数を追加しておく[これがobj化する意味]
        beep_times_keys

        tap_window_start
        tap_window_end
        rejection_window_start
        rejection_window_end

        judge
    end


    methods(Access = public)
        % コンストラクタ：クラスからオブジェクトを作る
        function obj = KeystrokeJudger() % 必ず必要な二行
            obj.beep_times_keys = beep_times_keys;

            obj.tap_window_start = tap_window_start;
            obj.tap_window_end = tap_window_end;
            obj.rejection_window_start = rejection_window_start;
            obj.rejection_window_end = rejection_window_end;

            obj.judge = judge;
        end

        %% 打鍵判定の時間窓を決定するまでの全体
        function [tap_window_start, tap_window_end, rejection_window_start, rejection_window_end, required_taps_total] = decide_window(obj, start_beep_time, tap_interval)
            obj.beep_times_keys = obj.make_beep_times_keys(start_beep_time, tap_interval);
            [tap_window_start, tap_window_end, rejection_window_start, rejection_window_end] = obj.make_judge_range(obj.beep_times_keys, tap_interval);
        end % ↑どうして返り値にobj.をつけられないの？
    end


    methods(Static, Access = private)
        %% beep音の鳴った時刻の配列データ（キー別）を作成
        function beep_times_keys = make_beep_times_keys(start_beep_time, tap_interval)
            % ここにbeep_timeを作成するコードを書く

            % 出力配列の準備
            trial_task_time = 20;

            % required_taps_total = 4*(num_loops - 1) + num_keys; % タップ数を記録
            % beep_times = NaN(required_taps_total, 1); % 結果配列をNaNで初期化

            % beep音が鳴った時刻を計算して格納
            t = start_beep_time + 8 * tap_interval; % 初期値、最初に白数字の1を表示する時刻
            current_time = t:tap_interval:(t + trial_task_time); % 時刻の生成
            num_beeps = numel(current_time); % ビープ音が鳴った数
            beep_times(1:num_beeps) = current_time; % ビープ音の提示時刻を示す配列に格納
            % beep_times = beep_times - t; %% 検証用

            % % t + trial_task_time以上の値をNaNに置き換え
            % beep_times(beep_times >= t + trial_task_time) = NaN;

            % 新しい配列 (要素数は、ループ数 × 4) の作成、start_beep_time + 8 * tap_intervalを始点とし、tap_intervalごとにtrial_task_timeを超えるまで加算
            beep_times_keys = NaN(floor(num_beeps/4)+1, 4, 'single'); % 新しい配列、keyごとに次元を分ける


            for mod_index = 0:3 % mod(インデックス, 4) の結果に基づく次元分け
                % 該当インデックスの抽出
                selected_indices = find(mod(1:size(beep_times, 2), 4) == mod_index);
                if mod_index ~= 0
                    beep_times_keys(1:numel(selected_indices), mod_index) = beep_times(selected_indices);
                else
                    beep_times_keys(1:numel(selected_indices), 4) = beep_times(selected_indices);
                end
            end

        end


        %% 打鍵判定の時間窓の決定
        function [tap_window_start, tap_window_end, rejection_window_start, rejection_window_end] = make_judge_range(beep_times_keys, tap_interval)
            % ここに配列tap_win_start, tap_win_endを作るコードを書く

            %% パラメータの設定[後でパラメータのセットに書く]
            keystroke_relaxation_range = 1/4; % 打鍵成功判定を緩和する割合　task全体での要求打鍵数の1/4　%%%
            tolerance_percentage_1 = 0.75; % task開始直後の打鍵成功許容範囲の割合 少し緩める %%%
            tolerance_percentage_2 = 0.75; % 通常の打鍵成功許容範囲の割合

            required_taps_total = numel(beep_times_keys(~isnan(beep_times_keys)));
            num_loops = size(beep_times_keys, 1);

            row_final = beep_times_keys(num_loops, :); % beep_times_keysの最終行目を取得
            num_keys = sum(~isnan(row_final)); % 最後のbeepで打鍵したキーの番号を取得

            tap_window_start = NaN(num_loops, size(beep_times_keys, 2));
            tap_window_end = NaN(num_loops, size(beep_times_keys, 2));
            rejection_window_start = NaN(num_loops, size(beep_times_keys, 2));
            rejection_window_end = NaN(num_loops, size(beep_times_keys, 2));

            %% 打鍵判定の時間窓配列の生成
            for loop = 1:num_loops
                for key = 1:4
                    if required_taps_total < 4*(loop - 1) + key % 全体でrequired_taps_total回までforループが回るようにする
                        break;
                    end

                    if beep_times_keys(loop, key) - beep_times_keys(1, 1) <= (beep_times_keys(num_loops, num_keys) - beep_times_keys(1, 1)) * keystroke_relaxation_range % 打鍵がtrial全体から見て最初の1/4（ほぼ最初の5秒間に相当）
                        tolerance_percentage = tolerance_percentage_1; % task開始直後の打鍵成功許容範囲の割合 少し緩める %%%
                        rejection_percentage = 1 - tolerance_percentage; % 誤った打鍵の検出を行う範囲の割合
                    else
                        tolerance_percentage = tolerance_percentage_2; % 通常の打鍵成功許容範囲の割合
                        rejection_percentage = 1 - tolerance_percentage; % 誤った打鍵の検出を行う範囲の割合
                    end

                    beep_point = beep_times_keys(loop, key); % この打鍵判定区間の中心時刻。ラグのあるblock.display_timesを使わず、beep_timeを基準に決定
                    tap_window_start(loop, key) = beep_point - tap_interval * tolerance_percentage; % 成功判定時間窓の開始時刻 %%%
                    tap_window_end(loop, key) = beep_point + tap_interval * tolerance_percentage;   % 成功判定時間窓の終了時刻 %%%

                    % correct_key_pressed = any(block.tap_times(num_trials, key, :) >= tap_window_start & block.tap_times(num_trials, key, :) <= tap_window_end);

                    % 他のキーが誤って押されていないか確認する時間窓
                    rejection_window_start(loop, key) = beep_point - tap_interval * rejection_percentage; % 失敗判定時間窓の開始時刻 %%%
                    rejection_window_end(loop, key) = beep_point + tap_interval * rejection_percentage;   % 失敗判定時間窓の終了時刻 %%%
                end
            end
        end

        %% 打鍵判定
        function judge = judge_taps(obj, taptimes, required_taps_total)  %%% ここでobjとして引き継ぐには？

            % パラメータの設定
            judge = zeros(4*(num_loops - 1) + num_keys, 1); % judge配列の初期化
            correct_key_pressed = zeros(required_taps_total, 1);
            incorrect_key_pressed = zeros(required_taps_total, 1);


            % judge配列の生成
            for loop = 1:num_loops
                for key = 1:4
                    if required_taps_total < 4*(loop - 1) + key
                        break;
                    end

                    if beep_times_keys(loop, key) - beep_times_keys(1, 1) <= (beep_times_keys(num_loops, num_keys) - beep_times_keys(1, 1)) * keystroke_relaxation_range % 打鍵がtrial全体から見て最初の1/4（ほぼ最初の5秒間に相当）
                        tolerance_percentage = tolerance_percentage_1; % task開始直後の打鍵成功許容範囲の割合 少し緩める %%%
                        rejection_percentage = 1 - tolerance_percentage; % 誤った打鍵の検出を行う範囲の割合
                    else
                        tolerance_percentage = tolerance_percentage_2; % 通常の打鍵成功許容範囲の割合
                        rejection_percentage = 1 - tolerance_percentage; % 誤った打鍵の検出を行う範囲の割合
                    end


                    % 該当キーが押されているか確認
                    if any(block.tap_times(num_trials, key, :) >= tap_window_start & block.tap_times(num_trials, key, :) <= tap_window_end)
                        correct_key_pressed(4*(loop - 1) + key, 1) = key;
                    end

                    % correct_key_pressed = any(block.tap_times(num_trials, key, :) >= tap_window_start & block.tap_times(num_trials, key, :) <= tap_window_end);

                    % 他のキーが誤って押されていないか確認
                    tap_window_start = beep_point - tap_interval * rejection_percentage; % 失敗判定時間窓の開始時刻 %%%
                    tap_window_end = beep_point + tap_interval * rejection_percentage;   % 失敗判定時間窓の終了時刻 %%%

                    % incorrect_key_pressed = false;
                    for other_key = setdiff(1:4, key) % key以外のキーをチェック
                        if any(block.tap_times(num_trials, other_key, :) >= tap_window_start & block.tap_times(num_trials, other_key, :) <= tap_window_end)
                            incorrect_key_pressed(4*(loop - 1) + key, 1) = other_key;
                            break;
                        end
                    end

                    % 該当キーが押され、誤ったキーが押されていない場合、judgeに1を格納
                    if correct_key_pressed(4*(loop - 1) + key, 1) == key && incorrect_key_pressed(4*(loop - 1) + key, 1) == 0
                        if block.display_times(num_trials, loop, key) == 0 % 画面提示されてない数字の対応打鍵は判定しない
                            judge(4*(loop - 1) + key, 1) = NaN;
                        else
                            judge(4*(loop - 1) + key, 1) = 1;
                        end
                    end
                    % fprintf("%d\n", 4*(loop - 1) + key) % [検証用]
                end
            end
        end

    end
end