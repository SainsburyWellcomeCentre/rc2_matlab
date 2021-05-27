classdef DigitalInput < handle
    
    properties
        enabled
        task
        ai_task
        channel_names = {}
        channel_ids = {}
        chan = {}
        n_chan
        state
        ai_chan
    end
    
    
    methods
        
        function obj = DigitalInput(config)
            
            obj.enabled = config.nidaq.di.enable;
            if ~obj.enabled, return, end
            
            obj.task = daq.createSession('ni');
            obj.n_chan = length(config.nidaq.di.channel_names);
            for i = 1 : obj.n_chan
                obj.channel_names{i} = config.nidaq.di.channel_names{i};
                obj.channel_ids{i} = config.nidaq.di.channel_id{i};
                obj.chan{i} = addDigitalChannel(obj.task, config.nidaq.di.dev, config.nidaq.di.channel_id{i}, 'InputOnly');
            end
            obj.task.IsContinuous = 0;
        end
        
        
        
        function data = read(obj)
            
            if ~obj.enabled, return, end
            
            data = obj.task.inputSingleScan();
        end
        
        
        
        function data = read_channel(obj, chan)
            
            if ~obj.enabled, return, end
            
            data = obj.read();
            data = data(chan);
        end
        
        
        
        function close(obj)
            
            if ~obj.enabled, return, end
            
            if isvalid(obj.task)
                delete(obj.task);
            end
        end
    end
end