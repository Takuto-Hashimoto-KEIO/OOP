clear
close all

KbName('UnifyKeyNames');
DisableKeysForKbCheck([240, 243, 244]);
Startup_SA;

% 設定を作成（beepパターンの作成も内包）
settings = ParameterSettings('12', 'B1', 1); % ()内は被験者番号、block番号、開始時の速度レベル(interval_index)

% 被験者への提示画面の準備
figure('Color', 'k', 'Position',[0.0010    0.0490    2.5600    1.3193]*500); % 黒色の背景を持つ新しい図を開く
axis off; % 軸を非表示にする
hold on;
pause(1);

%%% ここもクラス化すべき？
current_trial = 1; % 現在のtrial番号
speedchange = 0;
interval_index = settings.IntervalIndexAtStart;

for i = 1:settings.NumTrials
    trial = TrialMaster();
end








