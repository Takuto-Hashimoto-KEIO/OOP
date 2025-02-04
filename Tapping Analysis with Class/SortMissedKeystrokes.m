classdef SortMissedKeystrokes
    %SORTMISSEDKEYSTROKES このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        % もともと読み込むファイルに存在するプロパティ
        participant_name

        num_block

        num_trials
        num_keys
        tap_intervals

        beep_times_keys
        keystrokes
        pressed_times
        window_delimiters
        judge
        tap_interval_list

        % このクラス独自で設定するプロパティ
        block_speed_level
        mode_speed_level
        num_target_trials
        
        corrected_pressed_times
        acceptance_start
        acceptance_end
    end

    methods
        function obj = SortMissedKeystrokes()
            %SORTMISSEDKEYSTROKES このクラスのインスタンスを作成

        end

        % SortMissedKeystrokesの全体を一貫して実行
        function run_sort_missed_keystrokes(obj, folder_path)
            % フォルダ内の.matファイルを取得
            file_list = dir(fullfile(folder_path, 'Block_Result_*.mat'));

            % "blockの種類" が "M" のファイルのみを選択
            filtered_files = [];
            for i = 1:length(file_list)
                file_name = file_list(i).name;
                % 正規表現で "blockの種類" を抽出
                match = regexp(file_name, 'Block_Result_.*_(.)_block\d+_\d+', 'tokens');
                if ~isempty(match)
                    block_type = match{1}{1}; % "blockの種類" を取得
                    if strcmp(block_type, 'M') % 条件に合うか判定
                        filtered_files = [filtered_files; file_list(i)];
                    end
                end
            end

            obj.block_speed_level = NaN(length(filtered_files),20);

            % ファイルごとに処理を実行
            for file_idx = 1:length(filtered_files)
                obj = load_data(obj, filtered_files, file_idx);
                % obj = calculate_corrected_pressed_times(obj);
                % obj = calculate_acceptance_window(obj);
            end

            obj = load_target_data(obj);
            draw_plot(obj); % plotは別のクラスで行う予定
        end
    end

    methods (Access = private)
        % データのロードと格納
        function obj = load_data(obj, file_list, file_idx)
            % ファイルのフルパスを取得
            file_name = file_list(file_idx).name;
            full_file_path = fullfile(file_list(file_idx).folder, file_name);

            % ファイル名を表示（デバッグ用）
            fprintf('Processing file: %s\n', file_name);

            % ファイルを読み込む
            data = load(full_file_path);
            obj.participant_name = data.num_participant;

            block = data.block;  % 読み込んだデータからblockを取得

            % 既存のデータがある場合、1次元目を拡張する
            if file_idx == 1
                obj.beep_times_keys = block.beep_times_keys;
                obj.keystrokes = block.keystrokes;
                obj.pressed_times = block.pressed_times;
                obj.window_delimiters = block.window_delimiters;
                obj.judge = block.judge;
            else

                %% ここから編集2/3
                obj.beep_times_keys = cat(1, obj.beep_times_keys, block.beep_times_keys);
                obj.keystrokes = block.keystrokes;
                obj.pressed_times = block.pressed_times;
                obj.window_delimiters = block.window_delimiters;
                obj.judge = block.judge;
            end

            % このblockのtrial数を取得
            obj.num_trials = block.num_last_trial;

            % キーの種類数を取得
            obj.num_keys = size(obj.beep_times_keys, 3);

            % 打鍵間隔の推移を取得
            obj.tap_intervals = block.tap_intervals;

            % 打鍵判定区間の初期化
            obj.acceptance_start = NaN(obj.num_trials, max(obj.keystrokes.num_loops), obj.num_keys);
            obj.acceptance_end = NaN(obj.num_trials, max(obj.keystrokes.num_loops), obj.num_keys);

            % 補正後のキー押し下し時刻の初期化
            obj.corrected_pressed_times = NaN(obj.num_trials, obj.num_keys, 2000);

            % 速度レベルを格納する
            trial_speed_level = block.interval_index_recorder;
            obj.block_speed_level(file_idx, :) = trial_speed_level;
        end
        
        % 最頻の打鍵速度で実行したtrialのデータを取得
        function obj = load_target_data(obj)
            % 該当trialの算出
            obj.mode_speed_level = mode(obj.block_speed_level, 'all');
            obj.num_target_trials = find(obj.block_speed_level == obj.mode_speed_level); % main block全体を100trialとしたときの該当trialの番号
            obj.num_trials = length(obj.num_target_trials);

            if obj.num_trials < 30
                fprintf("Warning! target_data is only %d trials", obj.num_trials)
            end

            % 全target_trialsのデータを一つにまとめる


        end

function obj = calculate_corrected_pressed_times(obj)
            for trial_idx = 1:obj.num_trials
                for key_idx = 1:obj.num_keys
                    pressed_times_key = squeeze(obj.pressed_times(trial_idx, key_idx, :)); %%% 要観察
                    pressed_times_key = pressed_times_key(pressed_times_key > 0); % 0未満は無視

                    % task開始時のビープ音の時刻を基準に時刻を補正
                    obj.corrected_pressed_times(trial_idx, key_idx, 1:size(pressed_times_key)) = pressed_times_key - obj.beep_times_keys(trial_idx, 1, 1);
                    % corrected_pressed_times = corrected_pressed_times(corrected_pressed_times > - tap_interval(trial_idx)); % 異常な負の打鍵時刻を消去
                end
            end
        end

        function obj = calculate_acceptance_window(obj)
            for trial_idx = 1:obj.num_trials
                for loop = 1:obj.keystrokes.num_loops(trial_idx)

                    % 打鍵受付範囲を塗りつぶしで表示
                    for key = 1:obj.num_keys

                        % 到達した打鍵判定区間以降は、obj.judgeにNaNが格納されているため処理を行わない
                        if obj.keystrokes.num_keystroke_sections(trial_idx) < 4*(loop - 1) + key
                            break;
                        end

                        % window_shiftを算出
                        if obj.block_type == 'P'
                            window_shift = obj.window_delimiters.window_shift_rates(ceil(trial_idx/4)) * obj.tap_intervals(trial_idx)/2;
                        elseif obj.block_type == 'M'
                            window_shift = obj.window_delimiters.window_shift_rate * obj.tap_intervals(trial_idx)/2;
                        else
                            window_shift = 0;
                        end

                        % ビープ音の提示時刻を中心に決定した打鍵受付区間 これらをtask開始時のビープ音の時刻を基準に補正
                        obj.acceptance_start(trial_idx, loop, key) = obj.window_delimiters.acception_window_start(trial_idx, loop, key) + window_shift;
                        obj.acceptance_end(trial_idx, loop, key) = obj.window_delimiters.acception_window_end(trial_idx, loop, key) + window_shift;
                        obj.acceptance_start(trial_idx, loop, key) = obj.acceptance_start(trial_idx, loop, key) - obj.beep_times_keys(trial_idx, 1, 1);
                        obj.acceptance_end(trial_idx, loop, key) = obj.acceptance_end(trial_idx, loop, key) - obj.beep_times_keys(trial_idx, 1, 1);
                    end
                end
            end
        end

        function draw_plot(obj)
        end
    end
end
