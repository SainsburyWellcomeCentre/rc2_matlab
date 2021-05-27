classdef DelayedVelocity < handle
    
    properties
        
        enabled
        delay_ms = 0
        ni
    end
    
    
    methods
        
        function obj = DelayedVelocity(ni, config)
            
            if ~isfield(config, 'include_delayed_copy')
                obj.enabled = false;
                obj.ni = ni;
                return
            end
            
            obj.enabled = config.include_delayed_copy;
            obj.delay_ms = config.delay_ms;
            obj.ni = ni;
            
            ao_idx = find(strcmp(obj.ni.ao.channel_names, 'delayed_velocity'), 1);
            
            if isempty(ao_idx)
                obj.enabled = false;
            end
        end
        
        
        
        function new_waveform = create_waveform(obj, waveform)
            
            % if we are including a delayed copy of the velocity waveform
            if obj.enabled
                
                % number of sample points to delay
                n_samples_to_delay = (obj.delay_ms/1e3) * obj.ni.ao.task.Rate;
                
                fprintf('Delaying by %i samples\n', n_samples_to_delay);
                
                ao_idx = find(strcmp(obj.ni.ao.channel_names, 'delayed_velocity'));
                
                assert(~isempty(ao_idx));
                
                offset = obj.ni.ao.idle_offset(ao_idx);
                
                delayed_waveform = offset * ones(size(waveform));
                
                delayed_waveform(n_samples_to_delay+1:end) = waveform(1:end-n_samples_to_delay);
                
                new_waveform = [waveform, delayed_waveform];
                
            else
                
                new_waveform = waveform;
            end
        end
    end
end