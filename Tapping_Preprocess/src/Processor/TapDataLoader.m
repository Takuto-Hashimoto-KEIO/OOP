classdef TapDataLoader
    properties
    end


    methods(Access=public)
        function obj = TapDataLoader()
        end
    end


    methods(Static)
        % 全データの読み出しと仕分け
        function [raw_dataset, cond, result] = load_data(datapath)
            raw_dataset=load(datapath);
            cond.num_participant = raw_dataset.num_participant;
            cond.num_block = raw_dataset.num_block;
            cond.total_trials = raw_dataset.block.num_last_trial;
            cond.trial_task_time = 20; % 本実験1では測定データに含まれていないので仮置き
            cond.tap_interval_list = raw_dataset.block.tap_interval_list;

            % 打鍵関連、前処理に使うもの
            % 打鍵速度関連
            result.raw.tap_speed.interval_indices = raw_dataset.block.interval_index_recorder;
            result.raw.tap_speed.tap_intervals = raw_dataset.block.tap_intervals;

            % 測定結果
            result.raw.success_duration = raw_dataset.block.success_duration;
            result.raw.judge = raw_dataset.block.judge;
        end
    end
end

