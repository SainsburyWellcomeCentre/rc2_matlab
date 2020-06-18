classdef Offsets < handle
    
    properties
        
        nominal_stationary_offset = 0.5
        
        ctl
        error_mtx
        
        soloist_input_src = 'teensy'    % 'teensy' or 'ni'
        solenoid_state = 'down'         % 'up' or 'down'
        gear_mode = 'on'                % 'on' or 'off'
    end
    
    
    methods
        
        function obj = Offsets(ctl, config)
            
            obj.ctl = ctl;
            obj.error_mtx = config.offset_error_mtx;
            
        end
        
        
        function val = get_soloist_offset(obj)
            
            if strcmp(obj.solenoid_state, 'up') && strcmp(obj.soloist_input_src, 'teensy')
                
                val = -1e3*(obj.nominal_stationary_offset + obj.error_mtx(1, 2));
            
            elseif strcmp(obj.solenoid_state, 'up') && strcmp(obj.soloist_input_src, 'ni')
                
                val = -1e3*(obj.nominal_stationary_offset + obj.error_mtx(1, 3) + (obj.error_mtx(1, 5) - obj.error_mtx(1, 4)));
            
            elseif strcmp(obj.solenoid_state, 'down') && strcmp(obj.soloist_input_src, 'teensy')
            
                val = -1e3*(obj.nominal_stationary_offset + obj.error_mtx(3, 2));
            
            elseif strcmp(obj.solenoid_state, 'down') && strcmp(obj.soloist_input_src, 'ni')
                
                val = -1e3*(obj.nominal_stationary_offset + obj.error_mtx(3, 3) + (obj.error_mtx(3, 5) - obj.error_mtx(3, 4)));
            
            end
        end
        
        
        function val = get_ni_ao_offset(obj)
            
            % subtract error on AO
            if strcmp(obj.solenoid_state, 'up') && strcmp(obj.gear_mode, 'on')
                
                val = obj.nominal_stationary_offset - obj.error_mtx(1, 5) + obj.error_mtx(1, 4);
            
            elseif strcmp(obj.solenoid_state, 'up') && strcmp(obj.gear_mode, 'off')
                
                val = obj.nominal_stationary_offset - obj.error_mtx(2, 5) + obj.error_mtx(2, 4);
            
            elseif strcmp(obj.solenoid_state, 'down') && strcmp(obj.gear_mode, 'on')
                
                val = obj.nominal_stationary_offset - obj.error_mtx(3, 5) + obj.error_mtx(3, 4);
            
            elseif strcmp(obj.solenoid_state, 'down') && strcmp(obj.gear_mode, 'off')
                
                val = obj.nominal_stationary_offset - obj.error_mtx(4, 5) + obj.error_mtx(4, 4);
            end
            
        end
        
        
        function data = transform_ai_ao_data(obj, data)
            
            % subtract error on AI - assume that solenoid was 'down' and gear
            % mode 'on'...
            data = data - obj.error_mtx(3, 1);
            
            % subtract error on AO
            if strcmp(obj.solenoid_state, 'up') && strcmp(obj.gear_mode, 'on')
                
                data = data - obj.error_mtx(1, 5) + obj.error_mtx(1, 4);
                
            elseif strcmp(obj.solenoid_state, 'up') && strcmp(obj.gear_mode, 'off')
                
                data = data - obj.error_mtx(2, 5) + obj.error_mtx(2, 4);
                
            elseif strcmp(obj.solenoid_state, 'down') && strcmp(obj.gear_mode, 'on')
                
                data = data - obj.error_mtx(3, 5) + obj.error_mtx(3, 4);
                
            elseif strcmp(obj.solenoid_state, 'down') && strcmp(obj.gear_mode, 'off')
                
                data = data - obj.error_mtx(4, 5) + obj.error_mtx(4, 4);
                
            end
        end
    end
end
