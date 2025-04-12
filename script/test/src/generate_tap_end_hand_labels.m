% 打鍵もつれが起きた手の支配半球chの特定と格納
function  tap_end_hand_labels = generate_tap_end_hand_labels(first_misstap_indices_all_sbj)

total_subjects = size(first_misstap_indices_all_sbj, 2);
tap_end_hand_labels = cell(total_subjects, 1); % 出力の初期化

for sbj_idx = 1:total_subjects
    first_misstap_indices = squeeze(first_misstap_indices_all_sbj(:,sbj_idx)); % 一人分のデータを取り出す

    hand_labels = mod(first_misstap_indices, 2); % 1の場合は右手、0の場合は左手でもつれ

    % % もつれ手の対応chで検証する場合
    % % 0 -> 2, 1 -> 1 に変換、1はC3、2はC4を表す
    % hand_labels(hand_labels == 0) = 2; % C4のデータを使用
    % hand_labels(hand_labels == 1) = 1; % C3のデータを使用

    % もつれた手と非対応のchで検証する場合はこれを有効化
    hand_labels(hand_labels == 0) = 1; % C3のデータを使用
    hand_labels(hand_labels == 1) = 2; % C4のデータを使用

    tap_end_hand_labels{sbj_idx} = hand_labels;
end
end

