classdef KeystrokesJudger

    properties % 保存しておきたい変数を追加しておく[これがobj化する意味]
        task_ev

        current_trial
        tap_interval
        beep_start_time
        trial_task_time
        judge_range_parameters

        beep_times_keys

        window_delimiters
    end


    methods (Access = public)
        % コンストラクタ：クラスからオブジェクトを作る
        function obj = KeystrokesJudger(task_ev)
            obj.task_ev = task_ev;

            obj.current_trial = task_ev.current_trial;
            obj.tap_interval = task_ev.tap_interval;
            obj.beep_start_time = task_ev.Results.beep_start_times(obj.current_trial);
            obj.trial_task_time = task_ev.trial_task_time;
            obj.judge_range_parameters = task_ev.judge_range_parameters;
        end

        % 打鍵判定をする（judge_this_trial配列作成）までの全体
        function [obj, judge_this_trial] = run_keystrokes_judger(obj)
            all_data = obj.task_ev; % このクラスの入力であるオブジェクトtask_evの全体

            % beep音の鳴った時刻の配列データ（キー別）を作成
            obj.beep_times_keys = obj.make_beep_times_keys(obj.beep_start_time, obj.tap_interval, obj.trial_task_time);

            % 打鍵判定の時間窓（打鍵判定区間）の配列の作成
            [obj.window_delimiters, beep_based_required_keystrokes] = obj.make_judge_range();

            task_based_required_keystrokes = all_data.keystrokes;

            % このtrialの打鍵判定を実行
            judge_this_trial = obj.judge_keystrokes(all_data.Results.pressed_times, obj.current_trial, beep_based_required_keystrokes, obj.window_delimiters, task_based_required_keystrokes);
        end
    end

    methods (Access = private)
     % 打鍵判定の時間窓（打鍵判定区間）の配列の作成
        function [window_delimiters, required_keystrokes] = make_judge_range(obj)

            J_R_P = obj.judge_range_parameters; % 略称を設置

            required_keystrokes = numel(obj.beep_times_keys(~isnan(obj.beep_times_keys)));
            num_loops = size(obj.beep_times_keys, 1);

            row_final = obj.beep_times_keys(num_loops, :); % beep_times_keysの最終行目(最後の打鍵ループ目)を取得
            final_key = sum(~isnan(row_final)); % 最後のbeepで打鍵したキーの番号を取得

            acception_window_start = obj.task_ev.Results.window_delimiters.acception_window_start;
            acception_window_end = obj.task_ev.Results.window_delimiters.acception_window_end;
            rejection_window_start = NaN(num_loops, size(obj.beep_times_keys, 2));
            rejection_window_end = NaN(num_loops, size(obj.beep_times_keys, 2));

            % 打鍵判定の時間窓配列の生成
            for loop = 1:num_loops
                for key = 1:4
                    if required_keystrokes < 4*(loop - 1) + key % 全体でrequired_keystrokes回までforループが回るようにする
                        break;
                    end

                    if obj.beep_times_keys(loop, key) - obj.beep_times_keys(1, 1) <= (obj.beep_times_keys(num_loops, final_key) - obj.beep_times_keys(1, 1)) * J_R_P.relaxation_percentage % task全体の打鍵数から見て、最初のJ_R_P.relaxation_percentage倍の打鍵まで
                        tolerance_percentage = J_R_P.tolerance_percentage_1; % task開始直後の打鍵成功許容範囲の割合 少し緩める %%%
                        rejection_percentage = 1 - tolerance_percentage; % 誤った打鍵の検出を行う範囲の割合
                    else
                        tolerance_percentage = J_R_P.tolerance_percentage_2; % 通常の打鍵成功許容範囲の割合
                        rejection_percentage = 1 - tolerance_percentage; % 誤った打鍵の検出を行う範囲の割合
                    end

                    beep_point = obj.beep_times_keys(loop, key); % この打鍵判定区間の中心時刻。ラグのあるblock.display_timesを使わず、beep_timeを基準に決定
                    acception_window_start(obj.current_trial, loop, key) = beep_point - obj.tap_interval * tolerance_percentage; % 成功判定時間窓の開始時刻 %%%
                    acception_window_end(obj.current_trial, loop, key) = beep_point + obj.tap_interval * tolerance_percentage;   % 成功判定時間窓の終了時刻 %%%

                    % correct_key_pressed = any(block.tap_times(num_trials, key, :) >= tap_window_start & block.tap_times(num_trials, key, :) <= tap_window_end);

                    % 他のキーが誤って押されていないか確認する時間窓
                    rejection_window_start(loop, key) = beep_point - obj.tap_interval * rejection_percentage; % 失敗判定時間窓の開始時刻 %%%
                    rejection_window_end(loop, key) = beep_point + obj.tap_interval * rejection_percentage;   % 失敗判定時間窓の終了時刻 %%%
                end
            end

            % 出力を一つの構造体にまとめる
            window_delimiters = struct( ...
                'acception_window_start', acception_window_start, ...
                'acception_window_end', acception_window_end, ...
                'rejection_window_start', rejection_window_start, ...
                'rejection_window_end', rejection_window_end ...
                );
        end
    end


    methods (Static, Access = private)
        % beep音の鳴った時刻の配列データ（キー別）を作成
        function beep_times_keys = make_beep_times_keys(beep_start_time, tap_interval, trial_task_time)

            % beep音が鳴った時刻を計算して格納
            first_beep_time_in_task = beep_start_time + (8 + 1/2) * tap_interval; % 初期値、最初に白数字の1を表示する時刻
            current_time = first_beep_time_in_task:tap_interval:(first_beep_time_in_task + trial_task_time - 0.01); % 時刻データの生成。- 0.01は、trial_task_time秒に重なる最後のビープが鳴ったと仮定しないように補正。
            num_beeps = numel(current_time); % ビープ音が鳴った（本来鳴っているはずの）数
            beep_times(1:num_beeps) = current_time; % ビープ音の提示時刻を示す配列に格納

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

            % beep_times_keysの最終行目（最終loop）に格納された値が全てNaNならば、その行を削除する
            if all(isnan(beep_times_keys(end, :)))
                beep_times_keys(end, :) = [];
            end
        end

        % このtrialの打鍵判定を実行
        function judge = judge_keystrokes(pressed_times, current_trial, beep_based_required_keystrokes, window_delimiters, task_based_required_keystrokes)

            W_D = window_delimiters; % 略称を設置
            num_loops = task_based_required_keystrokes.num_loops;
            num_keys = task_based_required_keystrokes.num_keys;
            task_based_required_keystrokes = task_based_required_keystrokes.num_keystroke_sections;
 
            % 配列の初期設定
            judge = NaN(4*(num_loops - 1) + num_keys, 1); % judge配列の初期化
            correct_key_pressed = zeros(beep_based_required_keystrokes, 1);
            incorrect_key_pressed = zeros(beep_based_required_keystrokes, 1);

            % judge配列の生成
            for loop = 1:num_loops
                for key = 1:4
                    if beep_based_required_keystrokes < 4*(loop - 1) + key
                        break;
                    end                    

                    % 該当キーが押されているか確認
                    if any(pressed_times(current_trial, key, :) >= W_D.acception_window_start(current_trial, loop, key) & pressed_times(current_trial, key, :) <= W_D.acception_window_end(current_trial, loop, key))
                        correct_key_pressed(4*(loop - 1) + key, 1) = key;
                    end

                    % 押すべきでないキーが誤って押されていないか確認
                    for other_key = setdiff(1:4, key) % key以外のキーをチェック
                        if any(pressed_times(current_trial, other_key, :) >= W_D.rejection_window_start(loop, key) & pressed_times(current_trial, other_key, :) <= W_D.rejection_window_end(loop, key))
                            incorrect_key_pressed(4*(loop - 1) + key, 1) = other_key;
                            break;
                        end
                    end

                    if task_based_required_keystrokes >= 4*(loop - 1) + key % task実行時に到達していないかった打鍵判定区間の対応打鍵は、判定しない→NaNが格納されたままになる
                        % 該当キーが押され、誤ったキーが押されていない場合にのみ、judgeに1を格納。そうでなければ0を格納
                        if correct_key_pressed(4*(loop - 1) + key, 1) == key && incorrect_key_pressed(4*(loop - 1) + key, 1) == 0
                            judge(4*(loop - 1) + key, 1) = 1;
                        else
                            judge(4*(loop - 1) + key, 1) = 0;
                        end
                    end
                    % fprintf("%d\n", 4*(loop - 1) + key) % [検証用]
                end
            end
        end

    end
end