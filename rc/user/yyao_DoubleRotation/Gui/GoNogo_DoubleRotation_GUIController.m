classdef GoNogo_DoubleRotation_GUIController < handle
    
    properties
        
        protocol
        view
        plot
    end
    
    
    methods
        
        function obj = GoNogo_DoubleRotation_GUIController(protocol)
            
            obj.protocol = protocol;      
            obj.view = GoNogo_DoubleRotation_GUIView(obj); 
                                              
            addlistener(obj.protocol, 'current_trial', 'PostSet', @(src, evnt)obj.current_trial_updated(src, evnt));
            addlistener(obj.protocol, 'n_correct_s_plus_trials', 'PostSet', @(src, evnt)obj.n_correct_s_plus_updated(src, evnt));
            addlistener(obj.protocol, 'n_incorrect_s_plus_trials', 'PostSet', @(src, evnt)obj.n_incorrect_s_plus_updated(src, evnt));
            addlistener(obj.protocol, 'n_correct_s_minus_trials', 'PostSet', @(src, evnt)obj.n_correct_s_minus_updated(src, evnt));
            addlistener(obj.protocol, 'n_incorrect_s_minus_trials', 'PostSet', @(src, evnt)obj.n_incorrect_s_minus_updated(src, evnt));
            addlistener(obj.protocol, 'n_rewards_given', 'PostSet', @(src, evnt)obj.n_rewards_given_updated(src, evnt));
            
            set(obj.view.gui.s_plus_axes, 'ylim', [-0.05, 1.05], 'ytick', [0, 1]);  
            set(obj.view.gui.s_minus_axes, 'ylim', [-0.05, 1.05], 'ytick', [0, 1]); 
            obj.view.gui.warning_text.Text = '';                                    
            obj.view.gui.current_trialtype_val.Text = '';
        end
        
        
        
        function delete(obj)
            delete(obj.view);
            if isvalid(obj.protocol)
                obj.protocol.stop();
            end
        end
        
        
        function stop_protocol(obj)
            obj.protocol.stop();
        end
        
        
        function current_trial_updated(obj, ~, ~)
            obj.view.gui.current_trial_val.Text = sprintf('%i', obj.protocol.current_trial);  
            obj.view.gui.current_trialtype_val.Text = obj.protocol.sequence{obj.protocol.current_trial}.trial.stimulus_type;
        end
        
        function n_correct_s_plus_updated(obj, ~, ~)
            obj.view.gui.s_plus_correct_val.Text = sprintf('%i', obj.protocol.n_correct_s_plus_trials);  
            obj.update_plot();
        end
        
        function n_incorrect_s_plus_updated(obj, ~, ~)
            obj.view.gui.s_plus_incorrect_val.Text = sprintf('%i', obj.protocol.n_incorrect_s_plus_trials);  
            obj.update_plot();
        end
        
        function n_correct_s_minus_updated(obj, ~, ~)
            obj.view.gui.s_minus_correct_val.Text = sprintf('%i', obj.protocol.n_correct_s_minus_trials);  
            obj.update_plot();
        end
        
        function n_incorrect_s_minus_updated(obj, ~, ~)
            obj.view.gui.s_minus_incorrect_val.Text = sprintf('%i', obj.protocol.n_incorrect_s_minus_trials);  
            obj.update_plot();
        end
        
        function n_rewards_given_updated(obj, ~, ~)
            obj.view.gui.total_rewards_given.Text = sprintf('%i', obj.protocol.n_rewards_given);  
        end
        
        function update_plot(obj)    
            
            obj.plot.s_plus_idx = cellfun(@(x)(contains(x,'plus')), obj.protocol.stimulus_type_list);
            obj.plot.s_minus_idx = cellfun(@(x)(contains(x,'minus')), obj.protocol.stimulus_type_list);
            
            obj.plot.n_s_plus = sum(obj.plot.s_plus_idx);
            obj.plot.n_s_minus = sum(obj.plot.s_minus_idx);
            
            obj.plot.s_plus_response = obj.protocol.is_correct(obj.plot.s_plus_idx);
            obj.plot.s_minus_response = obj.protocol.is_correct(obj.plot.s_minus_idx);
            
            splus_colormap = [  255/255,0/255,0/255;...
                                255/255,127/255,0/255;...
                                255/255,255/255,0/255;...
                                0/255,255/255,0/255;...
                                0/255,0/255,255/255;...
                                75/255,0/255,130/255;...
                                148/255,0/255,211/255 ];
            obj.plot.s_plus_col = zeros(obj.plot.n_s_plus+obj.plot.n_s_minus, 3);
            obj.plot.s_plus_col(:,1) = 1;
%             obj.plot.s_plus_col(obj.plot.s_plus_response == 0, 1) = 1;
%             obj.plot.s_plus_col(obj.plot.s_plus_response == 1, 3) = 1;
%             obj.plot.s_plus_col(ceil(obj.protocol.stimulus_typeid_list/2),1:3) = splus_colormap(ceil(obj.protocol.stimulus_typeid_list/2),:);
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 1),1:3) = splus_colormap(1,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 2),1:3) = splus_colormap(1,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 3),1:3) = splus_colormap(2,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 4),1:3) = splus_colormap(2,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 5),1:3) = splus_colormap(3,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 6),1:3) = splus_colormap(3,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 7),1:3) = splus_colormap(4,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 8),1:3) = splus_colormap(4,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 9),1:3) = splus_colormap(5,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 10),1:3) = splus_colormap(5,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 11),1:3) = splus_colormap(6,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 12),1:3) = splus_colormap(6,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 13),1:3) = splus_colormap(7,:);
            catch
            end
            try
                obj.plot.s_plus_col(find(obj.protocol.stimulus_typeid_list == 14),1:3) = splus_colormap(7,:);
            catch
            end
%             obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'80'),1) = 255/255;obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'80'),2) = 0/255;  obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'80'),3) = 0/255;
%             obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'70'),1) = 255/255;obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'70'),2) = 127/255;obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'70'),3) = 0/255;
%             obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'60'),1) = 255/255;obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'60'),2) = 255/255;obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'60'),3) = 0/255;
%             obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'50'),1) = 0/255;  obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'50'),2) = 255/255;obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'50'),3) = 0/255;
%             obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'40'),1) = 0/255;  obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'40'),2) = 0/255;  obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'40'),3) = 255/255;
%             obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'30'),1) = 75/255; obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'30'),2) = 0/255;  obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'30'),3) = 130/255;
%             obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'20'),1) = 148/255;obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'20'),2) = 0/255;  obj.plot.s_plus_col(contains(obj.protocol.stimulus_type_list,'20'),3) = 211/255;
            obj.plot.s_plus_col(~obj.plot.s_plus_idx,:)=[];
%             obj.plot.s_plus_fill = zeros(obj.plot.n_s_plus);
%             obj.plot.s_plus_fill(obj.plot.s_plus_response == 0) = true;
            
            obj.plot.s_minus_col = ones(obj.plot.n_s_minus, 3)*0.6;
%             obj.plot.s_minus_col(obj.plot.s_minus_response == 0, 1) = 1;
%             obj.plot.s_minus_col(obj.plot.s_minus_response == 1, 3) = 1;
%             obj.plot.s_minus_fill = zeros(obj.plot.n_s_plus);
%             obj.plot.s_minus_fill(obj.plot.s_minus_response == 0) = true;
            
            scatter(obj.view.gui.s_plus_axes, 1:obj.plot.n_s_plus, obj.plot.s_plus_response, [], obj.plot.s_plus_col, 'fill');       
            scatter(obj.view.gui.s_minus_axes, 1:obj.plot.n_s_minus, obj.plot.s_minus_response, [], obj.plot.s_minus_col, 'fill');   
            
            set(obj.view.gui.s_plus_axes, 'xlim', [0, obj.plot.n_s_plus+1], 'xtick', 1:obj.plot.n_s_plus)
            set(obj.view.gui.s_minus_axes, 'xlim', [0, obj.plot.n_s_minus+1], 'xtick', 1:obj.plot.n_s_minus)
            
            if length(obj.plot.s_plus_response) >= 3
                if sum(obj.plot.s_plus_response(end-2:end)) == 0
                    obj.view.gui.warning_text.Text = '3 incorrect S+ trials in a row';
                end
            end
        end
    end
end
