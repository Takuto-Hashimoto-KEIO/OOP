classdef GenerateSpeedLevelGraph
    %GENERATESPEEDLEVELGRAPH このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        participant_name

        num_rows
        num_cols
        segment_length
        block_speed_level
    end

    methods
        function obj = GenerateSpeedLevelGraph()
            %GENERATESPEEDLEVELGRAPH このクラスのインスタンスを作成
        end

        % GenerateSpeedLevelGraphの全ての機能を一貫して実行
        function run_generate_speed_level_graph(obj, folder_path)
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

            % 条件に合うファイルがない場合、処理を終了
            if isempty(filtered_files)
                fprintf('条件に合うファイルが見つかりません。GenerateSpeedLevelGraphの処理を終了します。\n');
                return;
            end

            obj.block_speed_level = [];

            % ファイルごとに処理を実行
            for file_idx = 1:length(filtered_files)
                obj = load_data(obj, filtered_files, file_idx);
            end

            % プロットを作成
            draw_line_graph(obj);

            % グラフ画像を保存（最後の1枚のみ）
            % saveas(gcf, fullfile(folder_path, 'Main_block_speed_level_shift.png'));

            % "Speed_level_graph" フォルダを作成（存在しない場合のみ）
            output_folder = fullfile(folder_path, 'Speed_level_graph');
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


            % 速度レベルを格納する
            trial_speed_level = block.interval_index_recorder;
            obj.block_speed_level = [obj.block_speed_level; trial_speed_level];

            % データの行数と列数を取得
            [obj.num_rows, obj.num_cols] = size(obj.block_speed_level);

            % データが20個ずつで分割可能であることを確認
            obj.segment_length = block.num_last_trial;
            if mod(obj.num_rows, obj.segment_length) ~= 0
                error('block_speed_levelの行数は20の倍数である必要があります。');
            end
        end

        function draw_line_graph(obj)
            % 各セグメントの数を計算
            num_segments = obj.num_rows / obj.segment_length;

            % カラーマップの作成（異なる色をセグメントごとに割り当て）
            colors = lines(num_segments);

            % 折れ線グラフのプロット
            figure;
            hold on;
            for seg = 1:num_segments
                % 各セグメントの開始と終了インデックス
                start_idx = (seg - 1) * obj.segment_length;
                if start_idx == 0
                    start_idx = start_idx + 1;
                end
                end_idx = seg * obj.segment_length;

                % 各列のデータをそれぞれ異なる色でプロット
                for col = 1:obj.num_cols
                    % 現在セグメントをプロット
                    plot(start_idx:end_idx, obj.block_speed_level(start_idx:end_idx, col), ...
                        'Color', colors(seg, :), 'LineWidth', 5);
                end
            end
            hold off;

            % グラフの設定
            xlabel('Trial');
            ylabel('Speed Level');
            title(['Subject ' obj.participant_name '  Changes in Speed Level'], 'FontSize', 16);
            legend(arrayfun(@(x) sprintf('Block %d', x), 1:num_segments, 'UniformOutput', false));
            grid on;

            % 縦軸の目盛りを1刻みに設定
            ylim([floor(min(obj.block_speed_level(:))), ceil(max(obj.block_speed_level(:)))]);
            yticks(floor(min(obj.block_speed_level(:))):1:ceil(max(obj.block_speed_level(:))));
            fontsize(36,"points")
        end
    end
end

