data = tap_end_hand_rate_per_sbj*100;

% setup library and create instance
addpath("C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\tutorial-create-figure");
setup_lib_visualize_data;

% 現在開いているFigureの一覧を取得（関数内で作成したものを識別するため）
existingFigures = findall(0, 'Type', 'figure');

f = vi.figure();
obj_box = vi.notBoxPlot(data);
vi.moduBoxplot(obj_box, 8, [0, 0.4471, 0.7412]'); % 全プロットを青色に統一 第3引数にカラーを指定（青色）
size_font = 16;
vi.set_fig(4,size_font); % 入力一つ目に4を指定すると、軸ラベルをつけない,
vi.set_position(1);
% ラベルを設定（フォント指定）
vi.set_label('', 'right hand tap miss rate (%)');

% 横軸の目盛ラベルを削除
xticklabels([]);

% タイトルを追加（フォント指定）
title(sprintf('各被験者のもつれ手のうち右手が占める割合（N=%d）', size(data,1)), ...
    'FontName', 'Helvetica');