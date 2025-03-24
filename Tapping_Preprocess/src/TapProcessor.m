classdef TapProcessor
    % Author:Takuto Hashimoto

    properties(Access=public)
        cfg
        result

        % 各クラスのインスタンス
        data_loader
        data_editor
        data_generator
    end
    
    
    methods(Access=public)
        function obj = TapProcessor()
        end
        
        function obj = processing(obj,cfg)
            obj.cfg=cfg;
            obj=obj.create; % 各処理クラスのインスタンスを事前に作成
            obj=obj.preprocess;
        end
        
        function obj=preprocess(obj)
            % 全データの読み出しと仕分け
            [obj.cfg.raw_dataset, obj.cfg.cond, obj.result]=obj.data_loader.load_data(obj.cfg.datapath);

            % データの処理、新規作成
            obj.result = obj.data_editor.edit_data(obj.cfg, obj.result);
            obj.result = obj.data_generator.generate_data(obj.cfg, obj.result);
        end
    end


    methods(Access=private)
        % 各処理クラスのインスタンスを事前に作成
        function obj=create(obj)
            obj.data_loader=TapDataLoader(); % ロード処理のインスタンスを作成
            obj.data_editor=TapDataEditor(); % 編集処理のインスタンスを作成
            obj.data_generator=TapDataGenerator(); % 新データ作成処理のインスタンスを作成
        end
    end
end

