% 20250411 全被験者の打鍵もつれ時の全電極のα,β振幅について、ランダムな時刻と比較したp値をtopoにプロットするmain script

close all

%% 必要なパスの追加
main_folder_path  = fileparts(mfilename('fullpath')); % このスクリプトのフォルダパスを絶対パスとして取得

addpath(fullfile(main_folder_path, '..', 'Processor')); % 'Processor' フォルダをパスに追加
addpath(fullfile(main_folder_path, '..', 'test')); % 'test' フォルダをパスに追加
disp('Processorフォルダとtestフォルダのパスを追加しました。');

%% α,β振幅のp値を統合
% ここで一時停止し、ワークスペースに対象となるデータを手動でロード
p_values_2_bands = [p_value_all_ch_alpha, p_value_all_ch_beta]; % 129×2の配列にまとめる
draw_p_values_topo(p_values_2_bands); % TOPOの描画

%% 図の保存
save_path = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Analysis Result\20250411 all_channel_amptitude_test2 N=21"; % 保存先のパスを指定

% 出力した図の保存
figHandles = findall(0, 'Type', 'figure'); % 開いている全てのfigureを取得

for i = 1:length(figHandles)
    fig = figHandles(i);
    figure(fig); % アクティブ化
    % fig.Units = 'normalized';
    % fig.OuterPosition = [0 0 1 1]; % 全画面表示
    % fig.Units = 'normalized';
    % fig.OuterPosition = [0.25 0 0.5 1]; % 縦長の設定
    drawnow; % 画面更新を強制
    pause(0.05); % 描画の安定のための一時停止

    % 保存ファイル名の作成（番号は逆順に）
    baseFileName = sprintf('p_values_TOPO_alpha_and_beta_fig%02d', length(figHandles)-i+1);

    saveFileNamePNG = fullfile(save_path, [baseFileName, '.png']);
    saveFileNameMAT = fullfile(save_path, [baseFileName, '.mat']);

    % 図を保存（例: 'figure1.png', 'figure2.png', ...）
    saveas(fig, saveFileNamePNG);
    f = fig; % 不要な警告を避けるため
    save(saveFileNameMAT, 'f');
end