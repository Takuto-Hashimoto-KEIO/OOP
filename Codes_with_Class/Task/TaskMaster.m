classdef TaskMaster
    %TASKMASTER このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties

        % 可変の変数
        Results

        % 不変の変数
        trial_task_time
        current_trial
        tap_interval
        key_mapping

        % 可変の変数
        keystrokes
        num_loops
        num_keys
        num_keystroke_sections

        miss_ditected
        success_ditected
        draw_counter
        next_draw_time
        next_section_update_time
        task_terminater
    end

    methods
        function obj = TaskMaster(Results, trial_task_time, current_trial, tap_interval, key_mapping)
            %TASKMASTER このクラスのインスタンスを作成
            %   詳細説明をここに記述
            obj.Results = Results;

            obj.trial_task_time = trial_task_time;
            obj.current_trial = current_trial;
            obj.tap_interval = tap_interval;
            obj.key_mapping = key_mapping;
            
            obj.num_loops = 1;
            obj.num_keys = 1;
            obj.num_keystroke_sections = 1; % 今回のtaskでいくつめの打鍵判定区間かを記録]

            obj.miss_ditected = 0;
            obj.success_ditected = 0;
            obj.draw_counter = 0; % 今回のtaskで何回目の数字提示かを記録
            obj.next_draw_time = obj.Results.beep_start_times(obj.current_trial) + (8 + 1/2)*obj.tap_interval;
            obj.next_section_update_time = obj.Results.beep_start_times(obj.current_trial) + (8 + 1)*obj.tap_interval;
            obj.task_terminater = 0;
        end

        % run_task taskの開始から終了までを一貫して実行
        function obj = run_task(obj)

            % 打鍵測定の準備
            [while_count, draw_stopper] = obj.preparers();

            while(1) % 打鍵記録、リアルタイム打鍵成功判定、数字提示、打鍵判定区間更新をtrial_task_timeが経過するまで繰り返す

                % 打鍵記録
                [obj, keyIsDown, pressed_keys, while_count] = key_recoder(obj, while_count);

                % リアルタイム打鍵成功判定
                if keyIsDown && obj.miss_ditected == 0 % 打鍵があり、かつ、この打鍵判定区間で一度も”Miss”判定が出ていないときのみ、打鍵の成功判定を実行
                    obj = keystroke_realtime_judger(obj, pressed_keys);
                end

                % 時刻判定（数字提示と打鍵判定区間の更新を内包）
                [obj, draw_stopper] = time_keeper(obj, draw_stopper, obj.trial_task_time);
                if obj.task_terminater == 1 % task終了のため、while文を強制終了
                    break;
                end

                WaitSecs(0.001);
            end

            % 打鍵数に関する値を構造体にして保存
            obj.keystrokes = struct( ...
                'num_loops', obj.num_loops, ...
                'num_keys', obj.num_keys, ...
                'num_keystroke_sections', obj.num_keystroke_sections ...
                );

            fprintf('\n');
            fprintf('while_count = %d\n', while_count); % [検証用]
        end
    end

    methods (Access = private)
        % 打鍵記録
        function [obj, keyIsDown, pressed_keys, while_count] = key_recoder(obj, while_count)
            while_count = while_count + 1;
            [keyIsDown, secs, keyCode, ~] = KbCheck(); % 打鍵情報の取得

            if keyIsDown == 0 % 打鍵無しの判定
                obj.Results.pressed_times(obj.current_trial, :, while_count) = 0;
                pressed_keys = NaN;
            else % 打鍵ありの判定
                pressed_keys = find(keyCode(obj.key_mapping) == 1); % JEIFの打鍵の有無を判定
                obj.Results.pressed_times(obj.current_trial, pressed_keys, while_count) = secs; % 打ったキーの列にその時刻を保存
            end
        end

        % リアルタイム打鍵成功判定(とコマンドウィンドウへの表示)
        function obj = keystroke_realtime_judger(obj, pressed_keys)

            % 誤ったキーが押されているかチェック
            key_mapping_index_array = 1:length(obj.key_mapping);
            wrong_keys = setdiff(key_mapping_index_array, obj.num_keys); % 誤ったキー番号を取得
            wrongKey_pressed = any(ismember(pressed_keys, wrong_keys)); % 誤ったキーが押されたか確認

            if wrongKey_pressed % 誤った打鍵があったとき
                if obj.miss_ditected == 0
                    fprintf('Miss');
                    obj.miss_ditected = 1;
                end

            elseif all(pressed_keys == obj.num_keys) && isscalar(pressed_keys) % 正しい打鍵だけをしたとき（ビープ音提示の前後tap_interval÷2秒間で打鍵成功）
                if obj.success_ditected == 0
                    fprintf('Success');
                    obj.success_ditected = 1;
                end
            end
        end

        % 時刻判定（時間経過によるfail判定、task終了判定を内包）
        function [obj, draw_stopper] = time_keeper(obj, draw_stopper, trial_task_time)
            % 時間経過によるtask終了判定
            obj = task_end_judger(obj, trial_task_time);
            if obj.task_terminater == 1 % task終了のため、time_keeperを強制終了
                return;
            end

            if GetSecs >= obj.next_draw_time && draw_stopper == 0 % 最初のビープ音時を基準に、一つ前の数字提示からtap_interval経過していたら、次の数字(現在成功判定中の打鍵に対応)の提示に切り替える
                % 時間経過による数字提示
                draw_stopper = number_presenter(obj);
                obj.draw_counter = obj.draw_counter + 1;
            elseif GetSecs >= obj.next_section_update_time % ビープ音開始時を基準に、一つ前の打鍵受付終了時刻からtap_interval経過していたら、打鍵判定区間を更新
                % 時間経過によるfail判定
                fail_judger(obj);
                % 時間経過による打鍵判定区間更新
                [obj, draw_stopper] = judgment_section_updater(obj);
            end

        end

        % 被験者に打鍵を指示する数字を提示（白色数字）
        function draw_stopper = number_presenter(obj)
            cla;
            text(0.5, 0.5, num2str(obj.num_keys), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色の数字を表示
            drawnow
            draw_stopper = 1; % 次の打鍵判定区間に切り替わるまで描画をロック
        end

        % 時間経過によるfail判定
        function fail_judger(obj)
            if obj.miss_ditected == 0 && obj.success_ditected == 0 % SuccessでもMissでもなかったとき
                fprintf('Fail');
            end
        end

        % 打鍵判定区間の更新
        function  [obj, draw_stopper] = judgment_section_updater(obj)
            % 次の区切りの時刻を作成
            obj.num_keys = obj.num_keys + 1;
            if obj.num_keys == length(obj.key_mapping) + 1
                obj.num_keys = 1;
                obj.num_loops = obj.num_loops + 1; % 打鍵「JEIF」のループ数を更新
            end

            obj.num_keystroke_sections = obj.num_keystroke_sections + 1; % このtrialで何回目の打鍵判定区間かを更新

            % 次の画面提示と打鍵判定区間更新を行う時刻をそれぞれ算出
            obj.next_draw_time = obj.Results.beep_start_times(obj.current_trial) + (8 + obj.num_keystroke_sections - 1/2)*obj.tap_interval;
            obj.next_section_update_time = obj.Results.beep_start_times(obj.current_trial) + (8 + obj.num_keystroke_sections)*obj.tap_interval;

            draw_stopper = 0; % 描画のロックを解除

            % SuccessとMissの判定の有無をリセット
            obj.miss_ditected = 0;
            obj.success_ditected = 0;

            fprintf('\n');
            cla;
        end

        % 時間経過によるtask終了判定を内包
        function obj = task_end_judger(obj, trial_task_time)
            if GetSecs >= obj.Results.beep_start_times(obj.current_trial) + 8*obj.tap_interval + trial_task_time % task開始からtrial_task_time秒間以上経過したらそのtaskを終了(1taskを表すwhile文を抜ける)。打鍵判定区間の終わりのみで判定するため、実際には1taskの時間は最大tap_interval分増える可能性がある
                obj.task_terminater = 1;
            end
        end
    end

    methods (Static, Access = private)
        function [while_count, draw_stopper] = preparers()
            ListenChar(2) % キーボード入力をすべてMATLABのコマンドウィンドウから遮断
            while_count = 0;
            draw_stopper = 0; % 同じ数字描画を繰り返さないための変数、0で描画可能、描画したら1を格納して描画をロック
        end
    end
end

%%%　コードが長すぎる、どうやって分割するか？