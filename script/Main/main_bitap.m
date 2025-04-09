% 20250127コード フォルダ内の全てのファイルを対象にするための設定とループ処理の追加
% 修正箇所: cfg.datapath の指定部分と、その後の処理全体をループ化

clear
addpath('C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc\all_level_src\add_basic_path\');
savepath % パスを保存する
addpath(genpath("../src/"));
addpath(genpath("C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc"));
cfg.device = "egi";
folderPath = "C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Results\20250114~ 予備実験4\20250220_Y416\EEGdata\mat\Main"; % フォルダパスを指定
fileList = dir(fullfile(folderPath, '*.mat')); % フォルダ内の.matファイルを取得

for fileIdx = 1:length(fileList)
    close all
    cfg.datapath = fullfile(folderPath, fileList(fileIdx).name); % 各.matファイルのパスを指定
    fprintf('Processing file: %s\n', cfg.datapath); % 処理中のファイル名を表示

    cfg.coi=36;

    % (2) 解析処理 (既存のコードをそのまま使用)
    data_eeg = EEGProcessor;
    data_eeg.epocher = Rest2TaskEpocher; %???
    data_eeg = data_eeg.processing(cfg);

    %% 以下、解析と可視化部分 (既存コードをそのまま使用)
    frqfiled = squeeze(data_eeg.frqfiled(:, 36, :));
    figure
    hold on
    for i_trl = 1:size(frqfiled, 2)
        tmp = frqfiled(:, i_trl);
        plot(tmp)
    end
    hold off

    %% PSD Main blockの場合
    figure;
    power = permute(squeeze(data_eeg.power(:, :, cfg.coi, :)), [2, 1, 3]);
    rest_power = reshape(power(:, 1:80, :), size(power, 1), []); % Rest時間
    hold on
    task_power = reshape(power(:, end-200:end, :), size(power, 1), []); % Task時間
    
    rest_power(:,isoutlier(nansum(rest_power,1),"median")) = [];
    task_power(:,isoutlier(nansum(task_power,1),"median")) = [];
    col_obj = ThesisColors;
    plotMat(task_power, col_obj.col(:, 2));
    plotMat(rest_power, col_obj.col(:, 1));
%%
    %% TF
    ersp_c3 = squeeze(median(data_eeg.ersp(:, :, cfg.coi, :), 4, "omitnan"));
    TFDrawer.draw(ersp_c3, size(ersp_c3, 1) / 10);

    %% Topo
    end_index = size(data_eeg.ersp, 1);
    start_index = end_index - 20 * 10 + 1;
    task_time_indices = start_index:end_index;
    % data_eeg.ersp(:, :, [114, 120], :) = NaN; % 修論審査用
    draw_ersp_topo(data_eeg.ersp, [8 13; 14 30], task_time_indices); % 修論審査用

    % 出力した図の保存
    save_all_fig('jpg', fullfile(folderPath, fileList(fileIdx).name));
end

fprintf('このフォルダの解析は終了しました\n\n');

%% 旧コード（単一matファイル解析用）
% clear
% close all
% add_basic_path
% addpath(genpath("../src/"));
% addpath(genpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc")); % 20250113に橋本がパスを追加
% 
% cfg.device="egi";
% cfg.datapath="\\nas-2023\NAS32\hashimoto2024_bi_tap\Results\20250125_Y407\EEGdata\mff\Y407_M1_20250125_110437.mat";
%  % 解析したい脳波データのパスを入力
% 
% cfg.coi=36;
% 
% data_eeg=EEGProcessor;
% data_eeg.epocher=Rest2TaskEpocher; %???
% data_eeg=data_eeg.processing(cfg);
% % % ref_win=15:50;
% % % data_eeg=data_eeg.calc_ersp(ref_win);
% 
% %% visualize for quality check
% % signal
% frqfiled=squeeze(data_eeg.frqfiled(:,36,:));
% figure
% hold on
% for i_trl=1:size(frqfiled,2)
%     tmp=frqfiled(:,i_trl);
%     plot(tmp)
% end
% hold off
% 
% % PSD Main blockの場合 (違う場合はコメントアウト)
% figure;
% power=permute(squeeze(data_eeg.power(:,:,cfg.coi,:)),[2,1,3]);
% rest_power=reshape(power(:,1:80,:),size(power,1),[]); % Restの時間(セル1つあたり100 ms)、trialの切り揃えを考慮して冒頭8.0秒間に設定
% hold on
% task_power=reshape(power(:,end-200:end,:),size(power,1),[]); % taskの時間(セル1つあたり100 ms)、末尾-20秒から末尾までの20秒間に設定
% col_obj=ThesisColors;
% plotMat(task_power,col_obj.col(:,2));
% plotMat(rest_power,col_obj.col(:,1));
% 
% % % PSD 開眼/閉眼安静の場合 (違う場合はコメントアウト)
% % figure;
% % power=permute(squeeze(data_eeg.power(:,:,cfg.coi,:)),[2,1,3]);
% % rest_power=reshape(power(:,10:end,:),size(power,1),[]); % Restの時間(セル1つあたり100 ms)、Rest提示から60秒間（冒頭の1秒は被験者の認知＆REST意識開始に要する時間として除外）
% % hold on
% % col_obj=ThesisColors;
% % plotMat(rest_power,col_obj.col(:,1));
% 
% % TF
% % data_eeg.ersp(data_eeg.ersp>500) = nan;
% ersp_c3=squeeze(median(data_eeg.ersp(:,:,cfg.coi,:),4, "omitnan"));
% TFDrawer.draw(ersp_c3,size(ersp_c3, 1)/10); % 二つ目の引数は、100msec単位で表されたersp_c3の時間をsec単位に直して入力
% 
% % Topo
% % 最後の20秒間(taskの時間)のインデックスを取得
% end_index = size(data_eeg.ersp,1);
% start_index = end_index - 20 * 10 + 1;
% task_time_indices = start_index:end_index;
% draw_ersp_topo(data_eeg.ersp,[8 13;14 30],task_time_indices);  % 好きな時間範囲を指定、foiにはデフォルト値を入力
% 
% % 出力した図の保存
% save_all_fig('jpg', cfg.datapath);