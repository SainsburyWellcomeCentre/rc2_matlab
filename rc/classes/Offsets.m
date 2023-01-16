classdef Offsets < handle
    % Offsets class for handling voltage offsets which appear on the setup.
    %
    % Several offsets appear in the operation of the setup, due to electrical
    % artefacts (such as switching on LEDs, or the state of the solenoid).
    %
    % There are also differences when sending signals from the Teensy or the NI
    % (i.e. despite commanding 0.5V from the Teensy and NI, there will be an
    % error involved in both (observed teensy voltage = 0.5 + teensy_error,
    % observed NI voltage = 0.5 + NI_error)). 
    %
    % Sources of offset error: Difference between commanded voltage on Teensy and NI
    % ; Difference between recorded voltage on analog input and replayed analog output
    % ; Introduction of different offset when solenoid block is on or off.
    %
    % The error_mtx is a 4x7 matrix of error values under different setup
    % conditions and which offset we are looking at.
    %
    %  ROW --- STATE OF THE SETUP
    %
    %  1 ----- solenoid up, gear mode on
    %
    %  2 ----- solenoid up, gear mode off
    %
    %  3 ----- solenoid down, gear mode on
    %
    %  4 ----- solenoid down, gear mode off
    %
    %  COL --- OFFSET TYPE
    %
    %  1 ----- Difference between commanded voltage on Teensy and observed voltage on NIDAQ AI
    %
    %  2 ----- NOT USED
    %
    %  3 ----- NOT USED
    %
    %  4 ----- Difference between commanded voltage on Teensy and observed voltage on the visual stimulus computer
    %
    %  5 ----- Difference between commanded voltage from NIDAQ AO and observed voltage on the visual stimulus computer
    %
    %  6 ----- NOT USED
    %
    %  7 ----- NOT USED
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
    % As well, differences between commanded voltage from the Teensy and
    % NIDAQ, so that the stage and visual stimulus are stationary at the
    % baseline voltage... in this case, this class is still used.
    %
    % See also: calibration_script

    properties
        enabled % Boolean specifying whether the module is used.
        nominal_stationary_offset = 0.5 % A desired voltage value to output from the NIDAQ analog output.
        ctl % :class:`rc2.main.Controller` object.
        error_mtx % A matrix of error values to apply under different states of the setup.
        ao_ai_difference_V
        ni_idle_voltage
    end
    
    
    methods
        function obj = Offsets(ctl, config)
            % Constructor for a :class:`rc.classes.Offsets` class.
            %
            % :param ctl: The primary :class:`rc2.main.Controller` object.
            % :param config: The main configuration structure.
        
            obj.ctl = ctl;
            
            obj.enabled = config.offsets.enable;
            if ~obj.enabled, return, end
            
            if isfield(config, 'offset_error_mtx')
                obj.error_mtx = config.offset_error_mtx;
            else
                obj.error_mtx = config.offsets.error_mtx;
            end
            
            if isfield(config, 'ao_ai_difference_V')
                obj.ao_ai_difference_V = config.ao_ai_difference_V;
                obj.ni_idle_voltage = config.ni_idle_voltage;
            end
        end
        
        
        function val = get_soloist_offset(obj, soloist_input_src, solenoid_state, gear_mode)
            % Currently not used by the rest of the program.
        
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
        end
        
        
        function val = get_ni_ao_offset(obj, solenoid_state, gear_mode)
            % Given the :attr:`nominal_stationary_offset` get the actual offset to apply on the NIDAQ AO given the state of the setup.
            %
            % :param solenoid_state: Current state of the solenoid, can be 'up' or 'down',
            % :param gear_mode: The current gear mode 'on' or 'off'.
            % :return: The actual offset to apply.
            
            if ~isempty(obj.ao_ai_difference_V)
                val = obj.ni_idle_voltage;
                return
            end
                
            
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
            % Given a voltage waveform on the analog input, convert to a waveform to apply to the analog output which results in the same input to the Soloist and visual stimulus computer.
            %
            % :param data: N x 1 vector of recorded velocity data.
            % :param solenoid_state: The current state of the solenoid, can be 'up' or 'down'. 
            % :param gear_mode: The current gear mode, can be 'on' or 'off'.
            % :return: N x 1 corrected waveform, transformed such that voltage seen by downstream components is the same as the original input data.

            %   TODO:   1. completely reimplement offset corrections
            %           2. currently assumes that the recorded data was taken
            %           with solenoid down and gear mode on
            %           3. currently always uses error value in 4th row of 4th
            %           column.. don't see the reason for this
            
            if ~isempty(obj.ao_ai_difference_V)
                data = data - obj.ao_ai_difference_V;
                return
            end
            
            if ~obj.enabled
                return
            end
            
            
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
