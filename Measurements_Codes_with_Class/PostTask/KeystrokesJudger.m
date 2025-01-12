classdef KeystrokesJudger

    properties % 保存しておきたい変数を追加しておく[これがobj化する意味]
        task_ev
        block_type

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
        function obj = KeystrokesJudger(task_ev, block_type)
            obj.block_type = block_type;
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
            [obj.window_delimiters, beep_based_required_keystrokes] = obj.make_judge_windows();

            task_based_required_keystrokes = all_data.keystrokes;

            % このtrialの打鍵判定を実行
            judge_this_trial = obj.judge_keystrokes(all_data.Results.pressed_times, ...
                beep_based_required_keystrokes, task_based_required_keystrokes);
        end
    end

    methods (Access = private)
     % 打鍵判定の時間窓（打鍵判定区間）の配列の作成
        function [window_delimiters, required_keystrokes] = make_judge_windows(obj)

            J_R_P = obj.judge_range_parameters; % 略称を設置

            required_keystrokes = numel(obj.beep_times_keys(~isnan(obj.beep_times_keys)));
            num_loops = size(obj.beep_times_keys, 1);

            row_final = obj.beep_times_keys(num_loops, :); % beep_times_keysの最終行目(最後の打鍵ループ目)を取得
            final_key = sum(~isnan(row_final)); % 最後のbeepで打鍵したキーの番号を取得

            window_delimiters = obj.task_ev.Results.window_delimiters;

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
                    
                    beep_point = obj.beep_times_keys(loop, key); % この打鍵判定区間の中心時刻。ラグのある数字提示時刻display_timesを使わず、beep_timeを基準に決定
                    window_delimiters.acception_window_start(obj.current_trial, loop, key) = beep_point - obj.tap_interval * tolerance_percentage; % 成功判定時間窓の開始時刻 %%%
                    window_delimiters.acception_window_end(obj.current_trial, loop, key) = beep_point + obj.tap_interval * tolerance_percentage;   % 成功判定時間窓の終了時刻 %%%
                    
                    % correct_key_pressed = any(block.tap_times(num_trials, key, :) >= tap_window_start & block.tap_times(num_trials, key, :) <= tap_window_end);
                    
                    % 他のキーが誤って押されていないか確認する時間窓
                    window_delimiters.rejection_window_start(loop, key) = beep_point - obj.tap_interval * rejection_percentage; % 失敗判定時間窓の開始時刻 %%%
                    window_delimiters.rejection_window_end(loop, key) = beep_point + obj.tap_interval * rejection_percentage;   % 失敗判定時間窓の終了時刻 %%%
                end
            end
        end
        
        % このtrialの打鍵判定を実行
        function judge = judge_keystrokes(obj, pressed_times, beep_based_required_keystrokes, task_based_required_keystrokes)
            
            W_D = obj.window_delimiters; % 略称を設置
            acception_window_start = W_D.acception_window_start(obj.current_trial, :, :);
            acception_window_end = W_D.acception_window_end(obj.current_trial, :, :);
            rejection_window_start = W_D.rejection_window_start(obj.current_trial, :, :);
            rejection_window_end = W_D.rejection_window_end(obj.current_trial, :, :);
            
            % judgeの時だけ。window_shift_ratesに応じて打鍵判定区間をシフト
            if obj.block_type == 'P'
                if obj.current_trial >= 6
                    num_last_loop  = ceil(obj.current_trial/ 5) - 1; % 前回のループ番号
                    
                    % 前回のループで得たwindow_shift_rateに応じて打鍵判定区間をシフト
                    window_shift = W_D.window_shift_rates(num_last_loop)*(obj.tap_interval/2);
                    fprintf('\nこのtrialでは、打鍵判定区間を%d 秒だけ後ろにずらす\n', window_shift); % [検証用]
                    acception_window_start = acception_window_start + window_shift;
                    acception_window_end = acception_window_end + window_shift;
                    rejection_window_start = rejection_window_start + window_shift;
                    rejection_window_end = rejection_window_end + window_shift;
                end
                
            elseif obj.block_type == 'M'
                % 一定のwindow_shift_rateで打鍵判定区間をシフト
                window_shift = W_D.window_shift_rate*(obj.tap_interval/2);
                acception_window_start = acception_window_start + window_shift;
                acception_window_end = acception_window_end + window_shift;
                rejection_window_start = rejection_window_start + window_shift;
                rejection_window_end = rejection_window_end + window_shift;
            end
            
            num_loops = task_based_required_keystrokes.num_loops;
            num_keys = task_based_required_keystrokes.num_keys;
            task_based_required_keystrokes = task_based_required_keystrokes.num_keystroke_sections;

            % 配列の初期設定
            judge = NaN(4*(num_loops - 1) + num_keys, 1); % judge配列の初期化
            correct_key_pressed = zeros(beep_based_required_keystrokes, 1);
            % incorrect_key_pressed = zeros(beep_based_required_keystrokes, 1); [1/6に岩間先生の指示で消去]
            
            % judge配列の生成
            for loop = 1:num_loops
                for key = 1:4
                    if beep_based_required_keystrokes < 4*(loop - 1) + key
                        break;
                    end
                    
                    % 該当キーが押されているか確認                    
                    % 最小押し下し時刻が受容ウィンドウに収まっているか確認[1/10に岩間先生の指示で変更]
                    if any(pressed_times(obj.current_trial, key, :) >= acception_window_start(1, loop, key) & ...
                            pressed_times(obj.current_trial, key, :) <= acception_window_end(1, loop, key))
                        if any(pressed_times(obj.current_trial, key, :) >= obj.beep_times_keys(loop, key) - obj.tap_interval & ...
                            pressed_times(obj.current_trial, key, :) < acception_window_start(1, loop, key))
                        % ↑フライングして打っていないかを確認
                        else
                            correct_key_pressed(4*(loop - 1) + key, 1) = key;
                        end
                    end
                    
                    % % 押すべきでないキーが誤って押されていないか確認 [1/6に岩間先生の指示で消去]
                    % for other_key = setdiff(1:4, key) % key以外のキーをチェック
                    %     if any(pressed_times(obj.current_trial, other_key, :) >= rejection_window_start(1, loop, key) & ...
                    %             pressed_times(obj.current_trial, other_key, :) <= rejection_window_end(1, loop, key))
                    %         incorrect_key_pressed(4*(loop - 1) + key, 1) = other_key;
                    %         break;
                    %     end
                    % end

                    if task_based_required_keystrokes >= 4*(loop - 1) + key % task実行時に到達していないかった打鍵判定区間の対応打鍵は、判定しない→NaNが格納されたままになる
                        % 該当キーが押され、誤ったキーが押されていない場合にのみ、judgeに1を格納。そうでなければ0を格納
                        if correct_key_pressed(4*(loop - 1) + key, 1) == key % && incorrect_key_pressed(4*(loop - 1) + key, 1) == 0 [1/6に岩間先生の指示で消去]
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


    methods (Static, Access = private)
        % beep音の鳴った時刻の配列データ（キー別）を作成
        function beep_times_keys = make_beep_times_keys(beep_start_time, tap_interval, trial_task_time)

            % beep音が鳴った時刻を計算して格納
            first_beep_time_in_task = beep_start_time + (8 + 1/2) * tap_interval; % 初期値、最初に白数字の1を表示する時刻
            current_time = first_beep_time_in_task:tap_interval:(first_beep_time_in_task + trial_task_time - 0.01); % 時刻データの生成。- 0.01は、trial_task_time秒に重なる最後のビープが鳴ったと仮定しないように補正。
            num_beeps = numel(current_time); % ビープ音が鳴った（本来鳴っているはずの）数
            beep_times(1:num_beeps) = current_time; % ビープ音の提示時刻を示す配列に格納

            % beep_times = beep_times - beep_times(1); % [検証用]

            % 新しい配列 (要素数は、ループ数 × 4) の作成、start_beep_time + 8 * tap_intervalを始点とし、tap_intervalごとにtrial_task_timeを超えるまで加算
            beep_times_keys = NaN(floor(num_beeps/4)+1, 4'); % 新しい配列、keyごとに次元を分ける

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
    end
end