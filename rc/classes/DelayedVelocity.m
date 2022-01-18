classdef DelayedVelocity < handle
% DelayedVelocity Class for creating a delayed copy of a signal on a
% separate analog output.
%
%   DelayedVelocity Properties:
%       enabled         - whether to use this module
%       delay_ms        - amount of delay to add in milliseconds
%       ni              - handle to the NI object
%
%   DelayedVelocity Methods:
%       create_waveform  - takes a waveform and outputs a new waveform with
%                          a delay
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
%   - a field `include_delayed_copy` in the configuration structure, which is
%   set to true
%   - an analog output channel with channel name 'delayed_velocity' in the
%   configuration structure (`ao.channel_names`)
%
%   Otherwise, the `enabled` property is set to false.
%
% Further, `delay_ms` must be a positive integer, so the signal is always
% delayed (does not work if you want to shift the signal foward in time).

    properties
        
        enabled
        delay_ms = 0
    end
    
    properties (SetAccess = private, Hidden = true)
        
        ni
    end
    
    
    
    methods
        
        function obj = DelayedVelocity(ni, config)
        % DelayedVelocity
        %
        %   DelayedVelocity(NI, CONFIG) creates object. NI is an object of
        %   class NI, and CONFIG is a structure with the setup configuration. 
        
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
        %%create_waveform Takes a waveform and outputs a new waveform with a delay
        %
        %   NEW_WAVEFORM = create_waveform(WAVEFORM) takes a Nx1 vector
        %   with a velocity waveform, WAVEFORM. Creates a new vector of the same size
        %   (Nx1) with constant value equal to the `idle_offset` property
        %   (`ao.idle_offset`) of the channel with name 'delayed_velocity'
        %   (this channel must exist or an error is thrown). Then the
        %   waveform is delayed by `delay_ms` amount and inserted into the
        %   new vector.
        %
        %   The new vector is concatenated to the original WAVEFORM in 2nd
        %   dimension and this is returned as NEW_WAVEFORM (Nx2 matrix), to
        %   play on two analog outputs.
        
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
