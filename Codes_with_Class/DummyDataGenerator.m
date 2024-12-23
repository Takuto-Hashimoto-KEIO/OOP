classdef DummyDataGenerator
    properties
        tap_interval
        interval_index_recorder

        first_beep_time
        tap_times
        judge
        success_duration

        display_times
    end

    methods
        function obj = DummyDataGenerator(num_trials, num_conditions, tap_interval)
            if nargin < 2
                num_conditions = 10; % Default number of conditions
            end

            % Generate dummy data
            obj.tap_interval = tap_interval;
            % obj.interval_index_recorder = randi(num_conditions, 1, num_trials); % Random indices for intervals

            obj.first_beep_time = GetSecs;
            obj.tap_times = rand(num_trials, 4, 11000);

            obj.judge = randi([0, 1], num_trials, num_conditions); % Random success/failure judgments
            obj.success_duration = rand(1, num_trials); % Random success durations

            % obj.display_times = rand(num_trials, 2, 4); % Random display times
        end

        function saveData(obj, filename)
            if nargin < 2
                filename = 'dummy_data.mat'; % Default filename
            end
            block.tap_interval = obj.tap_interval;
            block.success_duration = obj.success_duration;
            % block.interval_index_recorder = obj.interval_index_recorder;
            block.judge = obj.judge;
            block.first_beep_time = obj.first_beep_time;
            % block.display_times = obj.display_times;

            save(filename, 'block');
        end
    end
end
