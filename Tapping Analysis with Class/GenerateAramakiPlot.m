classdef GenerateAramakiPlot
    %GENERATEARAMAKIPLOT このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        participant_name
        num_block

        num_trials
        num_keys

        beep_times_keys
        keystrokes
        pressed_times
        window_delimiters
        judge 
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
                plot_data(obj, folder_path);
            end
        end
    end

    methods (Access = private)
        % データのロードと格納
        function obj = load_data(obj, folder_path, files, file_idx)

            data = load(fullfile(folder_path, files(file_idx).name));

            % データを抽出
            obj.participant_name = data.num_participant;
            obj.num_block = data.num_block;
            block = data.block;
            % tap_acceptance_start_times = block.tap_acceptance_start_times;
            % display_times = block.display_times;
            obj.beep_times_keys = block.beep_times_keys;
            obj.keystrokes = block.keystrokes;
            obj.pressed_times = block.pressed_times;
            obj.window_delimiters = block.window_delimiters;
            obj.judge = block.judge;
            
            % trial数を取得
            obj.num_trials = size(obj.judge, 1);

            % キーの種類数を取得
            obj.num_keys = size(obj.beep_times_keys, 3);
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
                corrected_beep_times_keys = obj.beep_times_keys(trial_idx, :, :) - obj.beep_times_keys(trial_idx, 1, 1);

                for key = 1:obj.num_keys
                    % 打鍵すべきキーによって色を変えてプロット
                    plot(corrected_beep_times_keys(1, :, key), 1 * ones(1, size(corrected_beep_times_keys, 2)), ...
                        's', 'Color', colors4{key}, 'MarkerFaceColor', colors4{key}, 'HandleVisibility', 'off')

                    % 垂線を追加
                    trial_beep_times = corrected_beep_times_keys(1, :, key);
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
                    pressed_times_key = squeeze(obj.pressed_times(trial_idx, key_idx, :)); %%% 要観察
                    pressed_times_key = pressed_times_key(pressed_times_key > 0); % 0は無視

                    % task開始時のビープ音の時刻を基準に時刻を補正
                    corrected_pressed_times = pressed_times_key - obj.beep_times_keys(trial_idx, 1, 1);
                    % corrected_pressed_times = corrected_pressed_times(corrected_pressed_times > - tap_interval(trial_idx)); % 異常な負の打鍵時刻を消去

                    % キーごとにマーカースタイルを設定し、プロット
                    plot(corrected_pressed_times, key_positions(key_idx) * ones(1, length(corrected_pressed_times)), ...
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

                        % ビープ音の提示時刻を中心に決定した打鍵受付区間 これらをtask開始時のビープ音の時刻を基準に時刻を補正
                        acceptance_start = obj.window_delimiters.acception_window_start(trial_idx, loop, key);
                        acceptance_end = obj.window_delimiters.acception_window_end(trial_idx, loop, key);
                        acceptance_start = acceptance_start - obj.beep_times_keys(trial_idx, 1, 1);
                        acceptance_end = acceptance_end - obj.beep_times_keys(trial_idx, 1, 1);

                        if obj.judge(trial_idx, 4*(loop - 1) + key) == 0
                            % 打鍵失敗区間を灰色で塗りつぶし
                            fill([acceptance_start, acceptance_end, acceptance_end, acceptance_start], ...
                                [6.5-key, 6.5-key, 5.5-key, 5.5-key], ...
                                [0.1, 0.1, 0.1], 'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');

                        elseif ~isnan(acceptance_start) && ~isnan(acceptance_end)
                            % 打鍵成功区間をそのキーに対応する色で塗りつぶし
                            fill([acceptance_start, acceptance_end, acceptance_end, acceptance_start], ...
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
                title(['Subject ' obj.participant_name ' block ' obj.num_block ' trial ' num2str(trial_idx)]);

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
                savefig(fullfile(output_folder, ['subject_' obj.participant_name '_block_' obj.num_block '_trial_' num2str(trial_idx) '_graph.fig']));
            end
        end
    end
end
