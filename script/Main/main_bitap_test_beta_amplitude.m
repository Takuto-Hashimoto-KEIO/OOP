% 20250327 打鍵もつれ時のβ振幅について、全被験者についてランダムな時刻と比較する仮説検定を行うmain script

clear
close all

%% 必要なパスの追加
main_folder_path  = fileparts(mfilename('fullpath')); % このスクリプトのフォルダパスを絶対パスとして取得

addpath(fullfile(main_folder_path, '..', 'Processor')); % 'Processor' フォルダをパスに追加
addpath(fullfile(main_folder_path, '..', 'test')); % 'test' フォルダをパスに追加
disp('Processorフォルダとtestフォルダのパスを追加しました。');


%% 打鍵：読み込むフォルダパスの指定、→ Subject名_all_target～の.matファイルだけ読み出し
tapping_folder_path = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Processed_Results\Tapping";

%% 脳波：読み込むフォルダパスの指定、→ .matファイルだけ読み出し
EEG_folder_path = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Results\20250114~ 予備実験4"; % 脳波データのフォルダパスを指定


%% 保存先のパスの入力欄
 % 前処理した脳波データの保存先
 save_path1 = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Processed_Results\20250409 for_test";
 % 仮説検定の結果のデータと図の保存先
 save_path2 = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Analysis Result\20250409 amptitude_test N=21";


% %% 打鍵データから解析に必要なデータを取得、保存
% tap_data = GetTappingData();
% tap_data = tap_data.run(tapping_folder_path);
% 
% %% 脳波の下処理、保存
% % 脳波処理のための設定、配列の初期化
% cfg.device = "egi";
% cfg.coi=36; % 関心電極（空間フィルタをかける都合上、C3一つに限定）
% cfg.hpfrq = 2; cfg.lpfrq = 40; % バンドパスの周波数帯
% frqfiled_all = [];
% 
% % 脳波を解析可能な形にフィルタ処理、保存、関心trial以外の削除
% eeg_data = EEGdataProcessor();
% EEG_saved_path = eeg_data.run(cfg, EEG_folder_path, tap_data, save_path1);
% 
% cfg.coi=[36, 104]; % 関心電極（通常はC3,C4）

% %% 全被験者の打鍵もつれ時1秒窓のα or β振幅変化の検定
% test1 = Test1BetaAmplitudeAtMiss();
% EEG_saved_path = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Processed_Results\20250409 for_test\EEG"; % 仮置き
% save_path2 = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Analysis Result\20250411 amptitude_test1 N=21"; % 仮置き
% test1 = test1.run(cfg.coi, EEG_saved_path, tapping_folder_path, save_path2);

%% 全被験者の打鍵もつれ時1秒窓のα or β振幅変化の検定

%% 必要なパスの追加
% このscriptのパスを設定
this_folder_path  = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc\signal_processing\script\test\Test2AllChannelAmplitudeAtMiss.m"; % このスクリプトのフォルダパスを絶対パスとして取得
addpath(fullfile(this_folder_path, 'src')); % 'Processor' フォルダをパスに追加

%% データのロード、格納
[~, first_misstap_time_all_sbj, total_taget_trials, total_subjects] = load_tapping_data(tapping_folder_path); % 打鍵
EEG_saved_path = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Processed_Results\20250409 for_test\EEG"; % 仮置き
EEG_data_all_sbj = load_EEG_all_ch_data(EEG_saved_path, total_subjects); % EEG：全chのデータを取り出す

%% 検定
num_channnels = 129;
p_value_all_ch_beta = NaN(num_channnels, 1);

for i = 1:num_channnels % 1~129の電極について、順にp値を計算
    cfg.coi = i;
    test2 = Test2AllChannelAmplitudeAtMiss();

    save_path2 = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Analysis Result\20250411 all_channel_amptitude_test2 N=21"; % 仮置き
    p_value = test2.run(cfg.coi, EEG_data_all_sbj, first_misstap_time_all_sbj, total_taget_trials, total_subjects, save_path2);
    p_value_all_ch_beta(i, 1) = p_value;
    close all
end

save(fullfile(save_path2, sprintf('p_value_all_ch_beta.mat')), 'p_value_all_ch_beta');