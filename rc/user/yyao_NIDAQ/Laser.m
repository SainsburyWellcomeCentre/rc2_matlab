classdef Laser < handle
    % Pump class for handling digital output pump.

    properties
        
        enabled
        
        high_range
        low_range
        voltage

    end

    properties (SetObservable = true)
        pulse_duration
        pulse_width
    end
    
    properties (SetAccess = private, SetObservable = true)
        ao_chan % Index of the addressed channel.
        laser_state % Current state of the digital output (1 or 0).
        
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
            
            obj.pulse_duration = config.laser_pulse_duration;
            obj.pulse_width = config.laser.pulse_width;

            obj.high_range = config.laser.voltage_range(1);
            obj.low_range = config.laser.voltage_range(2);
            obj.voltage = config.laser.voltage;

            if config.laser.init_laser_state
                obj.on()
            else
                obj.off()
            end
            
            obj.laser_state = config.laser.init_laser_state;
        end
        
        
        
        function on(obj)
            if ~obj.enabled, return, end
            
            duration = 2;
            signal(:,obj.ao_chan) = ones(1,duration*obj.ni.ao.task.Rate)*obj.voltage;
            obj.ni.ao_write(signal);
            obj.laser_state = true;
            obj.ni.ao.task.IsContinuous = true;
            obj.ni.ao_start();
        end
        
        
        
        function off(obj)
            if ~obj.enabled, return, end
            
            obj.ni.ao.stop();
            obj.laser_state = false;
        end



        function pulse_repeat(obj)
            if ~obj.enabled, return, end
            
            signal(:,obj.ao_chan) = [ones(1, obj.pulse_width*obj.ni.ao.task.Rate) zeros(1, (obj.pulse_duration-obj.pulse_width)*obj.ni.ao.task.Rate)]*obj.voltage;
            obj.ni.ao_write(signal);
            obj.laser_state = true;
            obj.ni.ao.task.IsContinuous = true;
            obj.ni.ao_start();
        end
        
        
        
        function pulse(obj)
            if ~obj.enabled, return, end
            
            signal(:,obj.ao_chan) = [ones(1, obj.pulse_width*obj.ni.ao.task.Rate)]*obj.voltage;
            obj.ni.ao_write(signal);
            obj.laser_state = true;
            obj.ni.ao.task.IsContinuous = false;
            obj.ni.ao_start();
            obj.off();
        end
    end
end
