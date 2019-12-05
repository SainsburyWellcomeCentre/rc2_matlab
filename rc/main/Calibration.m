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
        
        filtTeensy2ni_offset
        rawTeensy2ni_offset
        soloist2ni_offset
        
        filtTeensy2ni_max
        rawTeensy2ni_max
        soloist2ni_max
        
        filtTeensy2ni_scale
        rawTeensy2ni_scale
        soloist2ni_scale
        
        filtTeensy2soloist_offset
        ni2soloist_offset
        
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
            
            calib.teensy.load('forward_only', true);
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
            obj.filtTeensy2ni_offset = mean(obj.data(:, filtered_idx));
            obj.rawTeensy2ni_offset = mean(obj.data(:, raw_idx));
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
            obj.filtTeensy2ni_max = mean(obj.data(idx1:idx2, filtered_idx));
            obj.rawTeensy2ni_max = mean(obj.data(idx1:idx2, raw_idx));
            
            % compute the scale in cm
            obj.filtTeensy2ni_scale = obj.max_velocity/(obj.filtTeensy2ni_max - obj.filtTeensy2ni_offset)/10;
            obj.rawTeensy2ni_scale = obj.max_velocity/(obj.rawTeensy2ni_max - obj.rawTeensy2ni_offset)/10;
            
            fprintf('Filtered teensy scale:  %.6f cm/s\n', obj.filtTeensy2ni_scale);
            fprintf('Raw teensy scale:  %.6f cm/s\n', obj.rawTeensy2ni_scale);
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
            
            % check we have already established filtTeensy2ni_offset
            if isempty(obj.filtTeensy2ni_offset)
                error('filtTeensy2ni_offset doesn''t exist. Run ''run_1'' to generate it');
                return; %#ok<UNRCH>
            end
            
            % estimate the voltage offset for the soloist
            teensy_ni_offset_mV = -1e3*obj.filtTeensy2ni_offset;
            
            % run calibration to determine offset on soloist
            relative_filtTeensy2soloist_offset = obj.soloist.calibrate_zero(stage_middle+100, stage_middle-100, teensy_ni_offset_mV);
            
            %TODO: check the units of this
            % actual offset is the two combined
            obj.filtTeensy2soloist_offset = teensy_ni_offset_mV - relative_filtTeensy2soloist_offset;
            
            % stop gear mode
            obj.soloist.abort()
            
            fprintf('Soloist AI offset: %.10f mV\n', obj.filtTeensy2soloist_offset);
            
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
        
        
            %check we have already established filtTeensy2ni_offset
            if isempty(obj.filtTeensy2soloist_offset)
                error('filtTeensy2soloist_offset doesn''t exist. Run ''soloist_ai_offset'' to generate it');
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
            
            obj.soloist.set_offset(obj.filtTeensy2soloist_offset);
            
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
            
            % stop gear mode
            obj.soloist.abort();
            
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
            
            %check we have already established filtTeensy2ni_offset
            if isempty(obj.filtTeensy2soloist_offset)
                error('filtTeensy2soloist_offset doesn''t exist. Run ''soloist_ai_offset'' to generate it');
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
            obj.soloist.set_offset(obj.filtTeensy2soloist_offset);
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
            obj.soloist2ni_offset = mean(obj.data(:, stage_idx));
            
            % print the offset
            fprintf('Stage offset on NI: %.6f V\n', obj.soloist2ni_offset);
        end
        
        
        function soloist_velocity_scale(obj)
        %%SOLOIST_VELOCITY_SCALE(obj, test_on)
        %  This method calibrates the scale for the velocity
        
            %check we have already established filtTeensy2ni_offset
            if isempty(obj.filtTeensy2soloist_offset)
                error('filtTeensy2soloist_offset doesn''t exist. Run ''soloist_ai_offset'' to generate it');
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
            obj.soloist.set_offset(obj.filtTeensy2soloist_offset);
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
            obj.soloist2ni_max = mean(obj.data(idx1:idx2, stage_idx));
            
            % compute the scale, in cm
            obj.soloist2ni_scale = obj.target_velocity/(obj.soloist2ni_max - obj.soloist2ni_offset)/10;
            
            fprintf('Stage scale on NI: %.6f V\n', obj.soloist2ni_scale);
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
            obj.minimum_deadband = max(abs(trace - obj.filtTeensy2ni_offset));
            
            % tell the user the minimum deadband
            fprintf('The minimum deadband you could have (assuming this trace) is %.6fV\n', obj.minimum_deadband);
            fprintf('    which is %.6f cm/s\n', obj.minimum_deadband * obj.filtTeensy2ni_scale);
            
            scale = 1.2;
            
            % suggest you use
            fprintf('%.1fx deadband would be %.6fV\n', scale, scale*obj.minimum_deadband);
            fprintf('    which is %.6f cm/s\n', scale*obj.minimum_deadband * obj.filtTeensy2ni_scale);
        end
        
        
        function calibrate_ni2soloist_offset(obj)
        %%CALIBRATE_NI2SOLOIST_OFFSET(obj)
        %   This method calibrates the offset from the NIDAQ analog output
        %   to the soloist (through the multiplexer). We apply the same
        %   offset as measured from the Teensy analog output to the NIDAQ 
        %   analog input (NOT through the mutliplexer) (this after all is
        %   what we will record and playback)
        
        
            %check we have already established filtTeensy2ni_offset
            if isempty(obj.filtTeensy2ni_offset)
                error('''filtTeensy2ni_offset'' doesn''t exist. Run '''' to generate it');
                return; %#ok<UNRCH>
            end
            if isempty(obj.filtTeensy2soloist_offset)
                error('''filtTeensy2soloist_offset'' doesn''t exist. Run '''' to generate it');
                return; %#ok<UNRCH>
            end
            
            % move the stage to the middle
            stage_middle = mean(obj.soloist.max_limits);
            
            % move to middle of stage. wait for move to complete
            proc = obj.soloist.move_to(stage_middle);
            proc.wait_for(0.5);
            
            % output the same offset as recorded on the NI
            obj.ni.ao.task.outputSingleScan(obj.filtTeensy2ni_offset+0.00696105);
            
            % listen to the NI
            obj.multiplexer.listen_to('ni');
            
            % load the zero teensy script for stationary
            obj.teensy.load('forward_only');
            
             % calibrating, do not move the treadmill
            fprintf('CALIBRATING: do not move the treadmill\n');
            
            % unblock the treadmill
            obj.treadmill.unblock()
            
            % run calibration to determine offset on soloist
            relative_ni2soloist_offset = obj.soloist.calibrate_zero(stage_middle+100, stage_middle-100, obj.filtTeensy2soloist_offset);
            
            % actual offset is the two combined
            obj.ni2soloist_offset = obj.filtTeensy2soloist_offset - relative_ni2soloist_offset;
            
            fprintf('NIDAQ to Soloist analog offset: %.10f mV\n', obj.ni2soloist_offset);
        end
        
        
        
%         function calibrate_ni2soloist_gear_scale(obj)
%         %%CALIBRATE_NI2SOLOIST_GEAR_SCALE(obj)
%         %   This method calibrates the gear scale when using the NIDAQ analog output
%         %   to drive the soloist (through the multiplexer). We record the
%         %   test pulse from the Teensy on the analog input, and play it
%         %   back using the NIDAQ.
%             
%             % prompt user to open Soloist Scope
%             input('Open Soloist Scope and get ready to record velocity feedback (Press enter when done)');
%             
%             % move to back of stage. wait for move to complete
%             proc = obj.soloist.move_to(1200); % needs to be configurable
%             proc.wait_for(0.5);
%             
%             % load a calibration script onto the teensy
%             % it waits for a signal to start
%             obj.teensy.load('calibrate_soloist')
%             
%             % tell stage to listen to teensy
%             obj.multiplexer.listen_to('teensy');
%             
%             % unblock the treadmill
%             obj.treadmill.unblock()
%             
%             % set parameters and enter gear mode
%             obj.soloist.set_offset(obj.filtTeensy2soloist_offset);
%             obj.soloist.set_gear_scale(obj.actual_gear_scale)
%             obj.soloist.listen_until(1450, 400);
%             
%             % Direct the user
%             fprintf('Start recording in the Soloist Scope and press Enter here.\n');
%             fprintf('The stage will reach a peak speed of approximately 40cm/s\n');
%             fprintf('When it has finished, check in the Soloist Scope the actual velocity attained and type it at the command line here\n')
%             input('Ready (press Enter)?');
%             
%             % Tell the teensy to start the profile
%             obj.zero_teensy.zero();
%             
%             % measure the profile
%             obj.measure();
%             
%             % abor this
%             obj.soloist.abort();
%             
%             % move to back of stage. wait for move to complete
%             proc = obj.soloist.move_to(1200); % needs to be configurable
%             proc.wait_for(0.5);
%             
%             % tell stage to listen to teensy
%             obj.multiplexer.listen_to('teensy');
%             
%             % set parameters and enter gear mode
%             obj.soloist.set_offset(obj.ni2soloist_offset);
%             obj.soloist.set_gear_scale(obj.actual_gear_scale)
%             obj.soloist.listen_until(1450, 400);
%             
%             
%             % write the same analog output we just measured
%             obj.ni.ao_write(obj.data);
%             
%             % start the task
%             obj.ni.ao_start();
%         
%         end
        
        
        
        
        function save(obj, fname)
            
            % check that all the parameters have been filled
            valid = ~isempty(obj.filtTeensy2ni_offset) && ...
                ~isempty(obj.rawTeensy2ni_offset) && ...
                ~isempty(obj.soloist2ni_offset) && ...
                ~isempty(obj.filtTeensy2ni_scale) && ...
                ~isempty(obj.rawTeensy2ni_scale) && ...
                ~isempty(obj.soloist2ni_scale) && ...
                ~isempty(obj.filtTeensy2soloist_offset) && ...
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
            
            calibration.offset(filtered_idx) = obj.filtTeensy2ni_offset;
            calibration.offset(raw_idx) = obj.rawTeensy2ni_offset;
            calibration.offset(stage_idx) = obj.soloist2ni_offset;
            
            calibration.scale(filtered_idx) = obj.filtTeensy2ni_scale;
            calibration.scale(raw_idx) = obj.rawTeensy2ni_scale;
            calibration.scale(stage_idx) = obj.soloist2ni_scale;
            
            calibration.filtTeensy2soloist_offset = obj.filtTeensy2soloist_offset;
            calibration.ni2soloist_offset = obj.ni2soloist_offset;
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
