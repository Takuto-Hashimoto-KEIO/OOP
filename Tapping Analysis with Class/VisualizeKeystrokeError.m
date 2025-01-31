classdef VisualizeKeystrokeError
    properties
        participant_name
        block_type
        num_block

        num_trials
        num_keys
        tap_intervals

        beep_times_keys
        keystrokes
        corrected_pressed_times
        judge

        acceptance_start
        acceptance_end
    end

    methods
        function obj = VisualizeKeystrokeError(data)
            % データを抽出
            obj.participant_name = data.participant_name;
            obj.num_block = data.num_block;
            obj.block_type = data.block_type;

            obj.beep_times_keys = data.beep_times_keys;
            obj.corrected_pressed_times = data.corrected_pressed_times;
            obj.judge = data.judge;
            obj.num_trials = data.num_trials;
            obj.num_keys = data.num_keys;
            obj.keystrokes = data.keystrokes;

            obj.acceptance_start = data.acceptance_start;
            obj.acceptance_end = data.acceptance_end;
        end

        % VisualizeKeystrokeErrorの全機能を一貫して実行
        function run_visualize_keystroke_error(obj, folder_path)

            % obj.acceptance_startとobj.acceptance_endの次元を削減
            num_keystroke_sections = obj.keystrokes.num_keystroke_sections;
            [obj.acceptance_start, obj.acceptance_end] = dimensional_reducer(obj, num_keystroke_sections);

            plot_summary(obj, folder_path);
        end

        function plot_summary(obj, folder_path)
            figure;
            hold on;
            colors = {'k', 'b', [0, 0.5, 0], 'r'}; % 成功:黒, 遅れ:青, 先行:鈍い緑, 飛ばし:赤
            legend_labels = {'\color{black} \bullet Success', ...
                '\color{blue} \bullet Delayed', ...
                '\color[rgb]{0, 0.5, 0} \bullet Early', ...
                '\color{red} \circ Skipped'};

            for trial_idx = 1:obj.num_trials

                % このtrialでの打鍵判定区間のリストを格納
                a_starts = sort(obj.acceptance_start(trial_idx, :));
                a_ends = sort(obj.acceptance_end(trial_idx, :));

                t_n = cell(obj.keystrokes.num_keystroke_sections(trial_idx),1);
                all_press_per_key = cell(obj.num_keys,1);

                % 1打鍵判定区間ごとにプロットする押し下し時刻などの準備
                for loop_idx = 1:obj.keystrokes.num_loops(trial_idx)
                    for key_idx = 1:obj.num_keys

                        % 打鍵番号
                        keystorke_idx = 4*(loop_idx - 1) + key_idx;

                        % 到達した打鍵判定区間以降は、obj.judgeにNaNが格納されているため処理を行わない
                        if obj.keystrokes.num_keystroke_sections(trial_idx) < keystorke_idx
                            break;
                        end

                        % 今回のキーを押した時刻を全て取得
                        all_press_per_key{key_idx} = squeeze(obj.corrected_pressed_times(trial_idx, key_idx, :));
                        all_press_per_key{key_idx} = all_press_per_key{key_idx}(all_press_per_key{key_idx} ~= 0); % ちょうど0の要素を削除

                        % % 検証用
                        % zero_indices = find(all_press_per_key == 0);
                        % if ~isempty(zero_indices)
                        %     disp(zero_indices);
                        % end

                        % 今回の打鍵判定区間の中にあるキー押し下し時刻だけを格納
                        filtered_press_times = all_press_per_key{key_idx};
                        t_n{keystorke_idx} = filtered_press_times(filtered_press_times >= a_starts(keystorke_idx) & filtered_press_times <= a_ends(keystorke_idx));
                    end
                end

                % 1打鍵判定区間ごとにプロット
                for loop_idx = 1:obj.keystrokes.num_loops(trial_idx)
                    for key_idx = 1:obj.num_keys

                        % 打鍵番号
                        keystorke_idx = 4*(loop_idx - 1) + key_idx;

                        % 到達した打鍵判定区間以降は、obj.judgeにNaNが格納されているため処理を行わない
                        if obj.keystrokes.num_keystroke_sections(trial_idx) < keystorke_idx
                            break;
                        end

                        % [検証用]
                        zero_indices = find(t_n{keystorke_idx} == 0);
                        if numel(zero_indices) ~= 0
                            disp(zero_indices);
                        end

                        all_press_per_key_idx = all_press_per_key{key_idx};

                        % 最初と最後の打鍵判定区間についてはプロットしない（配列の仕様の都合上）
                        if keystorke_idx ~= 1 && keystorke_idx ~= obj.keystrokes.num_keystroke_sections(trial_idx)
                            % 打鍵を1打鍵判定区間ごとに分類してプロット（キー押し下し開始時刻のみ）
                            if obj.judge(trial_idx, keystorke_idx) == 1 % 打鍵成功
                                plot(t_n{keystorke_idx}, trial_idx * ones(1, size(t_n{keystorke_idx}, 1)), 'o', 'Color', colors{1}, 'MarkerFaceColor', colors{1});

                            % 注意：成功判定の場合は、その前後の押し下しはプロットされない
                            elseif any(a_ends(keystorke_idx) < all_press_per_key_idx & all_press_per_key_idx <= a_ends(keystorke_idx + 1)) % 打鍵遅れ
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
            yticks(1:obj.num_trials);
            title([obj.participant_name ' ' 'Block Summary： ' obj.block_type ' block ' num2str(obj.num_block)]);
            % legend(legend_labels, 'Location', 'best');
            % legend(legend_labels, 'Location', 'northeast', 'AutoUpdate', 'off');
            
            lgd = legend(legend_labels, 'Location', 'northeast', 'AutoUpdate', 'off');

            % 凡例をさらに上に移動
            lgd.Position(2) = lgd.Position(2) + 0.05; % Y方向に少し上げる

            fontsize(36,"points")
            hold off;
            
            output_folder = fullfile(folder_path, 'Keystroke_Block_Summary');
            if ~exist(output_folder, 'dir')
                mkdir(output_folder);
            end
            savefig(fullfile(output_folder, ['subject_' obj.participant_name '_block_summary_' obj.block_type '_block_' num2str(obj.num_block) '.fig']));
        end
    end

    methods (Access = private)
        % obj.acceptance_startとobj.acceptance_endの2,3次元を合わせて次元削減
        function [acceptance_start_reduced, acceptance_end_reduced] = dimensional_reducer(obj, num_keystroke_sections)
            % 次元削減後の配列の初期化
            acceptance_start_reduced = NaN(obj.num_trials, max(num_keystroke_sections));
            acceptance_end_reduced = NaN(obj.num_trials, max(num_keystroke_sections));

            % 変換処理
            for trial_idx = 1:obj.num_trials
                for loop = 1:obj.keystrokes.num_loops(trial_idx)
                    for key = 1:obj.num_keys
                        keystroke_idx = 4 * (loop - 1) + key; % 打鍵番号の計算

                        % 打鍵番号が有効範囲内か確認
                        if keystroke_idx > num_keystroke_sections(trial_idx)
                            break;
                        end

                        % 新しい配列に格納
                        acceptance_start_reduced(trial_idx, keystroke_idx) = obj.acceptance_start(trial_idx, loop, key);
                        acceptance_end_reduced(trial_idx, keystroke_idx) = obj.acceptance_end(trial_idx, loop, key);
                    end
                end
            end
        end
    end
end
