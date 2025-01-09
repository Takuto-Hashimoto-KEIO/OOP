% 打鍵時系列データが正しく記録されているかを図で可視化

% データの準備
pressed_times = trial.Results.pressed_times; % 配列 (20×4×18000)
a = pressed_times(pressed_times ~= 0);

% 0を白、値がある場所を黒に変換
binary_data = pressed_times > 0; % 0以外の要素を1、0の要素を0にする

% 可視化のための行列を展開 (20×(4×11000)に変換)
visual_data = reshape(permute(binary_data, [1, 3, 2]), 20, []); 

% 図の描画
figure;
imagesc(~visual_data); % 白黒反転（0:白、1:黒）
colormap(gray); % グレースケールのカラーマップ
colorbar; % カラーバーを表示
xlabel('Columns (4×11000)'); % 列方向のラベル
ylabel('Rows (Trials)'); % 行方向のラベル
title('Pressed Times Visualization'); % タイトルの追加