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

current_trial = 1; % 現在のtrial番号
speedchange = 0;
interval_index = settings.IntervalIndexAtStart;

% Pretaskフォルダにパスをつなぐ
addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\PreTask");

% 速度変更、Rest、Readyの提示までを一括で行う
% speed_changer = SpeedChangeToReady(speedchange, current_trial);
%%% speed_changeをどこに保存する？(objectがたくさんになり、内容が重複して管理しきれない)
% speed_changer = speed_changer.trialStartToTask(); %%% なぜ()内にspeed_changerは不要なのか？

% ビープ音の提示開始
% beep_start_time = GetSecs;
beep_player = Beep_Player();
beep_player.play_beep_pattern(settings.BeepPatterns, interval_index);

% ビープ音の提示開始時刻を保存
settings.Results.beep_start_times(current_trial) = beep_player.getBeepStartime();

% 2ループで速度提示（黄色数字）
rhythm_presenter = RhythmPresenter(0.5, settings.Results.beep_start_times(current_trial)); %% 0.5は要変更
%%% いちいちsettingから引数を出さず、このスクリプト内で変数を出した方がいい？
rhythm_presenter.keystrokeSpeedPrompter();