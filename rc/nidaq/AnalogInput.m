classdef AnalogInput < handle
% AnalogInput Class for handling analog inputs on the NIDAQ
%
%   AnalogInput Properties:
%       enabled         - whether to use this module
%       task            - handle to the AI session object
%       channel_names   - names of the AI channels
%       channel_ids     - IDs of the AI channels
%       chan            - cell array with the handle to the channel objects
%       h_listener      - handle to the listener containing the callback function
%       log_every       - number of samples between calling the callback function
%
%   AnalogInput Methods:
%       delete          - destructor, deletes the task
%       prepare         - prepare the analog input for acquisition
%       start           - starts the AI task in the background
%       stop            - stop the AI task
%       close           - delete the AI task
%
%   See also: NI

    properties
        
        enabled
    end
    
    properties (SetAccess = private)
        
        task
        channel_names = {}
        channel_ids = {}
        chan = {}
        h_listener
        log_every
    end
    
    
    
    methods
        
        function obj = AnalogInput(config)
        % AnalogInput
        %
        %   AnalogInput(CONFIG) creates the analog input task with
        %   the details described in CONFIG (the main configuration
        %   structure with `ai` field.
        %
        %   See README for details on the configuration.
        
            obj.enabled = config.nidaq.ai.enable;
            
            if ~obj.enabled
                % fill in some blank information
                obj.task.Rate = nan;
                return
            end
            
            obj.task = daq.createSession('ni');
            
            for i = 1:length(config.nidaq.ai.channel_names)
                
                obj.channel_names{i} = config.nidaq.ai.channel_names{i};
                obj.channel_ids{i} = sprintf('ai%i', config.nidaq.ai.channel_id(i));
                obj.chan{i} = addAnalogInputChannel(obj.task, config.nidaq.ai.dev, config.nidaq.ai.channel_id(i), 'Voltage');
            end
            
            obj.task.Rate = config.nidaq.rate;
            obj.task.IsContinuous = 1;
            obj.log_every = config.nidaq.log_every;
            obj.h_listener = addlistener(obj.task, 'DataAvailable', @(x, y)pass(x, y));
        end
        
        
        
        function delete(obj)
        %%delete Destructor, deletes the task
        
            obj.close()
        end
        
        
        
        function prepare(obj, h_callback)
        %%prepare Prepare the analog input for acquisition
        %
        %   prepare(CALLBACK_HANDLE) setups the callback called by the
        %   analog input task. CALLBACK_HANDLE is the handle to a function
        %   which can be any valid function that can be passed to
        %   `addlistener(task, 'DataAvailable', CALLBACK_HANDLE)`
        %
        %   See also: addlistener
        
            if ~obj.enabled, return, end
            
            obj.task.NotifyWhenDataAvailableExceeds = obj.log_every;
            delete(obj.h_listener);
            obj.h_listener = addlistener(obj.task, 'DataAvailable', h_callback);
        end
        
        
        
        function start(obj)
        %%start Starts the AI task in the background
        %
        %   start()
        
            if ~obj.enabled, return, end
            
            obj.task.startBackground();
        end
        
        
        
        function stop(obj)
        %%stop Stop the AI task
        %
        %   stop()
        
            if ~obj.enabled, return, end
            
            if isvalid(obj.task)
                stop(obj.task)
                % remove the callback function
                delete(obj.h_listener);
                obj.h_listener = addlistener(obj.task, 'DataAvailable', @(x, y)pass(x, y));
            end
        end
        
        
        
        function close(obj)
        %%close Delete the AI task
        %
        %   close()
        
            if ~obj.enabled, return, end
            
            if isvalid(obj.task)
                delete(obj.task)
            end
        end
        
        
        
        function val = rate(obj)
            if ~obj.enabled, val = nan; return, end
            val = obj.task.Rate;
        end
    end
end
