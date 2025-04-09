classdef EEGdataProcessor
    % 脳波を解析可能な形にフィルタ処理、保存、関心trial以外の削除

    properties
    end

    methods(Access=public)
        function obj = EEGdataProcessor()
        end
    end

    methods (Static)
        % このクラスのすべての処理を一貫して実行
        function EEG_folder = run(cfg, input_folder_path, tap_data, save_path)

            target_trials = tap_data.target_trials; % 関心trial番号のリストを取得

            % 全ての被験者について、EEGdataの.matファイルが入ったフォルダのパスを取得
            all_folder_list = EEGdataProcessor.get_all_folders(input_folder_path);
            total_subjects = length(all_folder_list); % 被験者の総数

            % % 全被験者のEEGデータを格納した配列（保存する）の初期化
            % frqfiled_all_blocks_all_sbj = {total_subjects};
            % frqfiled_all_blocks_beta_all_sbj = {total_subjects};
            % frqfiled_target_trials_all_sbj = {total_subjects};

            % 各被験者のフォルダについて、測定データのロード、処理、保存、関心trial以外の削除
            for subject_idx = 1:total_subjects
                folder_path = all_folder_list{subject_idx};
                fprintf('\nProcessing folder No.%d: %s\n', subject_idx, folder_path);
                file_list = dir(fullfile(folder_path, '*.mat')); % フォルダ内の.matファイルを取得

                % 一時的にコメントアウト
                % % 1被験者について、block別に分かれた各ファイルを読み込み、バンドパスなどの処理をし、連結
                % spafiled_all_blocks = EEGdataProcessor.process_EEG(cfg, folder_path, file_list);
                % 
                % 保存先のフォルダの作成
                EEG_folder = fullfile(save_path, 'EEG');
                subject_name = file_list(1).name(1:4); % 解析したファイル名の冒頭4文字を、Subject名として取得
                subject_folder = fullfile(EEG_folder, subject_name);
                if ~exist(subject_folder, 'dir') % 保存フォルダの作成
                    mkdir(subject_folder);
                end
                % 
                % % spafiled_all_blocksの保存
                % file_path = fullfile(subject_folder, 'spafiled_all_blocks');
                % save(file_path, 'spafiled_all_blocks', '-v7.3');


                % 関心周波数帯(β帯)でのバンドパス（今回は全被験者で14~30）でフィルタ処理
                cfg.hpfrq = 14; cfg.lpfrq = 30; % バンドパスの周波数帯を、β帯に再設定
                % 1被験者について、block別に分かれた各ファイルを読み込み、バンドパスなどの処理をし、連結
                spafiled_all_blocks_beta = EEGdataProcessor.process_EEG(cfg, folder_path, file_list);

                % spafiled_all_blocks_betaの保存
                file_path = fullfile(subject_folder, 'spafiled_all_blocks_beta');
                save(file_path, 'spafiled_all_blocks_beta', '-v7.3');

                % 打鍵データをもとに、関心trialの脳波だけを取り出す
                spafiled_target_trials_beta = spafiled_all_blocks_beta(:, :, target_trials(~isnan(target_trials(:,subject_idx)), subject_idx));

                % spafiled_target_trials_betaの保存
                file_path = fullfile(subject_folder, 'spafiled_target_trials_beta');
                save(file_path, 'spafiled_target_trials_beta', '-v7.3');


                % 関心周波数帯(α帯)でのバンドパス（今回は全被験者で8~13）でフィルタ処理（%%%清水君に確認！）
                cfg.hpfrq = 8; cfg.lpfrq = 13; % バンドパスの周波数帯を、帯に再設定
                % 1被験者について、block別に分かれた各ファイルを読み込み、バンドパスなどの処理をし、連結
                spafiled_all_blocks_alpha = EEGdataProcessor.process_EEG(cfg, folder_path, file_list);


                % spafiled_all_blocks_alphaの保存
                file_path = fullfile(subject_folder, 'spafiled_all_blocks_alpha');
                save(file_path, 'spafiled_all_blocks_alpha', '-v7.3');

                % 打鍵データをもとに、関心trialの脳波だけを取り出す
                spafiled_target_trials_alpha = spafiled_all_blocks_alpha(:, :, target_trials(~isnan(target_trials(:,subject_idx)), subject_idx));

                % spafiled_target_trials_alphaの保存
                file_path = fullfile(subject_folder, 'spafiled_target_trials_alpha');
                save(file_path, 'spafiled_target_trials_alpha', '-v7.3');

                % % 各被験者のデータを順に格納
                % frqfiled_all_blocks_all_sbj{folder_idx} = frqfiled_all_blocks;
                % frqfiled_all_blocks_beta_all_sbj{folder_idx} = frqfiled_all_blocks_beta;
                % frqfiled_target_trials_all_sbj{folder_idx} = frqfiled_target_trials;
            end

            % % 全被験者のデータを順に格納して保存(MAT ファイル Version 7.3で)
            % subject_folder = fullfile(save_path, 'EEG');
            % if ~exist(subject_folder, 'dir') % 保存フォルダの作成
            %     mkdir(subject_folder);
            % end
            % save(fullfile(subject_folder, 'frqfiled_all_blocks_all_sbj.mat'), 'frqfiled_all_blocks_all_sbj', '-v7.3');
            % save(fullfile(subject_folder, 'frqfiled_all_blocks_beta_all_sbj.mat'), 'frqfiled_all_blocks_beta_all_sbj', '-v7.3');
            % save(fullfile(subject_folder, 'frqfiled_target_trials_all_sbj.mat'), 'frqfiled_target_trials_all_sbj', '-v7.3');
            % save(fullfile(subject_folder, 'frqfiled_all_blocks_all_sbj.mat'), 'frqfiled_all_blocks_all_sbj');
            % save(fullfile(subject_folder, 'frqfiled_all_blocks_beta_all_sbj.mat'), 'frqfiled_all_blocks_beta_all_sbj');
            % save(fullfile(subject_folder, 'frqfiled_target_trials_all_sbj.mat'), 'frqfiled_target_trials_all_sbj');
        end

        % 全ての被験者について、EEGdataの.matファイルが入ったフォルダのパスを取得
        function all_folder_list = get_all_folders(input_folder_path)
            % フォルダ内の全リストを取得
            folder_list = dir(input_folder_path);

            % 出力配列の初期化
            all_folder_list = {};

            % 正規表現で"Y+3桁の数字"が含まれるフォルダ名を検索
            pattern = "Y\d{3}";

            for i = 1:length(folder_list)
                if folder_list(i).isdir && ~strcmp(folder_list(i).name, '.') && ~strcmp(folder_list(i).name, '..')
                    if ~isempty(regexp(folder_list(i).name, pattern, 'once'))
                        % Mainフォルダのパスを取得
                        main_path = fullfile(input_folder_path, folder_list(i).name, 'EEGdata', 'mat', 'Main');
                        if isfolder(main_path)
                            all_folder_list{end+1} = main_path; %#ok<AGROW>
                        end
                    end
                end
            end
        end

        % 指定したバンドパスで脳波処理を実行、連結した1人分のデータを取得
        function spafiled_all_blocks = process_EEG(cfg, folder_path, file_list)

            % 配列の初期化
            spafiled_all_blocks = [];

            % 1被験者について、block別に分かれた各ファイルを読み込み、バンドパスなどの処理をし、連結
            for file_idx = 1:length(file_list)
                cfg.datapath = fullfile(folder_path, file_list(file_idx).name); % 各.matファイルのパスを指定
                fprintf('Processing file %d: %s\n', file_idx, cfg.datapath); % 処理中のファイル名を表示

                % バンドパス（通常は2~40Hz）などの前処理
                data_eeg = EEGProcessor;
                data_eeg.epocher = Rest2TaskEpocher;
                data_eeg = data_eeg.processing(cfg);
                % ersp = data_eeg.ersp; % 時間(100ms)×周波数(1~40Hz)×チャンネル数(129)×trial数の配列
                spafiled = data_eeg.spafiled; % 時間(1ms)×チャンネル数(129)×trial数の配列

                spafiled_all_blocks = connect_spafiled_data(spafiled_all_blocks, spafiled); % 前処理後のデータをtrial方向に連結
            end

            % 前処理後のデータをtrial方向に連結
            function all_data = connect_spafiled_data(all_data, one_data)

                if ~isempty(all_data)
                    % 結合データのサイズを揃えるための、NaNで埋めるパディング：1次元目（最初の次元）のサイズを調整し、サイズを統一（大きい方に合わせる
                    max_dim1 = max(size(all_data, 1), size(one_data, 1));
                    if size(all_data, 1) < max_dim1
                        pad_size = max_dim1 - size(all_data, 1);
                        all_data = padarray(all_data, [pad_size, 0, 0, 0], NaN, 'post');
                    end
                    if size(one_data, 1) < max_dim1
                        pad_size = max_dim1 - size(one_data, 1);
                        one_data = padarray(one_data, [pad_size, 0, 0, 0], NaN, 'post');
                    end
                end
                all_data = cat(3, all_data, one_data);
            end
        end
    end
end

