clear
close

bin_fname = 'D:\raw_data\CAA-1120675\CAA-1120675_231130_e50_PassiveRotationInDarkness_Stage2_einterleaving.bin';

[timebase,signal,online_data] = LickingData_Reading(bin_fname);
sampling_rate = 10000;

output.total_time=timebase(end);                  % total time
try
    output.n_rewards_given=online_data.n_rewards_given;    % total licking triggered rewards
catch
end
lick_threshold = 2.0;
if isfield(online_data,'lick_threshold')
    lick_threshold = online_data.lick_threshold;
end
reward_threshold = 4;
lickDetect_trigger_threshold = 4;
idx.lick = zeros(1,length(timebase));
idx.pump = zeros(1,length(timebase));
idx.trigger = zeros(1,length(timebase));
for i=2:length(timebase)
    if signal.lick_signal(i-1)<lick_threshold & signal.lick_signal(i)>=lick_threshold
        idx.lick(i)=1;
    end
    if signal.pump_signal(i-1)<reward_threshold & signal.pump_signal(i)>=reward_threshold
        idx.pump(i)=1;
    end
    if signal.LickDetect_trigger_signal(i-1)<lickDetect_trigger_threshold & signal.LickDetect_trigger_signal(i)>=lickDetect_trigger_threshold
        idx.trigger(i)=1;
    end
end
timestamp.lick = find(idx.lick==1)/sampling_rate;     % licking timestamps
timestamp.reward = find(idx.pump==1)/sampling_rate;   % reward timestamps
timestamp.trigger = find(idx.trigger==1)/sampling_rate;   % reward timestamps
output.n_licking=length(timestamp.lick);          % total licking
try
output.n_rewards_manually=length(timestamp.reward)-online_data.n_rewards_given;   % manually given rewards
catch
end

if isfield(online_data,'response') & isfield(online_data,'stimulus_type')
    output.n_trials = length(online_data.response);
    for i = 1:output.n_trials
        trial.s_plus80(i) = contains(online_data.stimulus_type(i),'80');
        trial.s_plus70(i) = contains(online_data.stimulus_type(i),'70');
        trial.s_plus60(i) = contains(online_data.stimulus_type(i),'60');
        trial.s_plus50(i) = contains(online_data.stimulus_type(i),'50');
        trial.s_plus40(i) = contains(online_data.stimulus_type(i),'40');
        trial.s_plus30(i) = contains(online_data.stimulus_type(i),'30');
        trial.s_plus20(i) = contains(online_data.stimulus_type(i),'20');
        trial.s_minus(i) = contains(online_data.stimulus_type(i),'minus');
        trial.ccw80(i) = contains(online_data.stimulus_type(i),'L') & contains(online_data.stimulus_type(i),'80');
        trial.cw80(i) = contains(online_data.stimulus_type(i),'R') & contains(online_data.stimulus_type(i),'80');
        trial.ccw70(i) = contains(online_data.stimulus_type(i),'L') & contains(online_data.stimulus_type(i),'70');
        trial.cw70(i) = contains(online_data.stimulus_type(i),'R') & contains(online_data.stimulus_type(i),'70');
        trial.ccw60(i) = contains(online_data.stimulus_type(i),'L') & contains(online_data.stimulus_type(i),'60');
        trial.cw60(i) = contains(online_data.stimulus_type(i),'R') & contains(online_data.stimulus_type(i),'60');
        trial.ccw50(i) = contains(online_data.stimulus_type(i),'L') & contains(online_data.stimulus_type(i),'50');
        trial.cw50(i) = contains(online_data.stimulus_type(i),'R') & contains(online_data.stimulus_type(i),'50');
        trial.ccw40(i) = contains(online_data.stimulus_type(i),'L') & contains(online_data.stimulus_type(i),'40');
        trial.cw40(i) = contains(online_data.stimulus_type(i),'R') & contains(online_data.stimulus_type(i),'40');
        trial.ccw30(i) = contains(online_data.stimulus_type(i),'L') & contains(online_data.stimulus_type(i),'30');
        trial.cw30(i) = contains(online_data.stimulus_type(i),'R') & contains(online_data.stimulus_type(i),'30');
        trial.ccw20(i) = contains(online_data.stimulus_type(i),'L') & contains(online_data.stimulus_type(i),'20');
        trial.cw20(i) = contains(online_data.stimulus_type(i),'R') & contains(online_data.stimulus_type(i),'20');
        trial.ccw_minus(i) = contains(online_data.stimulus_type(i),'L') & contains(online_data.stimulus_type(i),'minus');
        trial.cw_minus(i) = contains(online_data.stimulus_type(i),'R') & contains(online_data.stimulus_type(i),'minus');
    end
    trialidx.s_plus80 = find(trial.s_plus80==1);
    trialidx.s_plus70 = find(trial.s_plus70==1);
    trialidx.s_plus60 = find(trial.s_plus60==1);
    trialidx.s_plus50 = find(trial.s_plus50==1);
    trialidx.s_plus40 = find(trial.s_plus40==1);
    trialidx.s_plus30 = find(trial.s_plus30==1);
    trialidx.s_plus20 = find(trial.s_plus20==1);
    
    output.n_s_plus_trials = sum([length(trialidx.s_plus80) length(trialidx.s_plus70) length(trialidx.s_plus60) length(trialidx.s_plus50) length(trialidx.s_plus40) length(trialidx.s_plus30) length(trialidx.s_plus20)]);
    trialidx.s_minus = find(trial.s_minus==1);
    output.n_s_minus_trials = length(trialidx.s_minus);
    
    output.n_correct_s_plus80_trials = sum(online_data.response(trialidx.s_plus80));
    output.n_correct_s_plus70_trials = sum(online_data.response(trialidx.s_plus70));
    output.n_correct_s_plus60_trials = sum(online_data.response(trialidx.s_plus60));
    output.n_correct_s_plus50_trials = sum(online_data.response(trialidx.s_plus50));
    output.n_correct_s_plus40_trials = sum(online_data.response(trialidx.s_plus40));
    output.n_correct_s_plus30_trials = sum(online_data.response(trialidx.s_plus30));
    output.n_correct_s_plus20_trials = sum(online_data.response(trialidx.s_plus20));
    output.n_correct_s_minus_trials = sum(online_data.response(trialidx.s_minus));
    
    output.accuracy_s_plus = sum([output.n_correct_s_plus80_trials output.n_correct_s_plus70_trials output.n_correct_s_plus60_trials output.n_correct_s_plus50_trials output.n_correct_s_plus40_trials output.n_correct_s_plus30_trials output.n_correct_s_plus20_trials])/output.n_s_plus_trials;
    output.accuracy_s_minus = output.n_correct_s_minus_trials/output.n_s_minus_trials;
    output.accuracy = output.accuracy_s_plus;
    if output.n_s_minus_trials~=0
    	output.accuracy = (output.accuracy_s_plus*output.n_s_plus_trials+output.accuracy_s_minus*output.n_s_minus_trials)/(output.n_s_plus_trials+output.n_s_minus_trials);
    end
    
    trialidx.ccw80 = find(trial.ccw80==1);
    trialidx.ccw70 = find(trial.ccw70==1);
    trialidx.ccw60 = find(trial.ccw60==1);
    trialidx.ccw50 = find(trial.ccw50==1);
    trialidx.ccw40 = find(trial.ccw40==1);
    trialidx.ccw30 = find(trial.ccw30==1);
    trialidx.ccw20 = find(trial.ccw20==1);
    trialidx.ccw_minus = find(trial.ccw_minus==1);
%     output.n_ccw80_trials = length(trialidx.ccw80);
    trialidx.cw80 = find(trial.cw80==1);
    trialidx.cw70 = find(trial.cw70==1);
    trialidx.cw60 = find(trial.cw60==1);
    trialidx.cw50 = find(trial.cw50==1);
    trialidx.cw40 = find(trial.cw40==1);
    trialidx.cw30 = find(trial.cw30==1);
    trialidx.cw20 = find(trial.cw20==1);
    trialidx.cw_minus = find(trial.cw_minus==1);
%     output.n_cw80_trials = length(trialidx.cw80);
    output.n_correct_ccw80_trials = sum(online_data.response(trialidx.ccw80));
    output.n_correct_cw80_trials = sum(online_data.response(trialidx.cw80));
    output.n_correct_ccw70_trials = sum(online_data.response(trialidx.ccw70));
    output.n_correct_cw70_trials = sum(online_data.response(trialidx.cw70));
    output.n_correct_ccw60_trials = sum(online_data.response(trialidx.ccw60));
    output.n_correct_cw60_trials = sum(online_data.response(trialidx.cw60));
    output.n_correct_ccw50_trials = sum(online_data.response(trialidx.ccw50));
    output.n_correct_cw50_trials = sum(online_data.response(trialidx.cw50));
    output.n_correct_ccw40_trials = sum(online_data.response(trialidx.ccw40));
    output.n_correct_cw40_trials = sum(online_data.response(trialidx.cw40));
    output.n_correct_ccw30_trials = sum(online_data.response(trialidx.ccw30));
    output.n_correct_cw30_trials = sum(online_data.response(trialidx.cw30));
    output.n_correct_ccw20_trials = sum(online_data.response(trialidx.ccw20));
    output.n_correct_cw20_trials = sum(online_data.response(trialidx.cw20));
    output.n_correct_ccw_minus_trials = sum(online_data.response(trialidx.ccw_minus));
    output.n_correct_cw_minus_trials = sum(online_data.response(trialidx.cw_minus));
    output.n_correct_all = [output.n_correct_ccw80_trials, output.n_correct_cw80_trials, output.n_correct_ccw70_trials, output.n_correct_cw70_trials, output.n_correct_ccw60_trials, output.n_correct_cw60_trials, output.n_correct_ccw50_trials, output.n_correct_cw50_trials, output.n_correct_ccw40_trials, output.n_correct_cw40_trials, output.n_correct_ccw30_trials, output.n_correct_cw30_trials, output.n_correct_ccw20_trials, output.n_correct_cw20_trials, output.n_correct_ccw_minus_trials, output.n_correct_cw_minus_trials];
end


% %{
try         % raster plotting
%%%%%%%  Parameters for Rasters    %%%%%%%%%%%%%%%%%%%%
rasters.spike_line_width=1;         %%%放电raster线条的宽度
rasters.raster_color=[255 0 0; 255 127 0; 255 255 0; 0 255 0; 0 0 255; 75 0 130; 148 0 211; 255*0.6 255*0.6 255*0.6];        %%%放电raster的颜色 [R G B]
rasters.spikeHeight=0.8;              %%%
rasters.graph_length=1000;        %%%整个图的长度（单位：点子数）,此时刚好，spike和LFP的长度为1000点
rasters.graph_height=600;         %%%整个图的高度（单位：点子数）,此时如果LFPHeight=0.4,则LFP高度为500*0.4=200个点，如果spikeHeight=0.3,则spike高度为500*0.3个点
rasters.t0=[-15.5 15.5];
rasters.h=0.015;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bin=0.5;
binleft=rasters.t0(1):bin:rasters.t0(2);

rasters.spkref = timestamp.trigger;
t1=rasters.spkref+rasters.t0(1)-0.0005;
t2=rasters.spkref+rasters.t0(2)+0.0005;
count=zeros(1,length(binleft));
figure;   % figure 1 
n_lickingtrials = 0;
for j=1:1:length(rasters.spkref)
    rasters.spk=timestamp.lick;
    rasters.spk(rasters.spk>t2(j)|rasters.spk<t1(j))=[];
    if size(rasters.spk,1)==0 | size(rasters.spk,2)==0
        continue
    else
        rasters.trial(j).perieventTs=rasters.spk-rasters.spkref(j);
        for k=1:1:length(rasters.spk)
            x=floor((rasters.spk(k)-t1(j))/bin)+1;
            if x<=size(count,2)
            count(1,x)=count(1,x)+1;
            end
                subplot('position',[0.13,0.95-rasters.h*j,0.6702668680765358,rasters.h]);  % figure 1 rasters
                rasters.spike_color=rasters.raster_color(8,:);
                if trial.s_plus80(j)==1
                    rasters.spike_color=rasters.raster_color(1,:);
                elseif trial.s_plus70(j)==1
                    rasters.spike_color=rasters.raster_color(2,:);
                elseif trial.s_plus60(j)==1
                    rasters.spike_color=rasters.raster_color(3,:);
                elseif trial.s_plus50(j)==1
                    rasters.spike_color=rasters.raster_color(4,:);
                elseif trial.s_plus40(j)==1
                    rasters.spike_color=rasters.raster_color(5,:);
                elseif trial.s_plus30(j)==1
                    rasters.spike_color=rasters.raster_color(6,:);
                elseif trial.s_plus20(j)==1
                    rasters.spike_color=rasters.raster_color(7,:);
                end
                plot(rasters.trial(j).perieventTs(k)*ones(1,2),[0 1],'color',rasters.spike_color/255,'linewidth',rasters.spike_line_width);
                hold on;

        end
        if ~isempty(rasters.trial(j).perieventTs)
            n_lickingtrials = n_lickingtrials+1;
        end
    end
    axis([rasters.t0(1) rasters.t0(2) 0 1]);
%     set(gca,'xtick',[],'ytick',[],'box','off','xcolor',[1 1 1],'ycolor',[1 1 1]);
%     set(get(gca,'parent'),'color',[1 1 1],'paperunits','points','paperposition',[0 0 rasters.graph_length rasters.graph_height]);
    axis off

%         T=t1(j):bin:t2(j);
%         for l=1:length(T)-1
%             adtime=time_AD;
%             adtime(adtime>T(l+1)|adtime<T(l))=[];
%             ad=interp1(time_AD,AD,adtime);
%             adFR(j,l)=mean(ad);
%         end
end
    
firingrate=count/(length(rasters.spkref)*bin);
firingrate=firingrate(1:length(binleft))';

subplot('position',[0.13,0.3,0.6702668680765358,0.25]);  % figure 1 histograms
p=bar(binleft,firingrate);
set(get(p,'parent'),'box','off');
set(get(gca,'children'),'edgecolor',[0/255 0/255 0/255],'facecolor',[0/255 0/255 0/255]);  %'edgecolor'bar描边颜色，'facecolor'bar填充颜色
set(gca,'xlim',[rasters.t0(1) rasters.t0(2)],'box','off','xcolor',[0 0 0],'ycolor',[0 0 0]);
set(gca,'tickdir','out') % 坐标轴刻度向外

output.n_lickingtrials = n_lickingtrials;
catch
end
%}