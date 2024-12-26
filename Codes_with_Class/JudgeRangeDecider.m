classdef JudgeRangeDecider
    
    properties
        beap_time
        tap_win_start
        tap_win_end
    end
    

    methods(Access=public)
        function obj = JudgeRangeDecider()
        end

        function [tap_win_start,tap_win_end]=decide(obj,start_beap_time)
            beap_time=obj.make_beap_time(start_beap_time);
           [tap_win_start,tap_win_end]=obj.make_judge_range(beap_time);

           obj.beap_time=beap_time;
           obj.tap_win_start=tap_win_start;
           obj.tap_win_end=tap_win_end;
        end
    end


    % methods(Static,Access=private)
    %     function beap_time = make_beap_time(start_beap_time)
    %     end
    % 
    %     function [tap_win_start,tap_win_end]=make_judge_range(beap_time)
    % 
    % 
    %     end
    % end
end

