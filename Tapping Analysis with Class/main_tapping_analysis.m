clear
close all

%% 読み込むフォルダパスを指定
folder_path = "C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Results\20250114~ 予備実験4\20250206_Y413\tapping_data";

% 全ての打鍵解析を行う

% 各trialに1枚ずつの打鍵の時系列データのグラフを作成
aramaki_plot = GenerateAramakiPlot();
aramaki_plot.run_generate_aramaki_plot(folder_path);

% % 全blockで1枚の打鍵成功持続時間のtrial分布の箱ひげ図を作成
% S_D_plot = GenerateSuccessDurationGraph();
% S_D_plot.run_generate_Success_Duration_graph(folder_path);
% 
% % 全blockで1枚の打鍵成功率のtrial分布の箱ひげ図を作成
% S_R_plot = GenerateSuccessRateGraph();
% S_R_plot.run_generate_success_rate_graph(folder_path);
% 
% % 各Main blockで1枚の打鍵速度推移の折れ線グラフを作成
% S_L_graph = GenerateSpeedLevelGraph();
% S_L_graph.run_generate_speed_level_graph(folder_path);