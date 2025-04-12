% 保存した打鍵データから必要な要素の取得
function [first_misstap_indices_all_sbj, first_misstap_time_all_sbj, total_taget_trials, total_subjects] = load_tapping_data(tap_data_path)
file_path = fullfile(tap_data_path, 'tap_data.mat');
data = load(file_path);
first_misstap_indices_all_sbj = data.tap_data.first_misstap_indices; % 「trial数（100）× 被験者数」の配列
first_misstap_time_all_sbj = data.tap_data.first_misstap_time; % 「trial数（100）× 被験者数」の配列
total_taget_trials = data.tap_data.total_target_trials; % 各被験者について、関心trialの総数
total_subjects = size(first_misstap_time_all_sbj,2);
end