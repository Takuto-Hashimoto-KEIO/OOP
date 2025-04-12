function draw_p_values_topo(p_values_2_bands,foi)
arguments
    p_values_2_bands
    foi  =[8 13;14 30];
end

% パスをつなぐ
addpath('C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc\all_level_src\add_basic_path\');
savepath % パスを保存する
addpath(genpath("../src/"));
addpath(genpath("C:\Users\takut\OneDrive\ドキュメント\Hashimoto\元Onedrive\牛場研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\EEG_Analysis\eeg_analysis-main\src\gsrc"));

num_band = size(foi,2);
figure('Position', [1000,715,1455,523],'Color', [1 1 1]);
legend_band={"Alpha","Beta"};
title_col=[64,64,64]/255;
for i_band = 1 : num_band
    subplot(1,num_band,i_band);
    %f{i_band} = figure;
    p_values = p_values_2_bands(:,i_band);


    % % カラーマップの取得（オリジナルのまま）
    % cm = get_cmap("rdbu");
    % 
    % % --- カラーマップ加工：0〜0.1を青系、0.9〜1を赤系、それ以外は白 ---
    % % 長さを確認
    % n_cm = size(cm,1);
    % 
    % % カラーマップインデックス作成
    % p_range = linspace(0,1,n_cm);
    % 
    % % 色のマスク作成
    % % blue_mask  = p_range >= 0.95;
    % % red_mask = p_range <= 0.05;
    % % blue_mask  = p_range >= 0.9;
    % % red_mask = p_range <= 0.1;
    % blue_mask  = p_range >= 0.8;
    % red_mask = p_range <= 0.2;
    % white_mask = ~(blue_mask | red_mask);
    % 
    % % 青・赤・白のRGB値を定義
    % blue_base  = [0 0.2 0.7];   % 青
    % red_base = [0.7 0 0];     % 赤
    % white_base = [1 1 1];      % 白
    % 
    % % 青グラデーション（0.9〜1）打鍵もつれ時に振幅が減少（REST時の平均振幅から遠ざかる）
    % n_blue = sum(blue_mask);
    % blue_grad = [linspace(white_base(1), blue_base(1), n_blue)', ...
    %     linspace(white_base(2), blue_base(2), n_blue)', ...
    %     linspace(white_base(3), blue_base(3), n_blue)'];
    % 
    % % 赤グラデーション（0〜0.1）打鍵もつれ時に振幅が増加（REST時の平均振幅に近づく）
    % n_red = sum(red_mask);
    % red_grad = [linspace(red_base(1), white_base(1), n_red)', ...
    %     linspace(red_base(2), white_base(2), n_red)', ...
    %     linspace(red_base(3), white_base(3), n_red)'];
    % 
    % % 白（0.1〜0.9）
    % n_white = sum(white_mask);
    % white_grad = repmat(white_base, n_white, 1);
    % 
    % % 最終的なカラーマップを構築
    % cm_custom = zeros(n_cm, 3);
    % cm_custom(red_mask,:) = red_grad;
    % cm_custom(white_mask,:) = white_grad;
    % cm_custom(blue_mask,:) = blue_grad;
    % 
    % % --- トポ図描画 ---
    % fcn_drawTopo(p_values, 1:numel(p_values), 36);  % ROIは36（C3）不要な場合は空で
    % colormap(cm_custom);                    % 加工済カラーマップを適用
    % clim([0 1]);                           % p値スケール固定
    % set_cb('p-value', 10, -1);             % カラーバー追加


    fcn_drawTopo(p_values,1:numel(p_values),36);
    set_cb('p value',10,-1);% N% color bar scale ラベルの種類、フォントサイズ、上限値関連の数

    title(sprintf('%s, %d-%d [Hz]',legend_band{i_band},foi(i_band,1),foi(i_band,2)),"FontWeight","bold","FontSize",17,"Color",title_col); % [通常用]
end
cm=get_cmap("rdbu");
% colormap(cm);
colormap(flipud(cm)); % 赤青の反転
end