classdef DigitalInput < handle
% DigitalInput Class for handling digital inputs on the NIDAQ
%
%   DigitalInput Properties:
%       enabled         - whether to use this module
%       task            - handle to the DI session object
%       ai_task         - not used
%       channel_names   - names of the AI channels
%       channel_ids     - IDs of the AI channels
%       chan            - cell array with the handle to the channel objects
%       n_chan          - number of digital input channels
%       state           - not used
%       ai_chan         - not used
%
%   DigitalInput Methods:
%       read            - read the state of all digital inputs
%       read_channel    - read the state of a digital input
%       close           - delete the task
%
%   See also: NI

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
        % DigitalInput
        %
        %   DigitalInput(CONFIG) creates the digital input task with
        %   the details described in CONFIG (the main configuration
        %   structure with `di` field.
        %
        %   See README for details on the configuration.
        
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
        %%read Read the state of all digital inputs
        %
        %   DATA = read() returns the state of all digital inputs in DATA a
        %   1 x # DI channels boolean array.
        
            if ~obj.enabled, return, end
            
            data = obj.task.inputSingleScan();
        end
        
        
        
        function data = read_channel(obj, chan)
        %%read_channel Read the state of a digital input
        %
        %   DATA = read_channel(CHANNEL_IDX) returns the state the digital
        %   input given by CHANNEL_IDX (which should be an integer between
        %   1 and # DI channels), in DATA a boolean true (high) or false
        %   (low).
        
            if ~obj.enabled, return, end
            
            data = obj.read();
            data = data(chan);
        end
        
        
        
        function close(obj)
        %%close Delete the DI task
        %
        %   close()
        
            if ~obj.enabled, return, end
            
            if isvalid(obj.task)
                delete(obj.task);
            end
        end
    end
end