% 既存のMATファイルを編集して保存するスクリプト

% 1. ファイル名を指定
filename = "C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Results\20250114~ 予備実験4\20250206_Y413\tapping_data\Block_Result_Y413_M_block5_20250206_160905.mat";  % 必要なら新しいファイル名を指定（同じにすると上書き）

% 2. ファイルを読み込む
data = load(filename);

% 3. データを編集
% 例: 既存の変数を編集
if isfield(data, 'num_block')  % 'existing_variable'が存在するか確認
    data.num_block = '5';  % 値を変更
else
    disp('num_blockが存在しません。');
end

% % 例: 新しい変数を追加
% data.new_variable = rand(10, 1);

% 4. 編集内容を保存
save(filename, '-struct', 'data');  % 上書きする場合は 'filename' を使用

disp(['ファイルが保存されました: ', filename]);
