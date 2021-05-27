classdef Offsets < handle
    
    properties
        
        enabled
        nominal_stationary_offset = 0.5
        
        ctl
        error_mtx
    end
    
    
    methods
        
        function obj = Offsets(ctl, config)
            
            obj.enabled = config.offsets.enable;
            if ~obj.enabled, return, end
            
            obj.ctl = ctl;
            obj.error_mtx = config.offsets.error_mtx;
        end
        
        
        function val = get_soloist_offset(obj, soloist_input_src, solenoid_state, gear_mode)
            
            if ~obj.enabled
                val = obj.nominal_stationary_offset;
                return
            end
            
            if strcmp(solenoid_state, 'up') && strcmp(gear_mode, 'on')
                row = 1;
            elseif strcmp(solenoid_state, 'up') && strcmp(gear_mode, 'off')
                row = 2;
            elseif strcmp(solenoid_state, 'down') && strcmp(gear_mode, 'on')
                row = 3;
            elseif strcmp(solenoid_state, 'down') && strcmp(gear_mode, 'off')
                row = 4;
            end
            
            % start at the nominal voltage (e.g. 0.5V)
            val = obj.nominal_stationary_offset;
            
            if strcmp(soloist_input_src, 'teensy')
                
                val = -1e3*(val + obj.error_mtx(row, 2));
                
            elseif strcmp(soloist_input_src, 'ni')
                
                val = val + obj.error_mtx(row, 3);
                val = val - obj.error_mtx(row, 5) + obj.error_mtx(4, 4);
                val = -1e3 * val;
            end
            
            
%             if strcmp(solenoid_state, 'up') && strcmp(soloist_input_src, 'teensy')
%                 
%                 if strcmp(gear_mode, 'on')
%                     val = -1e3*(obj.nominal_stationary_offset + obj.error_mtx(1, 2));
%                 elseif strcmp(gear_mode, 'off')
%                     val = -1e3*(obj.nominal_stationary_offset + obj.error_mtx(2, 2));
%                 end
%                 
%             elseif strcmp(solenoid_state, 'up') && strcmp(soloist_input_src, 'ni')
%                 
%                 val = obj.nominal_stationary_offset;
%                 
%                 % if 0.5V applied on the NI in this state, we would see
%                 % this error on the Soloist.
%                 if strcmp(gear_mode, 'on')
%                     val = val + obj.error_mtx(1, 3);
%                 elseif strcmp(gear_mode, 'off')
%                     val = val + obj.error_mtx(2, 3);
%                 end
%                 
%                 % However, we have manipulated the NI voltage in the
%                 % following way.
%                 if strcmp(gear_mode, 'on')
%                     val = val - obj.error_mtx(1, 5) + obj.error_mtx(4, 4);
%                 elseif strcmp(gear_mode, 'off')
%                     val = val - obj.error_mtx(2, 5) + obj.error_mtx(4, 4);
%                 end
%                 
%                 % Thus this is the offset to subtract (in mV)
%                 val = -1e3*val;
%                 
%             elseif strcmp(solenoid_state, 'down') && strcmp(soloist_input_src, 'teensy')
%                 
%                 if strcmp(gear_mode, 'on')
%                     val = -1e3*(obj.nominal_stationary_offset + obj.error_mtx(3, 2));
%                 elseif strcmp(gear_mode, 'off')
%                     val = -1e3*(obj.nominal_stationary_offset + obj.error_mtx(4, 2));
%                 end
%                 
%             elseif strcmp(solenoid_state, 'down') && strcmp(soloist_input_src, 'ni')
%                 
%                 val = obj.nominal_stationary_offset;
%                 
%                 % if 0.5V applied on the NI in this state, we would see
%                 % this error on the Soloist.
%                 if strcmp(gear_mode, 'on')
%                     val = val + obj.error_mtx(3, 3);
%                 elseif strcmp(gear_mode, 'off')
%                     val = val + obj.error_mtx(4, 3);
%                 end
%                 
%                 % However, we have manipulated the NI voltage in the
%                 % following way.
%                 if strcmp(gear_mode, 'on')
%                     val = val - obj.error_mtx(3, 5) + obj.error_mtx(4, 4);
%                 elseif strcmp(gear_mode, 'off')
%                     val = val - obj.error_mtx(4, 5) + obj.error_mtx(4, 4);
%                 end
%                 
%                 % Thus this is the offset to subtract (in mV)
%                 val = -1e3*val;
%                 
%             end
        end
        
        
        function val = get_ni_ao_offset(obj, solenoid_state, gear_mode)
            
            if ~obj.enabled
                val = obj.nominal_stationary_offset;
                return
            end
            
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
            
            if ~obj.enabled
                return
            end
            
            
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
