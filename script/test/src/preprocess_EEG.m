function eeg_data = preprocess_EEG(eeg_data)
% === 包絡線の計算関数 ===
compute_envelope = @(x) abs(hilbert(x)); % ヒルベルト変換を用いた包絡線(1次元目の時間方向)

% 1. NaNの位置を0で埋める & 0で埋めた場所を記録
nan_mask = isnan(eeg_data); % NaNの位置を記録
eeg_data(nan_mask) = 0; % NaNを0で埋める

% 2. Hilbert変換
eeg_data = compute_envelope(eeg_data); % 先にヒルベルト変換

% 3. 0で埋めた場所をNaNに戻す
eeg_data(nan_mask) = NaN;
end