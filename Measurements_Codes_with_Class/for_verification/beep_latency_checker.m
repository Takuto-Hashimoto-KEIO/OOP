% 必要なライブラリの初期化
InitializePsychSound(1);

% 再生に必要な変数を準備
sampleRate = 44100; % サンプリングレート（Hz）
interval_index = 1; % 再生するビープパターンのインデックス（例）
all_patterns = generateAllBeepPatterns(TapIntervalList, sampleRate); % ビープ音のパターン生成関数を呼び出す
pattern_signal = all_patterns{interval_index}; % 指定されたパターンを取得

% PsychPortAudio の初期化と設定
deviceID = 0; % デフォルトデバイス
pahandle = PsychPortAudio('Open', deviceID, 1, 1, sampleRate, 1); % 出力設定

% 信号が1次元の場合はモノラルとして2次元に変換
if size(pattern_signal, 1) == 1
    pattern_signal = [pattern_signal; pattern_signal]; % 2行に複製
end

% パターン信号をバッファにロード
PsychPortAudio('FillBuffer', pahandle, pattern_signal);

% 再生開始直前の現在時刻を記録
beep_start_time = GetSecs;

% 再生開始タイムスタンプを取得
start_time = PsychPortAudio('Start', pahandle, 1, 0, 1); % 再生を開始

% もう一度現在時刻を取得して確認
current_time = GetSecs;

% 再生終了を待機
PsychPortAudio('Stop', pahandle, 1); % 再生終了

% タイムスタンプの確認
if start_time == 0
    warning('再生開始時刻が正しく取得できませんでした。タイミング確認を再試行してください。');
else
    fprintf('再生遅延: %.6f 秒\n', start_time - beep_start_time);
    fprintf('現在時刻との差: %.6f 秒\n', start_time - current_time);
end

% リソースを解放
PsychPortAudio('Close', pahandle); % ハンドルを閉じる


%% ビープ音のパターン生成関数
function beepPatterns = generateAllBeepPatterns(TapIntervalList, sampleRate)

frequency = 500; % 周波数
beepDuration = 0.03; % 長さ（秒）

beepPatterns = cell(1, length(TapIntervalList));
for idx = 1:length(TapIntervalList)
    interval = TapIntervalList(idx);
    totalDuration = 20 + 8.5 * interval; % 全体の長さ
    tBeep = linspace(0, beepDuration, round(beepDuration * sampleRate));
    beepSignal = sin(2 * pi * frequency * tBeep);

    % フェードイン・アウト適用
    fadeDuration = round(0.1 * length(beepSignal));
    fadeIn = linspace(0, 1, fadeDuration);
    fadeOut = linspace(1, 0, fadeDuration);
    beepSignal(1:fadeDuration) = beepSignal(1:fadeDuration) .* fadeIn;
    beepSignal(end-fadeDuration+1:end) = beepSignal(end-fadeDuration+1:end) .* fadeOut;

    % パターン生成
    patternSignal = zeros(1, round((interval / 2) * sampleRate));
    currentTime = interval / 2;
    while currentTime < totalDuration
        patternSignal = [patternSignal, beepSignal];
        silenceDuration = interval - beepDuration;
        if silenceDuration > 0
            silenceSignal = zeros(1, round(silenceDuration * sampleRate));
            patternSignal = [patternSignal, silenceSignal];
        end
        currentTime = currentTime + interval;
    end
    beepPatterns{idx} = patternSignal;
end
end
