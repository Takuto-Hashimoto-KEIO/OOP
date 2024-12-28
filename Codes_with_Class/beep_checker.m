% このコードは、波形を図に描写することで、ビープの音源が正しく生成されているかを確認する
TapIntervalList = [1/2, 1/2.3, 1/2.6, 1/2.9, 1/3.2, 1/3.5, 1/3.9, 1/4.3, 1/4.7, 1/5.2, 1/5.7];
beepPatterns = generateAllBeepPatterns(TapIntervalList);

% サンプルレート（Hz）
sampleRate = 44100;

% beepPatternsの1つ目のパターンを取得
patternIndex = 1; % 観察したいビープ速度のインデックスを入力
if patternIndex <= length(beepPatterns)
    signal = beepPatterns{patternIndex};

    % 時間軸の作成
    t = (0:length(signal)-1) / sampleRate;

    % 波形のプロット
    figure;
    plot(t, signal);
    xlabel('時間 (秒)');
    ylabel('振幅');
    title(['Beep Pattern ', num2str(patternIndex)]);
    grid on;
else
    disp('指定されたパターンが存在しません。');
end

%% ビープ音のパターン生成
function beepPatterns = generateAllBeepPatterns(TapIntervalList)

frequency = 500; % 周波数
beepDuration = 0.03; % 長さ（秒）
sampleRate = 44100; % サンプリングレート

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