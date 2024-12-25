% メインスクリプト
clc; clear; close all;

% 設定を作成
settings = ParameterSettings('12', 'B1', 1); % ()内は被験者番号、block番号、開始時の速度レベル

% 実験ブロックを作成
block = ExperimentBlock(settings); % クラスを呼び出す、ここで継承しない理由は？

% 実験開始～終了
block.start_block(); % クラスの中の関数を使用
