classdef TapDataEditor
    % 編集が必要なデータ（result.edited）の処理、格納

    properties
        raw_dataset
        cond
        result
    end

    methods(Access=public)
        function obj = TapDataEditor()
        end
    end

    methods
        % このクラスのすべての処理を一貫して実行
        function result = edit_data(obj, cfg, result)
            obj = obj.create_array(cfg, result);
            obj = edit_beep_times_keys(obj);
            obj = edit_tap_judge_range(obj);
            obj = edit_press_times(obj);

            % 出力の整理
            result = obj.result;
        end

        % インスタンスの整理
        function obj = create_array(obj, cfg, result)
            obj.raw_dataset = cfg.raw_dataset;
            obj.cond = cfg.cond;
            obj.result = result;
        end

        % beep_times_keysを処理
        function obj = edit_beep_times_keys(obj)
            obj.result.edited.beep_times_keys = obj.raw_dataset.block.beep_times_keys;
            obj.result.edited.first_beep_times = squeeze(obj.result.edited.beep_times_keys(:,1,1)); % 各trialの最初のビープ時刻を取得
            
            % 新しい配列beep_times_keysを初期化（元のbeep_times_keysと同じサイズ）
            beep_times_keys = obj.result.edited.beep_times_keys; 

            % NaN以外の要素について、各trialの最初のビープ時刻を0として補正
            for trial_idx = 1:size(beep_times_keys, 1)
                for loop_idx = 1:size(beep_times_keys, 2)
                    for key_idx = 1:size(beep_times_keys, 3)
                        if ~isnan(beep_times_keys(trial_idx, loop_idx, key_idx))
                            beep_times_keys(trial_idx, loop_idx, key_idx) = beep_times_keys(trial_idx, loop_idx, key_idx) - obj.result.edited.first_beep_times(trial_idx);
                        end
                    end
                end
            end

            % 2,3次元を入れ替え、trial×鍵×回数の形にする（pressed_timesと同じ形式にそろえる）
            beep_times_keys = permute(beep_times_keys, [1,3,2]);

            % 出力を整理
            obj.result.edited.beep_times_keys = beep_times_keys;
        end

        % tap_judge_rangeを処理
        function obj = edit_tap_judge_range(obj)

            % 処理に必要なデータの整理
            window_delimiters = obj.raw_dataset.block.window_delimiters;
            window_start = window_delimiters.acception_window_start;
            window_end = window_delimiters.acception_window_end;

            % 各trialの最初のビープ時刻を0として補正
           
            % 打鍵間隔の10%のシフトを加える処理
            for trial_idx = 1:obj.cond.total_trials
                for loop_idx = 1:size(window_start, 2)
                    for key_idx = 1:size(window_start, 3)

                        % NaNが格納されている要素では処理を行わない
                        if ~isnan(window_start(trial_idx, loop_idx, key_idx))

                            window_shift = window_delimiters.window_shift_rate * obj.result.raw.tap_speed.tap_intervals(trial_idx)/2;

                            % ビープ音の提示時刻を中心に決定した打鍵受付区間 これらをtask開始時のビープ音の時刻を0として補正
                            window_start(trial_idx, loop_idx, key_idx) = window_start(trial_idx, loop_idx, key_idx) - obj.result.edited.first_beep_times(trial_idx);
                            window_end(trial_idx, loop_idx, key_idx) = window_end(trial_idx, loop_idx, key_idx) - obj.result.edited.first_beep_times(trial_idx);

                            % さらに打鍵判定区間を最大で区間の10%シフト
                            window_start(trial_idx, loop_idx, key_idx) = window_start(trial_idx, loop_idx, key_idx) + window_shift;
                            window_end(trial_idx, loop_idx, key_idx) = window_end(trial_idx, loop_idx, key_idx) + window_shift;
                        end

                    end
                end
            end

            % 出力を整理
            obj.result.edited.acception_window_start = window_start;
            obj.result.edited.acception_window_end = window_end;
        end

        % edit_press_timesを処理
        function obj = edit_press_times(obj)

            pressed_times = obj.raw_dataset.block.pressed_times;
            pressed_times(pressed_times == 0) = NaN; % ちょうど0の要素を削除
            corrected_pressed_times = NaN(obj.cond.total_trials, size(pressed_times, 2), 2000); % 補正後のキー押し下し時刻の初期化

            % NaN以外の要素について、各trialの最初のビープ時刻を0として補正
            for trial_idx = 1:size(pressed_times, 1)
                for key_idx = 1:size(pressed_times, 2)
                    pressed_times_key = squeeze(pressed_times(trial_idx, key_idx, :));
                    pressed_times_key = pressed_times_key(pressed_times_key > 0); % 0未満は無視 (測定系で打鍵なしのとき0を格納してしまっているため0の時は処理の対象外)

                    % task開始時のビープ音の時刻を基準に時刻を補正
                    corrected_pressed_times(trial_idx, key_idx, 1:numel(pressed_times_key)) = pressed_times_key - obj.result.edited.first_beep_times(trial_idx);
                end
            end

            a = numel(find(corrected_pressed_times == 0)); % 検証用
            corrected_pressed_times(corrected_pressed_times == 0) = NaN; % 記録されているtask最初のビープ音の時刻と一致した押下時刻(原因不明)を除去

            % 出力を整理
            obj.result.edited.pressed_times = corrected_pressed_times;
        end
    end
end

