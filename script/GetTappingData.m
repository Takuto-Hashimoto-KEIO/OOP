classdef GetTappingData
    % 打鍵データから解析に必要なデータを抽出、保存
    
        properties
    end

    methods(Access=public)
        function obj = GetTappingData()
        end
    end

    methods (Static)
        % このクラスのすべての処理を一貫して実行
        function tap_data = run(folder_path)
            % ファイルリストの取得
            file_list = GetTappingData.get_file_list(folder_path);

            % 解析に必要な打鍵データの取得
            tap_data = GetTappingData.get_tap_data(file_list);

            % 解析に必要な打鍵データの保存
            GetTappingData.save_tap_data(tap_data, folder_path);
        end

        % ファイルリストを取得
        function file_list = get_file_list(folder_path)
            % ファイルリストの初期化
            file_list = {};

            % フォルダ内のSubject名のディレクトリを取得
            subject_dirs = dir(folder_path);
            subject_dirs = subject_dirs([subject_dirs.isdir]);

            % Subject名に合致するフォルダのみを取得（Y + 3桁の数字）
            subject_pattern = '^Y\d{3}$';
            valid_subjects = {};

            for i = 1:length(subject_dirs)
                if regexp(subject_dirs(i).name, subject_pattern)
                    valid_subjects{end+1} = subject_dirs(i).name;
                end
            end

            % 各Subjectフォルダを探索
            for i = 1:length(valid_subjects)
                subject_name = valid_subjects{i};
                % 該当ファイルの検索
                pattern = fullfile(folder_path, subject_name, sprintf('%s_all_target_*_trials.mat', subject_name));
                files = dir(pattern);
                
                % ファイルが見つかった場合に追加
                for j = 1:length(files)
                    file_list{end+1} = fullfile(files(j).folder, files(j).name);
                end
            end
        end

        % ファイルリストをもとにデータを取得
        function tap_data = get_tap_data(file_list)
            num_files = length(file_list);
            max_trials = 100;

            % NaNで初期化
            target_trials = NaN(max_trials, num_files);
            first_misstap_time = NaN(max_trials, num_files);
            total_target_trials = NaN(num_files, 1);

            for i = 1:num_files
                data = load(file_list{i});

                % target_trials を取得（存在する場合のみ）
                if isfield(data.result, 'target_trials')
                    num_entries = min(length(data.result.target_trials), max_trials);
                    target_trials(1:num_entries, i) = data.result.target_trials(1:num_entries);
                end

                % first_misstap_time を取得（存在する場合のみ）
                if isfield(data.result.target_data, 'first_misstap_time')
                    num_entries = min(length(data.result.target_data.first_misstap_time), max_trials);
                    first_misstap_time(1:num_entries, i) = data.result.target_data.first_misstap_time(1:num_entries);

                    % total_target_trials（関心trialの総数）を取得
                    total_target_trials(i) = num_entries;
                end

                % first_misstap_indices を取得（存在する場合のみ）
                if isfield(data.result.target_data, 'first_misstap_indices')
                    num_entries = min(length(data.result.target_data.first_misstap_indices), max_trials);
                    first_misstap_indices(1:num_entries, i) = data.result.target_data.first_misstap_indices(1:num_entries);
                end

                % 出力を構造体にして整理
                tap_data = struct('target_trials', target_trials, ...
                    'first_misstap_indices', first_misstap_indices, ...
                    'first_misstap_time', first_misstap_time, ...
                    'total_target_trials', total_target_trials);
            end
        end

        % データを保存
        function save_tap_data(tap_data, save_path)
            file_path = fullfile(save_path, 'tap_data');
            save(file_path, 'tap_data');
        end
    end
end

