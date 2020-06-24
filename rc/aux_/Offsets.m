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
        
        
        function val = get_soloist_offset(obj, solenoid_state, soloist_input_src)
            
            % Use object properties if no states have been given
            VariableDefault('solenoid_state', obj.solenoid_state);
            VariableDefault('soloist_input_src', obj.soloist_input_src);
            
            if strcmp(solenoid_state, 'up') && strcmp(soloist_input_src, 'teensy')
                
                val = -1e3*(obj.nominal_stationary_offset + obj.error_mtx(1, 2));
            
            elseif strcmp(solenoid_state, 'up') && strcmp(soloist_input_src, 'ni')
                
                val = obj.nominal_stationary_offset;
                
                % if 0.5V applied on the NI in this state, we would see
                % this error on the Soloist.
                val = val + obj.error_mtx(1, 3);
                
                % However, we have manipulated the NI voltage in the
                % following way.
                val = val - obj.error_mtx(1, 5) + obj.error_mtx(4, 4);
                
                % Thus this is the offset to subtract (in mV)
                val = -1e3*val;
            
            elseif strcmp(solenoid_state, 'down') && strcmp(soloist_input_src, 'teensy')
            
                val = -1e3*(obj.nominal_stationary_offset + obj.error_mtx(3, 2));
            
            elseif strcmp(solenoid_state, 'down') && strcmp(soloist_input_src, 'ni')
                
                val = obj.nominal_stationary_offset;
                
                % if 0.5V applied on the NI in this state, we would see
                % this error on the Soloist.
                val = val + obj.error_mtx(3, 3);
                
                % However, we have manipulated the NI voltage in the
                % following way.
                val = val - obj.error_mtx(3, 5) + obj.error_mtx(4, 4);
                
                % Thus this is the offset to subtract (in mV)
                val = -1e3*val;
            
            end
        end
        
        
        function val = get_ni_ao_offset(obj, solenoid_state, gear_mode)
        % 
            
            % Use object properties if no states have been given
            VariableDefault('solenoid_state', obj.solenoid_state);
            VariableDefault('gear_mode', obj.gear_mode);
            
            % subtract error on AO
            if strcmp(solenoid_state, 'up') && strcmp(gear_mode, 'on')
                
                val = obj.nominal_stationary_offset - obj.error_mtx(1, 5) + obj.error_mtx(4, 4);
            
            elseif strcmp(solenoid_state, 'up') && strcmp(gear_mode, 'off')
                
                val = obj.nominal_stationary_offset - obj.error_mtx(2, 5) + obj.error_mtx(4, 4);
            
            elseif strcmp(solenoid_state, 'down') && strcmp(gear_mode, 'on')
                
                val = obj.nominal_stationary_offset - obj.error_mtx(3, 5) + obj.error_mtx(4, 4);
            
            elseif strcmp(solenoid_state, 'down') && strcmp(gear_mode, 'off')
                
                val = obj.nominal_stationary_offset - obj.error_mtx(4, 5) + obj.error_mtx(4, 4);
            end
            
        end
        
        
        
        function data = transform_ai_ao_data(obj, data, solenoid_state, gear_mode)
        % Transforms data collected on the NIDAQ analog input, and
        % subtracts offsets
            
            % Use object properties if no states have been given
            VariableDefault('solenoid_state', obj.solenoid_state);
            VariableDefault('gear_mode', obj.gear_mode);
            
            % subtract error on AI - assume that solenoid was 'down' and gear
            % mode 'on' during recording... baseline should be around 0.5V
            data = data - obj.error_mtx(3, 1);
            
            % subtract error on AO
            if strcmp(solenoid_state, 'up') && strcmp(gear_mode, 'on')
                
                % first subtract the offset seen when 0.5V is applied on
                % the 
                data = data - obj.error_mtx(1, 5);
                
                % then add the offset which maintains a stable visual
                % stimulus
                data = data + obj.error_mtx(4, 4);
                
            elseif strcmp(solenoid_state, 'up') && strcmp(gear_mode, 'off')
                
                data = data - obj.error_mtx(2, 5) + obj.error_mtx(4, 4);
                
            elseif strcmp(solenoid_state, 'down') && strcmp(gear_mode, 'on')
                
                data = data - obj.error_mtx(3, 5) + obj.error_mtx(4, 4);
                
            elseif strcmp(solenoid_state, 'down') && strcmp(gear_mode, 'off')
                
                data = data - obj.error_mtx(4, 5) + obj.error_mtx(4, 4);
                
            end
        end
    end
end
