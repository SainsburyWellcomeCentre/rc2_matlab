classdef Offsets < handle
% Offsets Class for handling voltage offsets which appear on the setup
%
%   Offsets Properties:
%       nominal_stationary_offset   - a "desired" voltage value which we
%                                     want to output from the NIDAQ analog ouput
%       error_mtx                   - a matrix of "error" values 
%                                     to apply under different states of
%                                     the setup 
%       ctl                         - object of class RC2Controller
%
%   Offsets Methods:
%       get_soloist_offset       - currently not used
%       get_ni_ao_offset         - get the offset to apply to the NI analog
%                                  output in different setup states to
%                                  maintain stability of the setup
%       transform_ai_ao_data     - given a voltage waveform on the analog
%                                   input, convert to a waveform to apply
%                                   to the analog output which 
%                                   results in the same input to the
%                                   Soloist and visual stimulus computer
%
% Several offsets appear in the operation of the setup, due to electrical
% artefacts (such as switching on LEDs, or the state of the solenoid).
%
% There are also differences when sending signals from the Teensy or the NI
% (i.e. despite commanding 0.5V from the Teensy and NI, there will be an
% error involved in both (observed teensy voltage = 0.5 + teensy_error,
% observed NI voltage = 0.5 + NI_error)). 
%
% Sources of offset error:
%   difference between commanded voltage on Teensy and NI
%   difference between recorded voltage on analog input and replayed analog
%   output
%   introduction of different offset when solenoid block is on or off
%
% The error_mtx is a 4x7 matrix of error values under different setup
% conditions and which offset we are looking at.
%
%   ROW,    STATE OF THE SETUP
%   1       solenoid up, gear mode on
%   2       solenoid up, gear mode off
%   3       solenoid down, gear mode on
%   4       solenoid down, gear mode off
%
%   COL,    OFFSET TYPE
%   1       difference between commanded voltage on Teensy and observed voltage on NIDAQ AI
%   2       NOT USED
%   3       NOT USED
%   4       difference between commanded voltage on Teensy and observed voltage on the visual stimulus computer
%   5       difference between commanded voltage from NIDAQ AO and observed voltage on the visual stimulus computer
%   6       NOT USED
%   7       NOT USED
%
% TODO: currently handling of offsets has not been implemented well and is too
% complicated. It seems to work and the setup is stable, but there should
% be a systematic procedure for handling these offsets, which currently
% there is not.
%
% At a later date, we switched to calibrating the stage at the beginning of every
% trial in which the stage moves. This removed the need for most of this class.
%
% However, we still have to account for the voltage difference between
% solenoid UP and DOWN (which is dealt with separately from this class).
%
% As well,differences between commanded voltage from the Teensy and
% NIDAQ, so that the stage and visual stimulus are stationary at the
% baseline voltage... in this case, this class is still used.
%
% See also: calibration_script

    properties
        
        nominal_stationary_offset = 0.5
        
        ctl
        error_mtx
    end
    
    
    methods
        
        function obj = Offsets(ctl, config)
        % Offsets
        %
        %   Offsets(CTL, CONFIG) class for dealing with offsets on the
        %   setup. Takes the main RC2Controller object, CTL, and the CONFIG
        %   configuration structure.
        
            obj.ctl = ctl;
            obj.error_mtx = config.offset_error_mtx;
            
        end
        
        
        function val = get_soloist_offset(obj, soloist_input_src, solenoid_state, gear_mode)
        %%Currently not used by the rest of the program
        
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
        end
        
        
        function val = get_ni_ao_offset(obj, solenoid_state, gear_mode)
        %%get_ni_ao_offset Given the `nominal_stationary_offset` get the
        %%actual offset to apply on the NIDAQ AO given the state of the
        %%setup.
        %
        %   STATIONARY_OFFSET = get_ni_ao_offset(SOLENOID, GEAR_MODE)
        %   given the state of the solenoid, SOLENOID which can be 'up' or
        %   'down', and GEAR_MODE ('on' or 'off'), return the actual offset to
        %   apply on the NIDAQ analog output given the
        %   `nominal_stationary_offset` property in STATIONARY_OFFSET.
            
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
        %%transform_ai_ao_data given a voltage waveform on the analog input,
        %%convert to a waveform to apply to the analog output which
        %%results in the same input to the Soloist and visual stimulus
        %%computer 
        %
        %   DATA_CORRECTED = transform_ai_ao_data(DATA, SOLENOID, GEAR_MODE)
        %   given the state of the solenoid, SOLENOID which can be 'up' or
        %   'down', and GEAR_MODE ('on' or 'off'), take a Nx1 vector DATA of
        %   recorded velocity data and apply a correction, so that the
        %   eventual voltage seen by the components is the same as the
        %   original. Return Nx1 corrected vector, DATA_CORRECTED.
        %
        %   TODO:   1. completely reimplement offset corrections
        %           2. currently assumes that the recorded data was taken
        %           with solenoid down and gear mode on
        %           3. currently always uses error value in 4th row of 4th
        %           column.. don't see the reason for this
            
            % subtract error on AI - assume that solenoid was 'down' and gear
            % mode 'on' during recording... baseline should be around 0.5V
            data = data - obj.error_mtx(3, 1);
            
            % subtract error on AO
            if strcmp(solenoid_state, 'up') && strcmp(gear_mode, 'on')
                
                % first subtract the offset seen when 0.5V is applied on
                % the NIDAQ
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
