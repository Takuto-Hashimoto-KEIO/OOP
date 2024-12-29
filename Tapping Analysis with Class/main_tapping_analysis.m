clear
close all

%% 読み込むフォルダパスを指定
folder_path = "C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\Results\20241229_Self4";

%% 全ての打鍵解析を行う
aramaki_plot = GenerateAramakiPlot();
aramaki_plot.run_generate_aramaki_plot(folder_path);

S_D_plot = GenerateSuccessDurationGraph();
S_D_plot.run_generate_Success_Duration_graph(folder_path);

% generate_Success_Rate_gragh(folder_path);
% 
% generate_line_graph_of_speed_level(folder_path);