clear 
close all

start_beap_time=[];

decider = JudgeRangeDecider; % クラスを呼び出す

[tap_win_start, tap_win_end] = decider.decide(start_beap_time); % クラスの中の関数を使用


