clear
close all

%% 読み込むフォルダパスを指定(Main 5block分)
folder_path = "C:\Users\takut\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Hashimoto Resarch\Progress 2\Results\20250114~ 予備実験4\20250205_Y412\tapping_data";

sort_plot = SortMissedKeystrokes();
sort_plot.run_sort_missed_keystrokes(folder_path);