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

% % 被験者へのMain Block開始の提示
% text(0.5, 0.5, 'Main Block', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色の"Main Block"を表示
% % sendCommand(daq,1); % main block開始
% pause(3); % 3秒間待機
% cla;

% 各trialの実行
trial = TrialMaster(settings); %A% ここでsettingまるごと入れていいの？ →　仕方ない

% for current_trial = 1:settings.NumTrials
for current_trial = 1:3
    trial = trial.run_trial(current_trial);
    % 1trial終了時の判定を行うオブジェクトを作る

    %%% trial.ResultsをReultsに入れなおす必要ある？ → ない
end

% [検証用]
ListenChar(0) % キーボード入力をすべてMATLABのコマンドウィンドウから遮断の解除
text(0.5, 0.5, 'Executed to thjeifjeie end', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
pause(3); % 3秒間待機








