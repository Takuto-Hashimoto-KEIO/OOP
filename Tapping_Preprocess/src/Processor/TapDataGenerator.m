classdef TapDataGenerator
    % 解析に必要なデータを作成して処理
    
    properties
        raw_dataset
        cond
        result
    end

    methods(Access=public)
        function obj = TapDataGenerator()
        end
    end

    methods
        % このクラスのすべての処理を一貫して実行
        function result = generate_data(obj, cfg, result)
            obj = obj.create_array(cfg, result);
            first_misstap_indices = generate_first_misstap_idx(obj);
            first_misstap_time = generate_first_misstap_time(obj, first_misstap_indices);

            % 出力を整理
            result.generated.first_misstap_indices = first_misstap_indices;
            result.generated.first_misstap_time = first_misstap_time;
        end

        % インスタンスの整理
        function obj = create_array(obj, cfg, result)
            obj.raw_dataset = cfg.raw_dataset;
            obj.cond = cfg.cond;
            obj.result = result;
        end

        % % 処理後のデータ格納配列を定義
        % function obj = create_array(obj, cfg, result)
        %     obj.raw_dataset = cfg.raw_dataset;
        %     obj.cond = cfg.cond;
        %     obj.result = result;
        % end

        % 最初にもつれた打鍵がtask開始から何番目の打鍵か（trial×1）の取得  %% 03/21ここからスタート
        function first_misstap_indices = generate_first_misstap_idx(obj)

            % 必要なデータの整理
            judge = obj.result.raw.judge;
            first_misstap_indices = NaN(obj.cond.total_trials, 1); % 出力する配列を初期化

            % 処理
            for trial_idx = 1:obj.cond.total_trials
                % 現在のtrialにおいて、成功した打鍵（judgeが1）のインデックスを取得
                success_indices = find(judge(trial_idx, :) == 1);

                if ~isempty(success_indices) % 成功打鍵が無ければ、そのtrialのfirst_misstap_indicesにはNaNが格納されたまま
                    first_success = success_indices(1); % 最初の成功インデックスを取得
                    num_keystroke_sections = numel(find(~isnan(judge(trial_idx, :)))); % 打鍵判定区間の総数
                  
                    % 最初の成功インデックスに基づいて、task開始～最初の打鍵成功までの時間(秒)を一時計算
                    temp_duration = (first_success / num_keystroke_sections) * obj.cond.trial_task_time;

                    % temp_durationが3秒より大きい場合は、first_misstap_indicesを強制的に1とする（最初の打鍵成功が遅すぎるため、測定系でsuccess_durationも強制的に0となっている）
                    if temp_duration > 3
                        first_misstap_indices(trial_idx) = 1;
                    else % 成功した打鍵が存在する場合のみ処理を進める
                        % 最初の打鍵成功後の打鍵インデックスを1として、最初の失敗が何打鍵目かを探す
                        target_fail_idx = find(judge(trial_idx, first_success:end) == 0, 1);

                        if ~isempty(target_fail_idx) % 打鍵失敗がない場合はNaNのまま
                            first_misstap_indices(trial_idx) = first_success + target_fail_idx - 1;
                        end
                    end
                end
            end
        end

        % 最初に打鍵がもつれた時刻（task開始時を0とする）の取得
        function first_misstap_time = generate_first_misstap_time(obj, first_misstap_indices)

            % 必要なデータの整理
            beep_times_keys = obj.result.edited.beep_times_keys;
            first_misstap_time = NaN(obj.cond.total_trials, 1); % 出力する配列を初期化

            % 処理
            % beep_times_keysの2次元への変換
            [num_trials, num_keys, num_counts] = size(beep_times_keys);
            beep_times = nan(num_trials, num_keys * num_counts);

            for keys = 1:num_keys
                for counts = 1:num_counts
                    target_idx = num_keys * (counts - 1) + keys;
                    beep_times(:, target_idx) = beep_times_keys(:, keys, counts);
                end
            end

            % beep_timesのfirst_misstap_indices番目の時刻を格納
            for trial_idx = 1:obj.cond.total_trials
                if isnan(first_misstap_indices(trial_idx)) % 打鍵失敗がない場合、最初のもつれ時刻にもそのままNaNを格納
                else
                    first_misstap_time(trial_idx) = beep_times(trial_idx, first_misstap_indices(trial_idx));
                end
            end
        end
    end
end

