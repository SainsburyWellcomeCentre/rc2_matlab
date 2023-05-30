classdef DoubleRotation_test_03_vis < handle

    properties

        enable = true;

        vis_stim_type = 'solid';
        
        n_s_plus_trials
        n_s_minus_trials
        n_trials
        s_plus

%         cycles_per_s
%         cycles_per_degree       = 0.02;
%         cycles_per_s_all        = [1.5, 2, 3, 4, 6];  %% which TFs do we need?

        experiment
        enable_motion = true;
        
    end
    
    methods
    
        function obj = DoubleRotation_test_03_vis()
            obj.n_s_plus_trials         = 10;
            obj.n_s_minus_trials        = 10;
            obj.n_trials                = obj.n_s_plus_trials + obj.n_s_minus_trials;
            obj.experiment              = vis_stim_Solid();
        end
    
        function obj = vis_stim_lable(obj, lable_id)
            if strcmp(lable_id,'1')
                obj.s_plus = true;
%                 obj.cycles_per_s = [obj.cycles_per_s_all([1, 1])];
            elseif strcmp(lable_id,'2')
                obj.s_plus = true;
%                 obj.cycles_per_s = [obj.cycles_per_s_all([1, 1])];
            elseif strcmp(lable_id,'3')
                    obj.s_plus = false;
%                     obj.cycles_per_s = [obj.cycles_per_s_all([1, 4])];
            elseif strcmp(lable_id,'4')
                        obj.s_plus = false;
%                         obj.cycles_per_s = [obj.cycles_per_s_all([4, 1])];
            end  
        end
    
    
    end

end
