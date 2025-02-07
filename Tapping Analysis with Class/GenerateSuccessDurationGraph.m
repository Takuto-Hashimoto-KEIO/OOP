classdef GenerateSuccessDurationGraph
    %GENERATESUCCESSDURATIONGRAPH このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        all_durations
        all_positions
        Hz_list
        Hz

        participant_name

        num_trials
        success_duration
    end

    methods
        function obj = GenerateSuccessDurationGraph()
            %GENERATESUCCESSDURATIONGRAPH このクラスのインスタンスを作成
        end

        % GenerateSuccessDurationGraphの全ての機能を一貫して実行
        function run_generate_Success_Duration_graph(obj, folder_path)
            % フォルダ内の該当するデータファイルを全て読み込む
            file_list = dir(fullfile(folder_path, 'Block_Result_*.mat'));

            % 成功持続時間の全データを格納する行列を定義
            % 初期化を行う
            max_trials = 0;  % 最大トライアル数を記録
            for file_idx = 1:length(file_list)
                temp_data = load(fullfile(file_list(file_idx).folder, file_list(file_idx).name));
                max_trials = max(max_trials, temp_data.block.num_last_trial);  % 最大値を更新
            end
            obj.all_durations = NaN(max_trials, length(file_list));  % 最大トライアル数で初期化
            obj.all_positions = repmat(1:length(file_list), max_trials, 1);  % ブロック番号を繰り返す
            obj.Hz = NaN(max_trials, length(file_list)); % 各trialの打鍵速度（Hz）

            % 横軸ラベル用のリストを作成し、対応するインデックスを記録
            x_labels = strings(1, length(file_list));
            file_indices = 1:length(file_list);  % 元のファイル順序を保持
            for file_idx = 1:length(file_list)
                file_name = file_list(file_idx).name;

                % 正規表現でblockの種類とblock番号を抽出
                match = regexp(file_name, 'Block_Result_.*_(?<blockType>.*?)_block(?<blockNum>\d+)_.*', 'names');
                if ~isempty(match)
                    x_labels(file_idx) = sprintf('%s_%s', match.blockType, match.blockNum);
                else
                    x_labels(file_idx) = 'Unknown';
                end
            end

            % ラベルの並び替えロジック
            m_blocks = startsWith(x_labels, "M_");  % M_で始まるラベル
            p_blocks = startsWith(x_labels, "P_");  % P_で始まるラベル
            other_blocks = ~(m_blocks | p_blocks);  % その他のラベル

            % 並び替え: その他のラベル -> P_ラベル -> M_ラベル
            sorted_indices = [file_indices(other_blocks), file_indices(p_blocks), file_indices(m_blocks)];
            file_list = file_list(sorted_indices);  % ファイルリストを並び替え
            x_labels = x_labels(sorted_indices);   % ラベルも並び替え

            % 並び替えた順序に基づいてall_positionsを更新
            obj.all_positions = repmat(1:length(sorted_indices), size(obj.all_positions, 1), 1);

            % ファイルごとに処理を実行
            for file_idx = 1:length(file_list)
                obj = load_data(obj, file_list, file_idx);
            end

            % プロットを作成してフォルダに保存
            output_folder = plot_boxplot(obj, folder_path, x_labels);

            % 打鍵成功持続時間のblock平均を計算し、CSVファイルに出力
            calculate_block_averages(obj, output_folder)
        end
    end

    methods (Access = private)
        % データのロードと格納
        function obj = load_data(obj, file_list, file_idx)

            % ファイルのフルパスを取得
            file_name = file_list(file_idx).name;
            full_file_path = fullfile(file_list(file_idx).folder, file_name);

            % ファイルを読み込む
            data = load(full_file_path);

            obj.participant_name = data.num_participant;
            obj.success_duration = data.block.success_duration;
            obj.num_trials = data.block.num_last_trial;  % ファイル固有のトライアル数を取
            obj.Hz_list = 1 ./ data.block.tap_interval_list; % 測定で使用された打鍵速度（Hz）のリストを取得

            % 配列のリサイズ（不足があれば拡張）
            if size(obj.all_durations, 1) < obj.num_trials
                extra_rows = obj.num_trials - size(obj.all_durations, 1);
                obj.all_durations = [obj.all_durations; NaN(extra_rows, size(obj.all_durations, 2))];
                obj.Hz = [obj.Hz; NaN(extra_rows, size(obj.Hz, 2))];
            end

            for trial_idx = 1:obj.num_trials %%% [検証用]のために6にしている、本来はobj.num_trials
                obj.all_durations(trial_idx, file_idx) = obj.success_duration(trial_idx);
                obj.Hz(trial_idx, file_idx) = obj.Hz_list(data.block.interval_index_recorder(trial_idx));
            end
        end

        function output_folder = plot_boxplot(obj, folder_path, x_labels)
            figure;
            hold on;

            % データの形状を確認
            if numel(obj.all_durations) ~= numel(obj.all_positions)
                error('The number of elements in all_durations and all_positions must be the same.');
            end

            % NaNを含む要素を削除してベクトル化
            valid_idx = ~isnan(obj.all_durations);
            obj.all_durations = obj.all_durations(valid_idx);
            obj.all_positions = obj.all_positions(valid_idx);

            % 有効なデータがあるか確認
            if isempty(obj.all_durations) || isempty(obj.all_positions)
                error('No valid data to plot. Ensure that all_durations and all_positions contain valid values.');
            end

            % NaNを含む要素を削除
            nan_idx = isnan(obj.all_durations);
            obj.all_durations(nan_idx) = [];
            obj.all_positions(nan_idx) = [];

            % 箱ひげ図の作成
            h = boxplot(obj.all_durations, obj.all_positions, 'Widths', 0.5, 'Colors', 'b');
            set(h, {'linew'}, {3});  % 箱ひげ図の線の太さを3倍に設定

            % 中央線を赤色に変更
            set(findobj(gca, 'type', 'line', 'Tag', 'Median'), 'Color', 'r', 'LineWidth', 3);  % 中央値の線を赤色に設定

            % 箱を濃い青で塗りつぶす
            boxes = findobj(gca, 'Tag', 'Box');
            for j = 1:length(boxes)
                patch(get(boxes(j), 'XData'), get(boxes(j), 'YData'), 'b', 'FaceAlpha', 0.1);  % 濃い青で塗りつぶす
            end

            % 色の定義 (trial番号 1~5: 黒, 6~10: 青, 11~15: 緑 (蛍光色でない), 16~20: 赤)
            colors = {'k', 'b', [0, 0.5, 0], 'r'};

            % 各ブロックのデータ点をプロット
            box_width = 0.5;  % 箱ひげ図のボックス幅

            % 各ブロックインデックスごとにデータ点を処理
            unique_blocks = unique(obj.all_positions);  % ユニークなブロックインデックスを取得

            for block_idx = unique_blocks'
                block_data = obj.all_durations(obj.all_positions == block_idx);  % 該当ブロックのデータを取得

                % トライアルごとにデータを処理し色を割り当てる
                for i = 1:length(block_data)
                    duration = block_data(i);
                    trial_idx = i;  % トライアル番号は行番号に対応

                    % トライアル番号に基づいて色を選択
                    if trial_idx <= 5
                        color = colors{1};  % 黒
                    elseif trial_idx <= 10
                        color = colors{2};  % 青
                    elseif trial_idx <= 15
                        color = colors{3};  % 緑 (蛍光色でない)
                    else
                        color = colors{4};  % 赤
                    end

                    % 重複する点の検出（既に打たれた同じデータ点を確認）
                    duplicated_idx = find(block_data == duration);  % 同じduration値を持つデータ点を見つける
                    count = numel(duplicated_idx);  % 重複の数をカウント

                    % 重複がある場合、点をずらしてプロット
                    if count > 1
                        % 現在の点が何番目にプロットされるかを確認
                        idx_in_duplicates = find(duplicated_idx == i);

                        % 左右にずらす処理
                        max_jitter = box_width * 0.2;  % ボックスの幅の20%までずらす
                        step = max_jitter / (count - 1);  % ずらし幅を計算

                        if idx_in_duplicates == 1
                            % 最初の点は中央にプロット
                            scatter(block_idx, duration, 50, color, 'filled');
                        else
                            % 2番目以降の点を左右にずらしてプロット
                            x_shifted = block_idx + (idx_in_duplicates - 1) * step * (-1)^idx_in_duplicates;
                            scatter(x_shifted, duration, 50, color, 'filled');
                        end
                    else
                        % 重複がない場合はそのまま中央にプロット
                        scatter(block_idx, duration, 50, color, 'filled');
                    end
                end
            end

            % 縦軸の範囲を固定
            ylim([-2, max(obj.all_durations)]);  % 縦軸の最小値を-2に設定

            % グラフの設定
            set(gca, 'XTickLabel', x_labels, 'XTickLabelRotation', 45); % 横軸ラベルを適用
            ylabel('Success Duration (seconds)', 'FontSize', 14);
            title(['Subject ' obj.participant_name '  Keystroke Success Duration by Block'], 'FontSize', 16);
            box on;

            % 各ブロックごとのHz最頻値を計算し、テキストとして表示
            unique_blocks = unique(obj.all_positions);
            for block_idx = unique_blocks'
                block_Hz = obj.Hz(:, block_idx);  % 該当ブロックのHzデータを取得
                mode_Hz = mode(block_Hz(~isnan(block_Hz)));  % NaNを除いた最頻値を計算

                % 有効数字2桁に変換
                mode_Hz_sig2 = round(mode_Hz, 1 - floor(log10(abs(mode_Hz))));

                % 少数第一位まで表示するようにフォーマットを調整
                text(block_idx, -0.5, sprintf('%.1f Hz', mode_Hz_sig2), ...
                    'HorizontalAlignment', 'center', ...
                    'FontSize', 12, ...
                    'VerticalAlignment', 'top');  % 横軸ラベルの上に表示
            end

            fontsize(36,"points")
            hold off;

            % "Success_Durations_graph" フォルダを作成（存在しない場合のみ）
            output_folder = fullfile(folder_path, 'Success_Durations_graph');
            if ~exist(output_folder, 'dir')
                mkdir(output_folder);
            end

            % 保存ファイル名を定義
            fig_filename_fig = fullfile(output_folder, ['subject_' obj.participant_name '_success_duration.fig']);
            fig_filename_jpg = fullfile(output_folder, ['subject_' obj.participant_name '_success_duration.jpg']);

            % 保存処理を実行
            saveas(gcf, fig_filename_fig, 'fig');  % .fig形式で保存

            fig = gcf;
            fig.Units = 'normalized';
            fig.OuterPosition = [0 0 1 1]; % 全画面表示

            drawnow; % 画面更新を強制
            pause(0.1);
            saveas(gcf, fig_filename_jpg, 'jpg');  % .jpg形式で保存
        end

        function calculate_block_averages(obj, output_folder)
            % NaNを無視して、各ブロックのsuccess_durationの平均値を計算
            block_mean = nanmean(obj.all_durations, 1);

            % CSVファイルの保存場所をfolder_pathに指定
            csv_filename = fullfile(output_folder, ['subject_' obj.participant_name '_success_durations_block_average.csv']);

            % writematrixを使用してCSVファイルに保存
            writematrix(block_mean, csv_filename);
        end
    end
end
