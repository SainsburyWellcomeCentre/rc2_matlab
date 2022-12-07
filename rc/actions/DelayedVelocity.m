classdef DelayedVelocity < handle
    % DelayedVelocity class for creating a delayed copy of a signal on a
    % separate analog output.
    %
    % This class was created in order to move the stage with a small delay
    % relative to the visual stimulus. This is because there was a delay
    % between the command voltage and the update of the visual stimulus on the
    % projector. Therefore, separate signals were sent to the visual stimulus
    % and stage with the same profiles but with a delay out of two analog
    % ouputs.
    %
    % If this module is to be used there must be:
    %   
    % - a field `include_delayed_copy` in the configuration structure, which is set to true.
    % - an analog output channel with channel name 'delayed_velocity' in the configuration structure (`ao.channel_names`).
    %
    % Otherwise, the :attr:`enabled` property is set to false.
    %
    % Further, :attr:`delay_ms` must be a positive integer, so the signal is always
    % delayed (does not work if you want to shift the signal foward in time).

    properties
        enabled % Boolean specifying whether to use this module.
        delay_ms = 0 % Amount of delay to add in milliseconds.
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    
    methods
        function obj = DelayedVelocity(ni, config)
            % Constructor for a :class:`rc.actions.DelayedVelocity` action.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration structure.
        
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
            % Accepts a waveform and outputs a new waveform with added delay.
            %
            % :param waveform: An Nx1 vector containing a velocity vector.
            % :return: Transformation of the input vector to a new vector with constant value equal to the ``idle_offset`` property of the :class:`rc.nidaq.AnalogOutput` class of the channel with name 'delayed_velocity'. The new vector is concatenated to the original ``waveform`` delayed by :attr:`delay_ms`. Returned as an Nx2 matrix to play on two analog outputs.
        
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