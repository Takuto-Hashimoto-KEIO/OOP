classdef PlotMissedKeystrokes
    %PLOTMISSEDKEYSTROKES このクラスの概要をここに記述
    %   詳細説明をここに記述

    properties
        data
        success_duration_end
        output_folder
    end

    methods
        function obj = PlotMissedKeystrokes()
            %PLOTMISSEDKEYSTROKES このクラスのインスタンスを作成
        end

        % PlotMissedKeystrokesの全体を一貫して実行
        function obj = run_plot_missed_keystrokes(obj, data_from_sort_missed_keystrokes, folder_path)
            obj.data = data_from_sort_missed_keystrokes;
            obj = detect_success_duration_end(obj);
            obj = plot_summary(obj, folder_path);
        end

        % 打鍵成功持続時間の最後の成功打鍵の取得
        function obj = detect_success_duration_end(obj)
            obj.success_duration_end = NaN(obj.data.num_all_trials, 1);

            for trial_idx = 1:obj.data.num_all_trials
                % 現在のtrialにおいて、成功した打鍵（judgeが1）のインデックスを取得
                success_indices = find(obj.data.judge(trial_idx, :) == 1);

                if ~isempty(success_indices)
                    first_success = success_indices(1); % 最初の成功インデックスを取得

                    % 最初の成功インデックスに基づいて、task開始～最初の打鍵成功までの時間(秒)を一時計算
                    temp_duration = (first_success / obj.data.keystrokes.num_keystroke_sections) * 20; % 20はtrial_task_time（秒）

                    % temp_durationが3秒より大きい場合は、obj.success_duration_endを強制的に0とする（最初の打鍵成功が遅すぎるため）
                    if temp_duration > 3
                        obj.success_duration_end(trial_idx) = 0;
                    else % 成功した打鍵が存在する場合のみ処理を進める

                        % もしミスを挟んだ成功打鍵のペアが見つからない場合、最後の成功打鍵を末尾の成功インデックスとする
                        if isempty(success_indices(find(diff(success_indices) ~= 1, 1, 'first')))
                            obj.success_duration_end(trial_idx) = success_indices(end); % 連続成功が末尾まで続いた場合
                        else
                            % 最初の成功打鍵以降、連続した成功が途切れる直前の最後の成功打鍵の番号を取得
                            obj.success_duration_end(trial_idx) = success_indices(find(diff(success_indices) ~= 1, 1, 'first'));
                        end
                    end
                end
            end
        end

        function obj = plot_summary(obj, folder_path)
            figure;
            hold on;
            colors = {[0.5, 0.5, 0.5], 'b', [0, 0.5, 0], 'r', 'y'}; % 成功:黒, 遅れ:青, 先行:鈍い緑, 飛ばし:赤, 打鍵成功持続時間の最後の成功打鍵：黄
            legend_labels = {'\color{black} \bullet Success', ...
                '\color{blue} \bullet Delayed', ...
                '\color[rgb]{0, 0.5, 0} \bullet Early', ...
                '\color{red} \circ Skipped'};

            for trial_idx = 1:obj.data.num_all_trials

                % このtrialでの打鍵判定区間のリストを格納
                a_starts = obj.data.acceptance_start(trial_idx, :);
                a_ends = obj.data.acceptance_end(trial_idx, :);

                t_n = cell(obj.data.keystrokes.num_keystroke_sections(trial_idx),1);
                all_press_per_key = cell(obj.data.num_keys,1);

                % 1打鍵判定区間ごとにプロットする押し下し時刻などの準備
                for loop_idx = 1:obj.data.keystrokes.num_loops(trial_idx)
                    for key_idx = 1:obj.data.num_keys

                        % 打鍵番号
                        keystorke_idx = 4*(loop_idx - 1) + key_idx;

                        % 到達した打鍵判定区間以降は、obj.judgeにNaNが格納されているため処理を行わない
                        if obj.data.keystrokes.num_keystroke_sections(trial_idx) < keystorke_idx
                            break;
                        end

                        % 今回のキーを押した時刻を全て取得
                        all_press_per_key{key_idx} = squeeze(obj.data.corrected_pressed_times(trial_idx, key_idx, :));
                        all_press_per_key{key_idx} = all_press_per_key{key_idx}(all_press_per_key{key_idx} ~= 0); % ちょうど0の要素を削除

                        % 今回の打鍵判定区間の中にあるキー押し下し時刻だけを格納
                        filtered_press_times = all_press_per_key{key_idx};
                        t_n{keystorke_idx} = filtered_press_times(filtered_press_times >= a_starts(keystorke_idx) & filtered_press_times <= a_ends(keystorke_idx));
                    end
                end

                % 1打鍵判定区間ごとにプロット
                for loop_idx = 1:obj.data.keystrokes.num_loops(trial_idx)
                    for key_idx = 1:obj.data.num_keys

                        % 打鍵番号
                        keystorke_idx = 4*(loop_idx - 1) + key_idx;

                        % 到達した打鍵判定区間以降は、obj.judgeにNaNが格納されているため処理を行わない
                        if obj.data.keystrokes.num_keystroke_sections(trial_idx) < keystorke_idx
                            break;
                        end

                        % [検証用]
                        zero_indices = find(t_n{keystorke_idx} == 0);
                        if numel(zero_indices) ~= 0
                            disp(zero_indices);
                        end

                        all_press_per_key_idx = all_press_per_key{key_idx};

                        % 打鍵を1打鍵判定区間ごとに分類してプロット（キー押し下し開始時刻のみ）
                        % 最初と最後の打鍵判定区間についてはプロットしない（配列の仕様の都合上）
                        if keystorke_idx ~= 1 && keystorke_idx ~= obj.data.keystrokes.num_keystroke_sections(trial_idx)

                            if obj.data.judge(trial_idx, keystorke_idx) == 1 % 打鍵成功
                                plot(t_n{keystorke_idx}, trial_idx * ones(1, size(t_n{keystorke_idx}, 1)), 'o', 'Color', colors{1}, 'MarkerFaceColor', colors{1});
                                if keystorke_idx == obj.success_duration_end(trial_idx)
                                    fill([a_starts(keystorke_idx), a_ends(keystorke_idx), a_ends(keystorke_idx), a_starts(keystorke_idx)], ...
                                        [trial_idx+0.5, trial_idx+0.5, trial_idx-0.5, trial_idx-0.5], ...
                                        colors{5}, 'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');
                                end

                            % 注意：成功判定の場合は、その前後の押し下しはプロットされない
                            elseif obj.data.classified_keystrokes(trial_idx, keystorke_idx) == 1 % 打鍵遅れ
                                late_presses = all_press_per_key_idx(a_ends(keystorke_idx) <  all_press_per_key_idx & all_press_per_key_idx <= a_ends(keystorke_idx + 1));
                                fill([a_starts(keystorke_idx), a_ends(keystorke_idx), a_ends(keystorke_idx), a_starts(keystorke_idx)], ...
                                    [trial_idx+0.5, trial_idx+0.5, trial_idx-0.5, trial_idx-0.5], ...
                                    colors{2}, 'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');
                                plot(late_presses, trial_idx * ones(1, size(late_presses, 1)), 'o', 'Color', colors{2}, 'MarkerFaceColor', colors{2});

                                if any(a_starts(keystorke_idx - 1) <= all_press_per_key_idx & all_press_per_key_idx < a_starts(keystorke_idx)) % 打鍵先行
                                    fast_presses = all_press_per_key_idx(a_starts(keystorke_idx - 1) <= all_press_per_key_idx & all_press_per_key_idx < a_starts(keystorke_idx));
                                    fill([a_starts(keystorke_idx), a_ends(keystorke_idx), a_ends(keystorke_idx), a_starts(keystorke_idx)], ...
                                        [trial_idx+0.5, trial_idx+0.5, trial_idx-0.5, trial_idx-0.5], ...
                                        colors{3}, 'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');
                                    plot(fast_presses, trial_idx * ones(1, size(fast_presses, 1)), 'o', 'Color', colors{3}, 'MarkerFaceColor', colors{3});
                                end

                            else % 打鍵飛ばし
                                % plot(t_n{keystorke_idx}, trial_idx, 'o', 'Color', colors{4}, 'MarkerFaceColor', colors{4});
                                fill([a_starts(keystorke_idx), a_ends(keystorke_idx), a_ends(keystorke_idx), a_starts(keystorke_idx)], ...
                                    [trial_idx+0.5, trial_idx+0.5, trial_idx-0.5, trial_idx-0.5], ...
                                    colors{4}, 'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');
                            end

                            % 各打鍵判定区間の中央の時刻に直線を引く
                            a_center = (a_starts(keystorke_idx) + a_ends(keystorke_idx)) / 2; % 平均値を計算
                            plot([a_center, a_center], [trial_idx+0.5, trial_idx-0.5], 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1.5, 'HandleVisibility', 'off'); % 灰色の直線を描画
                        end
                    end
                end
            end

            xlabel('Time (sec)');
            ylabel('Trials');
            yticks([1, 10:10:obj.data.num_all_trials]); % y軸のラベルを1, 10, 20, ... のみに設定
            title([obj.data.participant_name ' ' 'Sorted all ' num2str(obj.data.num_all_trials) ' trials ' num2str(obj.data.speed_levels(1)) ' Hz']);
            % legend(legend_labels, 'Location', 'best');
            % legend(legend_labels, 'Location', 'northeast', 'AutoUpdate', 'off');
            
            lgd = legend(legend_labels, 'Location', 'northeast', 'AutoUpdate', 'off');

            % 凡例をさらに上に移動
            lgd.Position(2) = lgd.Position(2) + 0.05; % Y方向に少し上げる

            fontsize(36,"points")
            hold off;

            obj.output_folder = fullfile(folder_path, 'Keystroke_Block_Summary');
            if ~exist(obj.output_folder, 'dir')
                mkdir(obj.output_folder);
            end

            % 保存ファイル名を定義
            fig_filename_fig = fullfile(obj.output_folder, ['subject_' obj.data.participant_name '_sorted_all_trials.fig']);
            fig_filename_jpg = fullfile(obj.output_folder, ['subject_' obj.data.participant_name '_sorted_all_trials.jpg']);

            saveas(gcf, fig_filename_fig, 'fig');  % .fig形式で保存

            fig = gcf;
            fig.Units = 'normalized';
            fig.OuterPosition = [0 0 1 1]; % 全画面表示
            drawnow; % 画面更新を強制
            pause(0.1);
            
            saveas(gcf, fig_filename_jpg, 'jpg');  % .jpg形式で保存
        end
    end
end
