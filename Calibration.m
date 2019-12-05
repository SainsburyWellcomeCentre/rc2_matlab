classdef Calibration < handle
    
    properties
        
        max_velocity = 1000 % mm/s
        max_voltage = 2.5  % V
        cnts_per_unit = 10000 % check this
    end
    
    properties (SetAccess = private)
        
        data
        
        config
        
        ni
        teensy
        soloist
        multiplexer
        zero_teensy
        treadmill
        
        target_velocity = 400 % mm/s
        
        filtered_teensy_ni_offset
        raw_teensy_ni_offset
        stage_ni_offset
        
        filtered_teensy_ni_max
        raw_teensy_ni_max
        stage_ni_max
        
        filtered_teensy_ni_scale
        raw_teensy_ni_scale
        stage_ni_scale
        
        filtered_teensy_soloist_offset
        
        theoretical_gear_scale
        actual_gear_scale
        
        minimum_deadband
    end
    
    
    
    
    
    methods
        
        function obj = Calibration(config)
        %%obj = CALIBRATION(config)
        %   Class containing calibration routines for setup.
        %   Should run in this particular order:
        %   
        %       1. teensy_ni_offsets()
        %       2. teensy_velocity_scale()
        %       3. soloist_ai_offset()
        %       4. soloist_gear_scale()
        %       5. soloist_ni_offset()
        %       6. soloist_velocity_scale()
        %       7. deadband()
        %
        
            obj.config = config;
            
            % setup the necessary components
            obj.ni = NI(config);
            obj.teensy = Teensy(config, false);
            obj.soloist = Soloist(config);
            obj.multiplexer = Multiplexer(obj.ni, config);
            obj.zero_teensy = ZeroTeensy(obj.ni, config);
            obj.treadmill = Treadmill(obj.ni, config);
            
            obj.multiplexer.listen_to('teensy');
        end
        
        
        
        function teensy_ni_offsets(obj)
            
            % move the stage to the middle
            stage_middle = mean(obj.soloist.max_limits);
            
            % move to middle of stage. wait for move to complete
            proc = obj.soloist.move_to(stage_middle);
            proc.wait_for(0.5);
            
            % load the zero teensy script for stationary
            obj.teensy.load('forward_only');
            
            % unblock the treadmill
            obj.treadmill.unblock()
            
            % calibrating, do not move the treadmill
            fprintf('CALIBRATING: do not move the treadmill\n');
            
            % run the measuring subroutine
            obj.measure();
            
            % index of the filtered teensy
            filtered_idx = strcmp(obj.config.nidaq.ai.channel_names, 'filtered_teensy');
            raw_idx = strcmp(obj.config.nidaq.ai.channel_names, 'raw_teensy');
            
            % select the location of the max
            trace = obj.data(:, filtered_idx);
            
            h_fig = figure;
            plot(trace)
            xlabel('Sample point')
            ylabel('Volts')
            title('trace to average')
            
            % prompt user whether they are happy
            uans = input('Avering this trace, press enter if happy, otherwise press N and rerun calibration:');
            
            % close the figure
            close(h_fig);
            
            % if user pressed N exit
            if strcmp(uans, 'N')
                return
            end
            
            % main teensy offset on PC... step 1 done.
            obj.filtered_teensy_ni_offset = mean(obj.data(:, filtered_idx));
            obj.raw_teensy_ni_offset = mean(obj.data(:, raw_idx));
        end
        
        
        
        function teensy_velocity_scale(obj)
            
            % move the stage to the middle
            stage_middle = mean(obj.soloist.max_limits);
            
            % move to middle of stage. wait for move to complete
            proc = obj.soloist.move_to(stage_middle);
            proc.wait_for(0.5);
            
            % load the zero teensy script for motion
            obj.teensy.load('forward_only');
            
            % print message to user
            input('CALIBRATION: Move the treadmill as fast as possible in the next 10s. Press enter to start.\n');
            
            % unblock the treadmill
            obj.treadmill.unblock()
            
            % run the measuring subroutine
            obj.measure();
            
            % index of the filtered teensy
            filtered_idx = strcmp(obj.config.nidaq.ai.channel_names, 'filtered_teensy');
            raw_idx = strcmp(obj.config.nidaq.ai.channel_names, 'raw_teensy');
            
            % select the location of the max
            trace = obj.data(:, filtered_idx);
            
            % print message to user
            fprintf('Place box over part of trace to average:\n');
            
            h_fig = figure;
            plot(trace)
            xlabel('Sample point')
            ylabel('Volts')
            
            rect = drawrectangle();
            
            uans = input('Press enter key when happy with position (press N to exit):');
            
            if strcmp(uans, 'N')
                return
            end
            
            coords = rect.Position;
            idx1 = round(coords(1));
            idx2 = round(idx1+coords(3));
            
            close(h_fig);
            
            % main teensy offset on PC... step 1 done.
            obj.filtered_teensy_ni_max = mean(obj.data(idx1:idx2, filtered_idx));
            obj.raw_teensy_ni_max = mean(obj.data(idx1:idx2, raw_idx));
            
            % compute the scale in cm
            obj.filtered_teensy_ni_scale = obj.max_velocity/(obj.filtered_teensy_ni_max - obj.filtered_teensy_ni_offset)/10;
            obj.raw_teensy_ni_scale = obj.max_velocity/(obj.raw_teensy_ni_max - obj.raw_teensy_ni_offset)/10;
            
            fprintf('Filtered teensy scale:  %.6f cm/s', obj.filtered_teensy_ni_scale);
            fprintf('Raw teensy scale:  %.6f cm/s', obj.raw_teensy_ni_scale);
        end
        
        
        
        function soloist_ai_offset(obj)
            
            % move the stage to the middle
            stage_middle = mean(obj.soloist.max_limits);
            
            % move to middle of stage. wait for move to complete
            proc = obj.soloist.move_to(stage_middle);
            proc.wait_for(0.5);
            
            % load the zero teensy script for stationary
            obj.teensy.load('forward_only');
            
            % unblock the treadmill
            obj.treadmill.unblock()
            
            % calibrating, do not move the treadmill
            fprintf('CALIBRATING STAGE: do not move the treadmill\n');
            
            % check we have already established filtered_teensy_ni_offset
            if isempty(obj.filtered_teensy_ni_offset)
                error('filtered_teensy_ni_offset doesn''t exist. Run ''run_1'' to generate it');
                return; %#ok<UNRCH>
            end
            
            % estimate the voltage offset for the soloist
            teensy_ni_offset_mV = -1e3*obj.filtered_teensy_ni_offset;
            
            % run calibration to determine offset on soloist
            relative_filtered_teensy_soloist_offset = obj.soloist.calibrate_zero(stage_middle+100, stage_middle-100, teensy_ni_offset_mV);
            
            %TODO: check the units of this
            % actual offset is the two combined
            obj.filtered_teensy_soloist_offset = teensy_ni_offset_mV - relative_filtered_teensy_soloist_offset;
            
            fprintf('Soloist AI offset: %.10f mV\n', obj.filtered_teensy_soloist_offset);
            
            % calibrating, do not move the treadmill
            fprintf('FINISHED ANALOG INPUT OFFSET CALIBRATION FOR STAGE\n');
        end
        
        
        function soloist_gear_scale(obj, test_on)
        %%SOLOIST_GEAR_SCALE(obj, test_on)
        %  This method calibrates the 'gear_scale' parameter. 
        %   The soloist accepts an analog input, and converts the voltage
        %   to velocity.
        %   The scale (V to mm/s) is determined by the gear scale factor.
        %   To do this we need to open Soloist Scope and record the true
        %   velocity feedback of the stage.
        %   To calibrate run with test_on = false;
        %   To test the calibration run with test_on = true
        
        
            %check we have already established filtered_teensy_ni_offset
            if isempty(obj.filtered_teensy_soloist_offset)
                error('filtered_teensy_soloist_offset doesn''t exist. Run ''soloist_ai_offset'' to generate it');
                return; %#ok<UNRCH>
            end
            
            % prompt user to open Soloist Scope
            input('Open Soloist Scope and get ready to record velocity feedback (Press enter when done)');
            
            % move to back of stage. wait for move to complete
            proc = obj.soloist.move_to(1200); % needs to be configurable
            proc.wait_for(0.5);
            
            % load a calibration script onto the teensy
            % it waits for a signal to start
            obj.teensy.load('calibrate_soloist')
            
            % unblock the treadmill
            obj.treadmill.unblock()
            
            % calculate the theoretical gear scale factor
            max_speed_scale = (obj.max_velocity * obj.cnts_per_unit)/1000;
            obj.theoretical_gear_scale = -(max_speed_scale * (1/obj.max_voltage));
            
            obj.soloist.set_offset(obj.filtered_teensy_soloist_offset);
            
            % run a calibration script on the soloist
            if test_on
                if isempty(obj.actual_gear_scale)
                    error('actual_gear_scale doesn''t exist. Run ''soloist_gear_scale'' in calibration mode to generate it');
                    return; %#ok<UNRCH>
                end
                obj.soloist.set_gear_scale(obj.actual_gear_scale)
            else
                obj.soloist.set_gear_scale(obj.theoretical_gear_scale)
            end
            
            obj.soloist.listen_until(1450, 400);
            
            % Direct the user
            fprintf('Start recording in the Soloist Scope and press Enter here.\n');
            fprintf('The stage will reach a peak speed of approximately 40cm/s\n');
            fprintf('When it has finished, check in the Soloist Scope the actual velocity attained and type it at the command line here\n')
            input('Ready (press Enter)?');
            
            % Tell the teensy to start the profile
            obj.zero_teensy.zero();
            
            % The user types in actual velocity attained from soloist scope
            actual_velocity = input('Actual velocity (mm/s):');
            
            % Ratio of target to actual
            p = obj.target_velocity/actual_velocity;
            
            % compute actual gear scale
            obj.actual_gear_scale = obj.theoretical_gear_scale * p;
            
            fprintf('Theoretical gear scale was %.2f\n', obj.theoretical_gear_scale);
            fprintf('Target velocity was %.2f mm/s\n', obj.target_velocity);
            fprintf('Actual velocity was %.2f mm/s\n', actual_velocity);
            fprintf('So, actual gear scale is %.2f\n', obj.actual_gear_scale);
        end
        
        
        
        function soloist_ni_offset(obj)
        %%SOLOIST_NI_OFFSET(obj)
        %   This method puts the stage into gear mode with the calibrated
        %   offset and gear scale (as measured with the above functions).
        %   Then measures the offset while the treadmill is stationary.
            
            %check we have already established filtered_teensy_ni_offset
            if isempty(obj.filtered_teensy_soloist_offset)
                error('filtered_teensy_soloist_offset doesn''t exist. Run ''soloist_ai_offset'' to generate it');
                return; %#ok<UNRCH>
            end
            if isempty(obj.actual_gear_scale)
                error('actual_gear_scale doesn''t exist. Run ''soloist_gear_scale'' to generate it');
                return; %#ok<UNRCH>
            end
            
            % move the stage to the middle
            stage_middle = mean(obj.soloist.max_limits);
            
            % move to middle of stage. wait for move to complete
            proc = obj.soloist.move_to(stage_middle);
            proc.wait_for(0.5);
            
            % load the zero teensy script for stationary
            obj.teensy.load('forward_only');
            
            % unblock the treadmill
            obj.treadmill.unblock()
            
             % calibrating, do not move the treadmill
            fprintf('CALIBRATING: do not move the treadmill\n');
            
            % set the correct offset and scale on the soloist
            obj.soloist.set_offset(obj.filtered_teensy_soloist_offset);
            obj.soloist.set_gear_scale(obj.actual_gear_scale);
            
            % start the motor in gear mode
            obj.soloist.listen_until(stage_middle+100, stage_middle-100);
            
            % run the measuring subroutine
            obj.measure();
            
            % abort the soloist lprocess
            obj.soloist.abort()
            
            % index of the filtered teensy
            stage_idx = strcmp(obj.config.nidaq.ai.channel_names, 'stage');
            
            % select the location of the max
            trace = obj.data(:, stage_idx);
            
            h_fig = figure;
            plot(trace)
            xlabel('Sample point')
            ylabel('Volts')
            title('trace to average')
            
            % prompt user whether they are happy
            uans = input('Avering this trace, press enter if happy, otherwise press N and rerun calibration:');
            
            % if user pressed N exit
            if strcmp(uans, 'N')
                return
            end
            
            % close the figure
            close(h_fig);
            
            % main teensy offset on PC... step 1 done.
            obj.stage_ni_offset = mean(obj.data(:, stage_idx));
            
            % print the offset
            fprintf('Stage offset on NI: %.6f V\n', obj.stage_ni_offset);
        end
        
        
        function soloist_velocity_scale(obj)
        %%SOLOIST_VELOCITY_SCALE(obj, test_on)
        %  This method calibrates the scale for the velocity
        
            %check we have already established filtered_teensy_ni_offset
            if isempty(obj.filtered_teensy_soloist_offset)
                error('filtered_teensy_soloist_offset doesn''t exist. Run ''soloist_ai_offset'' to generate it');
                return; %#ok<UNRCH>
            end
            if isempty(obj.actual_gear_scale)
                error('actual_gear_scale doesn''t exist. Run ''soloist_gear_scale'' to generate it');
                return; %#ok<UNRCH>
            end
            
            % move to back of stage. wait for move to complete
            proc = obj.soloist.move_to(1200); % needs to be configurable
            proc.wait_for(0.5);
            
            % load a calibration script onto the teensy
            % it waits for a signal to start
            obj.teensy.load('calibrate_soloist')
            
            % unblock the treadmill
            obj.treadmill.unblock()
            
            % set the correct offset and scale on the soloist
            obj.soloist.set_offset(obj.filtered_teensy_soloist_offset);
            obj.soloist.set_gear_scale(obj.actual_gear_scale);
            
            % run the listen until script on the soloist
            obj.soloist.listen_until(1450, 400);
            
            input('Ready to move (press Enter)?');
            
            % Tell the teensy to start the profile
            obj.zero_teensy.zero();
            
            % measure 10s of data
            obj.measure();
            
            % stop the soloist running
            obj.soloist.abort()
            
            % index of the filtered teensy
            stage_idx = strcmp(obj.config.nidaq.ai.channel_names, 'stage');
            
            % select the location of the max
            trace = obj.data(:, stage_idx);
            
            % print message to user
            fprintf('Place box over part of trace to average:\n');
            
            % plot the trace
            h_fig = figure;
            plot(trace)
            xlabel('Sample point')
            ylabel('Volts')
            
            % prompt user to draw a rectangle over region to average
            rect = drawrectangle();
            uans = input('Press enter key when happy with position (press N to exit):');
            
            % if the user presses N, abort
            if strcmp(uans, 'N')
                return
            end
            
            % get the indices where the rectangle is
            coords = round(rect.Position);
            idx1 = round(coords(1));
            idx2 = round(idx1+coords(3));
            
            % close the figure
            close(h_fig);
            
            % voltage on recorded on NI in stage channel
            obj.stage_ni_max = mean(obj.data(idx1:idx2, stage_idx));
            
            % compute the scale, in cm
            obj.stage_ni_scale = obj.target_velocity/(obj.stage_ni_max - obj.stage_ni_offset)/10;
            
            fprintf('Stage scale on NI: %.6f V\n', obj.stage_ni_scale);
        end
        
        
        function deadband(obj)
        %%DEADBAND(obj)
        %   Records some stationary recording and computes the minimum
        %   deadband required, then suggests another deadband.
            
            % move the stage to the middle
            stage_middle = mean(obj.soloist.max_limits);
            
            % move to middle of stage. wait for move to complete
            proc = obj.soloist.move_to(stage_middle);
            proc.wait_for(0.5);
            
            % load the zero teensy script for stationary
            obj.teensy.load('forward_only');
            
             % calibrating, do not move the treadmill
            fprintf('CALIBRATING: do not move the treadmill\n');
            
            % unblock the treadmill
            obj.treadmill.unblock()
            
            % run the measuring subroutine
            obj.measure();
            
            % index of the filtered teensy
            filtered_idx = strcmp(obj.config.nidaq.ai.channel_names, 'filtered_teensy');
            
            % select the location of the max
            trace = obj.data(:, filtered_idx);
            
            h_fig = figure;
            plot(trace)
            xlabel('Sample point')
            ylabel('Volts')
            title('trace to average')
            
            % prompt user whether they are happy
            uans = input('Computing deadband from this trace, press enter if happy, otherwise press N and rerun calibration:');
            
            % close the figure
            close(h_fig);
            
            % if user pressed N exit
            if strcmp(uans, 'N')
                return
            end
            
            % main teensy offset on PC... step 1 done.
            obj.minimum_deadband = max(abs(trace - obj.filtered_teensy_ni_offset));
            
            % tell the user the minimum deadband
            fprintf('The minimum deadband you could have (assuming this trace) is %.6fV\n', obj.minimum_deadband);
            fprintf('    which is %.6f cm/s\n', obj.minimum_deadband * obj.filtered_teensy_ni_scale);
            
            % suggest you use
            fprintf('3x deadband would be %.6fV\n', 3*obj.minimum_deadband);
            fprintf('    which is %.6f cm/s\n', 3*obj.minimum_deadband * obj.filtered_teensy_ni_scale);
        end
        
        
        
        function save(obj, fname)
            
            % check that all the parameters have been filled
            valid = ~isempty(obj.filtered_teensy_ni_offset) && ...
                ~isempty(obj.raw_teensy_ni_offset) && ...
                ~isempty(obj.stage_ni_offset) && ...
                ~isempty(obj.filtered_teensy_ni_scale) && ...
                ~isempty(obj.raw_teensy_ni_scale) && ...
                ~isempty(obj.stage_ni_scale) && ...
                ~isempty(obj.filtered_teensy_soloist_offset) && ...
                ~isempty(obj.actual_gear_scale);
        
            % if not true then problem
            if ~valid
                error('one or more parameters have not been calibrated');
            end
            
            % get the indices in the 
            filtered_idx = strcmp(obj.config.nidaq.ai.channel_names, 'filtered_teensy');
            raw_idx = strcmp(obj.config.nidaq.ai.channel_names, 'raw_teensy');
            stage_idx = strcmp(obj.config.nidaq.ai.channel_names, 'stage');
            
            calibration.channel_names = obj.config.nidaq.ai.channel_names;
            calibration.offset = zeros(1, length(obj.config.nidaq.ai.channel_names));
            calibration.scale = ones(1, length(obj.config.nidaq.ai.channel_names));
            
            calibration.offset(filtered_idx) = obj.filtered_teensy_ni_offset;
            calibration.offset(raw_idx) = obj.raw_teensy_ni_offset;
            calibration.offset(stage_idx) = obj.stage_ni_offset;
            
            calibration.scale(filtered_idx) = obj.filtered_teensy_ni_scale;
            calibration.scale(raw_idx) = obj.raw_teensy_ni_scale;
            calibration.scale(stage_idx) = obj.stage_ni_scale;
            
            calibration.soloist_ai_offset = obj.filtered_teensy_soloist_offset;
            calibration.gear_scale = obj.actual_gear_scale;
            calibration.deadband_V = 1.2*obj.minimum_deadband;
            
            save(fname, 'calibration')
        end
        
        
        function h_callback(obj, ~, evt)
            
            obj.data = cat(1, obj.data, evt.Data);
        end
        
        
        function measure(obj)
            
            obj.data = [];
            
            % setup callback to log data to temporary file
            obj.ni.prepare_acq(@(x, y)obj.h_callback(x, y))
            
            % run for about 20s
            obj.ni.start_acq(false);  % do not start clock
            
            tic;
            while toc < 10
                pause(0.05)
            end
            
            % stop acquiring
            obj.ni.stop_acq(false);
        end
    end
end
