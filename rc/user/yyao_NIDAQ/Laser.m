classdef Laser < handle
    % Pump class for handling digital output pump.

    properties
        
        enabled
        
        high_range
        low_range
        voltage

    end

    properties (SetObservable = true)
%         pulse_duration
        pulse_width
        pulse_interval
    end
    
    properties (SetAccess = private, SetObservable = true)
        ao_chan % Index of the addressed channel.
        laser_state % Current state of the digital output (1 or 0).
        repeat_state
    end
    
    properties (Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    
    methods
        function obj = Laser(ni, config)
            obj.enabled = config.laser.enable;
            if ~obj.enabled, return, end

            obj.ni = ni;
            
            all_ao_channel_names = obj.ni.ao.channel_names;
            this_ao_name = config.laser.ao_name;
            obj.ao_chan = find(strcmp(this_ao_name, all_ao_channel_names));     % ao_chan index
            
%             obj.pulse_duration = config.laser.pulse_duration;
            obj.pulse_width = config.laser.pulse_width;
            obj.pulse_interval = config.laser.pulse_interval;

            obj.high_range = config.laser.voltage_range(1);
            obj.low_range = config.laser.voltage_range(2);
            obj.voltage = config.laser.voltage;
            obj.ni.ao.task.NotifyWhenScansQueuedBelow = 1;
            if config.laser.init_laser_state
                obj.on()
            else
                obj.off()
            end
            
            obj.laser_state = config.laser.init_laser_state;
        end
        
        
        
        function on(obj)
            if ~obj.enabled, return, end
            
            duration = 0.1;
            signal(:,obj.ao_chan) = ones(1,duration*obj.ni.ao.task.Rate)*obj.voltage;
            obj.ni.ao_write(signal);
            obj.laser_state = true;
            obj.ni.ao.task.IsContinuous = 1;
            obj.ni.ao_start();
        end
        
        
        
        function off(obj)
            if ~obj.enabled, return, end
            while obj.ni.ao.task.IsRunning
                pause(0.01);
            end
            obj.ni.ao.task.IsContinuous = 0;
            signal(:,obj.ao_chan) = [0];
            obj.ni.ao_write(signal);
            obj.ni.ao_start();
            obj.ni.ao.stop();
            obj.laser_state = false;
        end



        function pulse_repeat(obj)
            if ~obj.enabled, return, end
            obj.off();
            obj.ni.ao.task.IsContinuous = 1;
            obj.repeat_state = 1;
            while obj.repeat_state ==1
                if obj.repeat_state == -1
                    break
                end
                clear signal
                signal(:,obj.ao_chan) = [ones(1, obj.pulse_width*obj.ni.ao.task.Rate) zeros(1,(obj.pulse_interval-obj.pulse_width)*obj.ni.ao.task.Rate)]*obj.voltage;
                signal(end,obj.ao_chan) = 0;
                obj.ni.ao_write(signal);
                obj.laser_state = true;
                obj.ni.ao_start();
                while obj.ni.ao.task.IsRunning
                    pause(0.005);
                end
                if obj.repeat_state == -1
                    break
                end
                signal(:,obj.ao_chan) = [0];
                obj.ni.ao_write(signal);
                obj.ni.ao_start();
                obj.ni.ao.stop();
                obj.laser_state = false;
                if obj.repeat_state == -1
                    break
                end
            end
            obj.repeat_state = 0;
        end
        
        function pulse_repeat_abort(obj)
            if obj.repeat_state == 0,return, end
            obj.repeat_state = -1;
            obj.off();
        end
        
        function pulse(obj)
            if ~obj.enabled, return, end
            
            signal(:,obj.ao_chan) = [ones(1, obj.pulse_width*obj.ni.ao.task.Rate)]*obj.voltage;
            signal(end,obj.ao_chan) = 0;
            obj.ni.ao_write(signal);
            obj.laser_state = true;
            obj.ni.ao.task.IsContinuous = 1;
            obj.ni.ao_start();
            while obj.ni.ao.task.IsRunning
                pause(0.005);
            end
            obj.off();
        end
    end
end
