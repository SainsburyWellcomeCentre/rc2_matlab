classdef ProtocolSequence < handle
% ProtocolSequence Class for handling a sequence of trial objects
%
%   ProtocolSequence Properties:
%       randomize_reward    - whether to randomize the timing of the reward after the trial
%
%    The following are for internal use:
%       sequence            - cell array containing objects of the trial classes
%       abort               - internal, whether to abort the sequence
%       current_sequence    - currently running trial
%       current_reward_state - internal, the state of the reward randomization before the sequence
%       current_trial       - current index of the trial running
%       forward_trials      - number of trials which have finished forward
%       backward_trials     - number of trials which have finished backward
%
%   ProtocolSequence Methods:
%       add             - adds an object of trial class to the sequence.
%       run             - run the sequence of trials in `sequence`
%       prepare         - prepare for running a sequence of trials
%       stop            - stops running the sequence of trials
%
%   See also: ProtocolSequence

    properties
        
        ctl
        sequence = {}
        running = false;
        abort = false;
        current_sequence
        current_reward_state = false
        randomize_reward = false
    end
    
    properties (SetObservable = true)
        
        current_trial = 1;
        forward_trials = 0;
        backward_trials = 0;
    end
    
    
    
    methods
        
        function obj = ProtocolSequence(ctl)
        % ProtocolSequence
        %
        %   ProtocolSequence(CTL) creates the object, and takes CTL, an
        %   object of class RC2Controller as argument.
        
            obj.ctl = ctl;
        end
        
        
        
        function add(obj, protocol)
        %%add Adds an object of trial class to the sequence.
        %
        %   add(TRIAL) adds the object TRIAL to the protocol sequence. It
        %   should be one of the objects Coupled, EncoderOnly, StageOnly,
        %   ReplayOnly, CoupledMismatch, EncoderOnlyMismatch or another
        %   class with `run` and `stop` methods and `handle_acquisition`
        %   and `wait_for_reward` properties.
        
            obj.sequence{end+1} = protocol;
        end
        
        
        
        function run(obj)
        %%run Run the sequence of trials
        %
        %   run() runs the sequence of trials in `sequence` by calling
        %   their `run` method. 
        %
        %   Also starts NIDAQ acquisition and starts playing the sound.
        
            obj.prepare()
            
            h = onCleanup(@obj.cleanup);
            
            obj.ctl.play_sound();
            obj.ctl.prepare_acq();
            obj.ctl.start_acq();
            obj.running = true;
            
            for i = 1 : length(obj.sequence)
                
                obj.current_sequence = obj.sequence{i};
                obj.current_trial = i;
                
                % start running this protocol
                finished_forward = obj.sequence{i}.run();
                
                if obj.abort
                    obj.running = false;
                    obj.abort = false;
                    return
                end
                
                if finished_forward
                    obj.forward_trials = obj.forward_trials + 1;
                else
                    obj.backward_trials = obj.backward_trials + 1;
                end
            end
            
            % let cleanup handle the stopping
        end
        
        
        
        function prepare(obj)
        %%prepare Prepare for running a sequence of trials
        %
        %   prepare() initializes internal variables, sets the reward to be
        %   randomized if necessary, and sets the `handle_acquisition` and
        %   `wait_for_reward` of the trials to false. The `wait_for_reward`
        %   property of the last trial is set to true.
        
            obj.current_trial = 1;
            obj.backward_trials = 0;
            obj.forward_trials = 0;
            
            obj.current_reward_state = obj.ctl.reward.randomize;
            obj.ctl.reward.randomize = obj.randomize_reward;
            
            % set run_once properties to false
            for i = 1 : length(obj.sequence)
                obj.sequence{i}.handle_acquisition = false;
                obj.sequence{i}.wait_for_reward = false;
            end
            
            % wait for reward to complete on last protocol
            obj.sequence{end}.wait_for_reward = true;
            
            % give warning if we are going to be loading onto teensy
            if isprop(obj.sequence{1}, 'direction')
                direction = cellfun(@(x)(x.direction), obj.sequence, 'uniformoutput', false);
                if length(unique(direction)) ~= 1
                    warning('direction of travel is not the same for all protocols')
                end
            end
        end
        
        
        
        function stop(obj)
        %%stop Stops running the sequence of trials
        %
        %   stop() calls the `stop` method of the currently running trial.
        
            if isempty(obj.current_sequence)
                return
            end
            obj.abort = true;
            obj.current_sequence.stop();
            %delete(obj.current_sequence);
            obj.current_sequence = [];
            obj.ctl.reward.randomize = obj.current_reward_state;
        end
        
        
        
        function cleanup(obj)
        %%cleanup Function to run when the `run` exits
        %
        %   cleanup() is here just for safety to stop tasks on the setup
        %   (these should already be called when an individual trial is
        %   stopped).
        
            fprintf('running cleanup in protseq\n')
            obj.running = false;
            obj.ctl.soloist.stop();
            obj.ctl.block_treadmill()
            obj.ctl.vis_stim.off();
            obj.ctl.stop_acq();
            obj.ctl.stop_sound();
        end
    end
end