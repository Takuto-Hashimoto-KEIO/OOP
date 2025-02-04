clear
close all

%% 読み込むフォルダパスを指定
folder_path = "\\nas-2023\NAS32\hashimoto2024_bi_tap\Results\20250202_Y409\tapping_data\Block_Result_Y409_M_block1_20250202_110415.mat";

%% 全ての打鍵解析を行う

% VisualizeKeystrokeErrorだけを実行し、1blockに1枚ずつの打鍵の時系列データのグラフを作成
aramaki_plot = GenerateAramakiPlot();
aramaki_plot.run_generate_aramaki_plot(folder_path);