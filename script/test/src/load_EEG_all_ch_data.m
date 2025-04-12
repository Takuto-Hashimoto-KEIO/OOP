% 保存したblock別EEGデータの取得、1つのcoiを選択→格納
function EEG_data_coi_all_sbj = load_EEG_all_ch_data(EEG_data_path, total_subjects)

% 出力配列の初期化
EEG_data_coi_all_sbj = cell(total_subjects, 1);

for sbj_idx = 1:total_subjects
    % 被験者フォルダのパスを作成
    subject_folder = sprintf('Y4%02d', sbj_idx);

    % % alphaのデータが欲しい場合
    % fprintf('Loading folder No.%d: %s alpha\n', sbj_idx, subject_folder);
    % file_path = fullfile(EEG_data_path, subject_folder, ...
    %     'spafiled_target_trials_alpha.mat'); % EEGProcessorで作成したtarget_trialのデータだけをロード

    % betaのデータがほしい場合
    fprintf('Loading folder No.%d: %s beta\n', sbj_idx, subject_folder);
    file_path = fullfile(EEG_data_path, subject_folder, ...
        'spafiled_target_trials_beta.mat'); % EEGProcessorで作成したtarget_trialのデータだけをロード

    if isfile(file_path)
        EEG_data = load(file_path);
        
        % EEG_data = EEG_data.spafiled_target_trials_alpha; % alphaのデータが欲しい場合
        EEG_data = EEG_data.spafiled_target_trials_beta; % betaのデータが欲しい場合

        EEG_data_coi_all_sbj{sbj_idx} = EEG_data; % 時間×ch×trial数の配列
    else
        warning('File not found: %s', file_path);
    end
end
end