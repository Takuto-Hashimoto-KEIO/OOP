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
            first_file_data = load(fullfile(file_list(1).folder, file_list(1).name));
            obj.num_trials = size(first_file_data.block.success_duration, 1); % トライアル数を取得するため、最初のファイルを読み込む
            obj.all_durations = NaN(obj.num_trials, length(file_list));  % 行: トライアル、列: ブロック
            obj.all_positions = repmat(1:length(file_list), obj.num_trials, 1);  % ブロック番号を繰り返す
            obj.Hz_list = first_file_data.block.tap_interval_list; % 測定で使用された打鍵速度（Hz）のリスト
            obj.Hz = NaN(obj.num_trials, length(file_list)); % 各trialの打鍵速度（Hz）

            % ファイルごとに処理を実行
            for file_idx = 1:length(file_list)
                obj = load_data(obj, file_list, file_idx);
            end

            % プロットを作成してフォルダに保存
            plot_boxplot(obj, folder_path);

            % 打鍵成功持続時間のblock平均を計算し、CSVファイルに出力
            calculate_block_averages(obj, folder_path)
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
            obj.num_trials = size(obj.success_duration, 1);

            for trial_idx = 1:obj.num_trials %%% [検証用]のために6にしている、本来はobj.num_trials
                obj.all_durations(trial_idx, file_idx) = obj.success_duration(trial_idx);
                obj.Hz(trial_idx, file_idx) = obj.Hz_list(data.block.interval_index_recorder(trial_idx));
            end
        end

        function plot_boxplot(obj, folder_path)
            figure;
            hold on;

            % データの形状を確認
            if numel(obj.all_durations) ~= numel(obj.all_positions)
                error('The number of elements in all_durations and all_positions must be the same.');
            end

            % all_durationsとall_positionsをベクトル形式に変換
            obj.all_durations = obj.all_durations(:);  % 縦ベクトルに変換
            obj.all_positions = obj.all_positions(:);  % 縦ベクトルに変換

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
            xlabel('Block', 'FontSize', 14);
            ylabel('Success Duration (seconds)', 'FontSize', 14);
            title(['Subject ' obj.participant_name], ...
                'FontSize', 16);
            box on;

            fontsize(36,"points")
            hold off;

            % "Success_Durations_graph" フォルダを作成（存在しない場合のみ）
            output_folder = fullfile(folder_path, 'Success_Durations_graph');
            if ~exist(output_folder, 'dir')
                mkdir(output_folder);
            end

            % 箱ひげ図をMATLAB Figure (.fig)形式で保存
            savefig(fullfile(output_folder, ['subject_' obj.participant_name '_success_durations_graph.fig']));

            % 各ブロックごとのHz最頻値を計算し、テキストとして表示
            unique_blocks = unique(obj.all_positions);
            for block_idx = unique_blocks'
                block_Hz = obj.Hz(:, block_idx);  % 該当ブロックのHzデータを取得
                mode_Hz = mode(block_Hz(~isnan(block_Hz)));  % NaNを除いた最頻値を計算
                text(block_idx, -0.5, sprintf('%.1f Hz', mode_Hz), 'HorizontalAlignment', 'center', 'FontSize', 12, 'VerticalAlignment', 'top');  % 横軸ラベルの上に表示
            end
            fontsize(36,"points")
        end

        function calculate_block_averages(obj, folder_path)
            % NaNを無視して、各ブロックのsuccess_durationの平均値を計算
            block_mean = nanmean(obj.all_durations, 1);

            % CSVファイルの保存場所をfolder_pathに指定
            csv_filename = fullfile(folder_path, ['subject_' obj.participant_name '_success_durations_block_average.csv']);

            % writematrixを使用してCSVファイルに保存
            writematrix(block_mean, csv_filename);
        end
    end
end
