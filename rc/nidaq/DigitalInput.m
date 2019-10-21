classdef DigitalInput < handle
    
    properties
        task
        ai_task
        channel_names
        channel_ids
        chan = {}
        n_chan
        state
        ai_chan
    end
    
    
    methods
        
        function obj = DigitalInput(config)
            
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
            data = obj.task.inputSingleScan();
        end
        
        
        function data = read_channel(obj, chan)
            data = obj.read();
            data = data(chan);
        end
        
        
        function close(obj)
            if isvalid(obj.task)
                delete(obj.task);
            end
        end
    end
end