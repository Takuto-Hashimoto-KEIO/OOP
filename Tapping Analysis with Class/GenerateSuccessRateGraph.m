%% 打鍵成功率をplotする箱ひげ図を描くコード
classdef GenerateSuccessRateGraph
    %GENERATESUCCESSRATEGRAPH このクラスの概要をここに記述

    properties
        num_trials
        participant_name

        success_rates
        block_labels
        trial_success_rates
    end

    methods
        function obj = GenerateSuccessRateGraph()
            %GENERATESUCCESSRATEGRAPH このクラスのインスタンスを作成
        end

        function run_generate_success_rate_graph(obj, folder_path)
            % フォルダ内の該当するデータファイルを全て読み込む
            file_list = dir(fullfile(folder_path, 'Block_Result_*.mat'));

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

            % ブロックごとの成功率とラベルを格納する変数
            obj.success_rates = [];  % 各ブロックの打鍵成功率（20トライアル分）
            obj.block_labels = [];  % 各データのブロックラベル

            % ファイルごとに処理を実行
            for file_idx = 1:length(file_list)
                obj = load_data(obj, file_list, file_idx);
            end

            % プロットを作成してフォルダに保存
            plot_boxplot(obj, file_list, x_labels);

            % 箱ひげ図を保存
            mean_block_success_rates = save_plot(obj, folder_path);

            % 打鍵成功率のblock平均を計算し、CSVファイルに出力
            obj.save_success_rates_to_csv(folder_path, mean_block_success_rates);
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
            block = data.block;  % 読み込んだデータからblockを取得

            % トライアル数の定義
            obj.num_trials = block.num_last_trial;  % トライアル数

            % 成功率を格納する配列（20行×1列のベクトル）
            obj.trial_success_rates = NaN(obj.num_trials, 1);

            % 各trial（行）ごとに成功率を計算
            for trial = 1:obj.num_trials
                trial_data = block.judge(trial, :);
                % NaNを除く有効データ数を計算
                valid_data = trial_data(~isnan(trial_data));
                % 成功率を計算
                obj.trial_success_rates(trial) = sum(valid_data == 1) / numel(valid_data) * 100;
            end

            obj.success_rates = [obj.success_rates; obj.trial_success_rates];

            % ブロックラベルを保存
            obj.block_labels = [obj.block_labels; file_idx * ones(obj.num_trials, 1)];
        end

        function plot_boxplot(obj, file_list, x_labels)
            % ブロック数を取得
            num_blocks = length(file_list);

            % 打鍵成功率の箱ひげ図を作成
            figure;
            boxplot(obj.success_rates, obj.block_labels, 'Colors', 'b');  % 線を青に
            hold on;

            % 箱ひげ図のスタイルを調整
            h = findobj(gca, 'Tag', 'Box');
            for j = 1:length(h)
                patch(get(h(j), 'XData'), get(h(j), 'YData'), [0.7 0.8 1], 'FaceAlpha', 0.5);  % 四分位範囲を薄い青色で塗りつぶす
            end

            % 中央値とアウトライアのスタイルを変更
            set(findobj(gca, 'Tag', 'Median'), 'Color', 'r', 'LineWidth', 3);  % 中央値を赤、太さ3倍
            set(findobj(gca, 'Tag', 'Box'), 'LineWidth', 3);  % 箱ひげの線を太さ3倍
            set(findobj(gca, 'Tag', 'Whisker'), 'LineWidth', 3);  % 髭線の太さを3倍
            set(findobj(gca, 'Tag', 'Outliers'), 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k');  % 点を黒で塗りつぶし

            % 重なる点を検出して処理
            jitter_amount = 0.05;  % 点をずらす量の初期設定
            box_width = 0.5;  % 箱ひげ図のボックス幅を設定（例として0.5）

            % ブロックごとのx座標の中心値
            x_original = 1:num_blocks;  % ブロックごとの元のx座標

            for block_idx = 1:num_blocks
                % 該当ブロックの成功率データを取得
                block_success_rates = obj.success_rates(obj.block_labels == block_idx);
                x_vals = block_idx * ones(size(block_success_rates));

                % トライアルごとにデータを処理し色を割り当てる
                for i = 1:length(block_success_rates)
                    rate = block_success_rates(i);
                    trial_idx = i;  % トライアル番号は行番号に対応

                    % トライアル番号に基づいて色を選択
                    if trial_idx <= 5
                        color = 'k';  % 黒
                    elseif trial_idx <= 10
                        color = 'b';  % 青
                    elseif trial_idx <= 15
                        color = [0, 0.5, 0];  % 緑
                    else
                        color = 'r';  % 赤
                    end

                    % 重複する点の検出
                    duplicated_idx = find(block_success_rates == rate);  % 同じ成功率を持つデータ点を見つける
                    count = numel(duplicated_idx);  % 重複の数をカウント

                    % 重複がある場合、点をずらしてプロット
                    if count > 1
                        % 現在の点が何番目にプロットされるかを確認
                        idx_in_duplicates = find(duplicated_idx == i);

                        % 左右にずらす処理
                        max_jitter = box_width * 0.15;  % ボックスの幅の20%までずらす
                        step = max_jitter / (count - 1);  % ずらし幅を計算

                        if idx_in_duplicates == 1
                            % 最初の点は中央にプロット
                            scatter(x_vals(i), rate, 50, color, 'filled');
                        else
                            % 2番目以降の点を左右にずらしてプロット
                            x_shifted = x_vals(i) + (idx_in_duplicates - 1) * step * (-1)^idx_in_duplicates;
                            scatter(x_shifted, rate, 50, color, 'filled');
                        end
                    else
                        % 重複がない場合はそのまま中央にプロット
                        scatter(x_vals(i), rate, 50, color, 'filled');
                    end
                end
            end
            hold off;

            % 上下左右に余白を持たせる設定
            outer_margin = 0.05;  % 外側の余白を指定 (5%)
            set(gca, 'OuterPosition', [outer_margin, outer_margin, 1 - 2 * outer_margin, 1 - 2 * outer_margin]);

            % グラフをきれいに表示するための設定
            set(gca, 'XTickLabel', x_labels, 'XTickLabelRotation', 45); % 横軸ラベルを適用
            ylabel('Success Rate (%)');
            title(['Subject ' obj.participant_name '  Keystroke Success Rate by Block'], 'FontSize', 16);

            fontsize(36,"points")
        end

        function mean_block_success_rates = save_plot(obj, folder_path)
            % "Success_Rate_graph" フォルダを作成（存在しない場合のみ）
            output_folder = fullfile(folder_path, 'Success_Rate_graph');
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

            % 1ブロック全体の打鍵成功率を計算
            unique_block_labels = unique(obj.block_labels);
            mean_block_success_rates = arrayfun(@(x) mean(obj.success_rates(obj.block_labels == x)), unique_block_labels);
        end
    end

    methods (Static, Access = private)
        % 打鍵成功率をCSVファイルに保存する関数
        function save_success_rates_to_csv(folder_path, mean_block_success_rates)
            output_folder = fullfile(folder_path, 'Success_Rate_graph');

            % CSVファイルに保存するデータの作成
            csv_data = mean_block_success_rates;

            % CSVファイル名の設定
            csv_filename = fullfile(output_folder, 'block_success_rates.csv');

            % CSVファイルとして保存
            csvwrite(csv_filename, csv_data);
        end
    end
end
