clear
close all

KbName('UnifyKeyNames');
DisableKeysForKbCheck([240, 243, 244]);

% Setupフォルダにパスをつなぐ
addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\Setup");

Startup_SA;

% 設定を作成（beepパターンの作成も内包）
settings = ParameterSettings('Self', '1', 'S', 1); % ()内は被験者番号、block番号、blockの種類｛S, P, M｝、開始時の速度レベル(interval_index)

% 被験者への提示画面の準備
figure('Color', 'k', 'Position', [0.0010    0.0490    2.5600    1.3193]*500); % 黒色の背景を持つ新しい図を開く
axis off; % 軸を非表示にする
hold on;
pause(1);

% 被験者へのBlock開始の提示
block_start_notifier(settings.block_type);
% sendCommand(daq,1); % block開始
pause(3); % 3秒間待機
cla;

% 各trial&各task終了後の打鍵解析の実行
trial = TrialMaster(settings); %A% ここでsettingまるごと入れていいの？ →　仕方ない

% Pretask, Task, PostTaskフォルダにパスをつなぐ
addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\PreTask");
addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\Task");
addpath("C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\20241205 codes with Class\Measurements\Codes_with_Class\PostTask");

for current_trial = 1:settings.NumTrials
    % for current_trial = 1:6 % 仮で少ないtrialだけ回すときの[検証用]

    % trial開始～終了までを実行（1taskごとの打鍵判定処理を内包）
    trial = trial.run_trial(current_trial);

    % 速度調節Screening1のみでの終了処理
    if settings.block_type == 'S'
        if trial.screening1_terminater == 1
            break;
        end
    end

    % trial.Resultsに保存する全trialのデータが集約される
end
% sendCommand(daq,7); % Block終了

ListenChar(0) % 「キーボード入力をすべてMATLABのコマンドウィンドウから遮断」の解除

% 全trial（= 1block）終了後の保存
Results = ResultsKeeper(trial);
Results = Results.run_results_keeper(settings.judge_range_parameters);

% [検証用]
text(0.5, 0.5, 'Executed to the end', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
pause(3); % 3秒間待機
close all


function block_start_notifier(block_type)
switch block_type
    case 'S'
        block_name = 'Speed Adjustment Block';
    case 'P'
        block_name = 'Practice Block';
    case 'M'
        block_name = 'Main Block';
    otherwise
        disp('block_typeへの入力が間違っています\n')
end

txt = text(0.5, 0.5, '', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
txt.String = block_name;
drawnow;
end
