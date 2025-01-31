classdef GenerateAramakiPlot
    %GENERATEARAMAKIPLOT このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        participant_name
        block_type
        num_block

        num_trials
        num_keys
        tap_intervals

        beep_times_keys
        corrected_beep_times_keys
        keystrokes
        pressed_times
        corrected_pressed_times
        window_delimiters
        judge

        acceptance_start
        acceptance_end
    end

    methods
        function obj = GenerateAramakiPlot()
            %GENERATEARAMAKIPLOT このクラスのインスタンスを作成
        end

        % GenerateAramakiPlotの全機能を一貫して実行
        function run_generate_aramaki_plot(obj, folder_path)

            % フォルダ内の該当するデータファイルを全て読み込む
            files = dir(fullfile(folder_path, 'Block_Result_*.mat'));

            % ファイルごとに処理を実行
            for file_idx = 1:length(files)
                obj = load_data(obj, folder_path, files, file_idx);
                obj = calculate_corrected_pressed_times(obj);
                obj = calculate_acceptance_window(obj);
                plot_data(obj, folder_path);

                % % 1blockの打鍵もつれの要約を出力 20250129 作成
                file_summary = VisualizeKeystrokeError(obj);
                file_summary.run_visualize_keystroke_error(folder_path);
            end
        end
    end

    methods (Access = private)
        % データのロードと格納
        function obj = load_data(obj, folder_path, files, file_idx)

            % ファイル名を取り出す
            filename = files(file_idx).name;

            % blockの種類を抽出
            pattern = 'Block_Result_.*?_(.*?)_block\d+_\d+';
            obj.block_type = regexp(filename, pattern, 'tokens', 'once');
            if ~isempty(obj.block_type)
                obj.block_type = obj.block_type{1}; % セル配列から文字列を取得
            else
                obj.block_type = ''; % パターンに一致しない場合の処理
            end

            % ファイル名とblockの種類を表示（デバッグ用、必要なら削除）
            fprintf('Processing file: %s, Block type: %s\n', filename, obj.block_type);

            data = load(fullfile(folder_path, files(file_idx).name));

            % データを抽出
            obj.participant_name = data.num_participant;
            obj.num_block = data.num_block;
            block = data.block;

            obj.beep_times_keys = block.beep_times_keys;
            obj.keystrokes = block.keystrokes;
            obj.pressed_times = block.pressed_times;
            obj.window_delimiters = block.window_delimiters;
            obj.judge = block.judge;

            % trial数を取得
            % obj.num_trials = 2; % 一時的に使用
            obj.num_trials = block.num_last_trial; % 本来はこれを使用

            % キーの種類数を取得
            obj.num_keys = size(obj.beep_times_keys, 3);
            
            % 打鍵間隔の推移を取得
            obj.tap_intervals = block.tap_intervals;

            % 打鍵判定区間の初期化
            obj.acceptance_start = NaN(obj.num_trials, max(obj.keystrokes.num_loops), obj.num_keys);
            obj.acceptance_end = NaN(obj.num_trials, max(obj.keystrokes.num_loops), obj.num_keys);

            % 補正後のキー押し下し時刻の初期化
            obj.corrected_pressed_times = NaN(obj.num_trials, obj.num_keys, 2000); % 初期化
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

        % 各trialのプロットを生成
        function plot_data(obj, folder_path)
            % trialごとに処理を実行
            for trial_idx = 1:obj.num_trials %%% [検証用]のために6にしている、本来はobj.num_trials
                figure;
                hold on;

                % キーのラベルとその縦軸の位置
                keys = {'J', 'E', 'I', 'F'};
                key_positions = [5, 4, 3, 2]; % J=5, E=4, I=3, F=2の位置
                % キーの説明ラベル
                keys_legend = {'RI', 'LM', 'RM', 'LI'};

                % NUMを縦軸の5にプロット
                colors4 = {[0, 0, 1], [0, 0.5, 0], [1, 0, 0], [0.5, 0, 0.5]}; %% 青, 緑, 赤, 紫

                % obj.beep_times_keysについて、task開始時の最初のビープ音を基準(0)に補正
                obj.corrected_beep_times_keys = obj.beep_times_keys(trial_idx, :, :) - obj.beep_times_keys(trial_idx, 1, 1);

                for key = 1:obj.num_keys
                    % 打鍵すべきキーによって色を変えてプロット
                    plot(obj.corrected_beep_times_keys(1, :, key), 1 * ones(1, size(obj.corrected_beep_times_keys, 2)), ...
                        's', 'Color', colors4{key}, 'MarkerFaceColor', colors4{key}, 'HandleVisibility', 'off')

                    % 垂線を追加
                    trial_beep_times = obj.corrected_beep_times_keys(1, :, key);
                    for t_idx = 1:length(trial_beep_times)
                        t = trial_beep_times(1, t_idx);
                        xline(t, '--', 'Color', colors4{key}, 'HandleVisibility', 'off'); % 点線の垂線（'off'で凡例から除外）
                    end
                end


                % 各打鍵をプロット

                % % 押し下し開始時の打鍵データだけをプロットする場合
                % for key_idx = 1:obj.num_keys
                %     pressed_times_key = squeeze(obj.pressed_times(trial_idx, key_idx, :));
                % pressed_times_key = pressed_times_key(pressed_times_key > 0); % 0は無視
                %
                %     % 直前の要素が0であり、かつその要素が0でないものを抽出(各打鍵の開始時刻だけを抽出)
                %     pressed_times_key_filtered = [];
                %     for i = 2:length(pressed_times_key)
                %         if pressed_times_key(i-1) == 0 && pressed_times_key(i) > 0
                %             pressed_times_key_filtered = [pressed_times_key_filtered; pressed_times_key(i)];
                %         end
                %     end
                %     pressed_times_key = pressed_times_key_filtered;
                %
                % %     pressed_times_key = pressed_times_key(pressed_times_key > 0); % 0は無視
                %
                %     % 初期打鍵時刻を基準に時刻を補正
                %     corrected_pressed_times = pressed_times_key - obj.beep_times_keys(trial_idx, 1, 1);
                %
                %     % キーごとのマーカースタイル設定
                %     plot(corrected_pressed_times, key_positions(key_idx) * ones(1, length(corrected_pressed_times)), ...
                %         'o', 'MarkerFaceColor', colors4{key_idx}, 'Color', colors4{key_idx}, ...
                %         'DisplayName', [keys{key_idx} ' (' keys_legend{key_idx} ')']);
                % end

                % 押し下し～離鍵時　全ての打鍵データをプロットする場合
                for key_idx = 1:obj.num_keys
                    % キーごとにマーカースタイルを設定し、プロット
                    plot(squeeze(obj.corrected_pressed_times(trial_idx, key_idx, :)), key_positions(key_idx) * ones(1, length(obj.corrected_pressed_times)), ...
                        'o', 'MarkerFaceColor', colors4{key_idx}, 'Color', colors4{key_idx}, ...
                        'DisplayName', [keys{key_idx} ' (' keys_legend{key_idx} ')']);
                end

                % 打鍵受付範囲の取得とプロット
                for loop = 1:obj.keystrokes.num_loops(trial_idx)

                    % 打鍵受付範囲を塗りつぶしで表示
                    for key = 1:obj.num_keys

                        % 到達した打鍵判定区間以降は、obj.judgeにNaNが格納されているため処理を行わない
                        if obj.keystrokes.num_keystroke_sections(trial_idx) < 4*(loop - 1) + key
                            break;
                        end

                        % 打鍵判定区間を示す配列の名称を省略
                        a_start = obj.acceptance_start(trial_idx, loop, key);
                        a_end = obj.acceptance_end(trial_idx, loop, key);

                        if obj.judge(trial_idx, 4*(loop - 1) + key) == 0
                            % 打鍵失敗区間を灰色で塗りつぶし
                            fill([a_start, a_end, a_end, a_start], ...
                                [6.5-key, 6.5-key, 5.5-key, 5.5-key], ...
                                [0.1, 0.1, 0.1], 'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');

                        elseif ~isnan(a_start) && ~isnan(a_end)
                            % 打鍵成功区間をそのキーに対応する色で塗りつぶし
                            fill([a_start, a_end, a_end, a_start], ...
                                [6.5-key, 6.5-key, 5.5-key, 5.5-key], ...
                                colors4{key}, 'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');
                        end
                    end
                end

                % 軸の設定
                ylim([0.5, 5.5]); % NUMを含めてy軸範囲を設定
                yticks([1, 2, 3, 4, 5]);
                yticklabels({'NUM', 'F', 'I', 'E', 'J'}); % NUMを含めたラベル
                xlabel('Time (sec)');
                ylabel('Keys');
                title(['Subject ' obj.participant_name ', ' obj.block_type ' block ' obj.num_block ', trial ' num2str(trial_idx) ', ' ...
                    num2str(1/obj.tap_intervals(trial_idx)) ' Hz']);

                % 塗りつぶし部分を凡例に含めないための調整
                legend('Location', 'best');
                legend;

                fontsize(36,"points")
                hold off;

                % "Aramaki_graph" フォルダを作成（存在しない場合のみ）
                output_folder = fullfile(folder_path, 'Aramaki_graph');
                if ~exist(output_folder, 'dir')
                    mkdir(output_folder);
                end

                % MATLAB Figure (.fig)形式で保存パスを設定して保存
                savefig(fullfile(output_folder, ['subject_' obj.participant_name '_' obj.block_type '_block_' obj.num_block '_trial_' num2str(trial_idx) '_graph.fig']));
            end
        end
    end
end
