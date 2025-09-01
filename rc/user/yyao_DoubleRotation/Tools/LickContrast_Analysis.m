if exist('analysis')
    try
        close(analysis.f.Number)
    end
end
clear analysis

analysis.bin_fname = 'C:\Users\Margrie_Lab1\Documents\raw_data\CAA-1123047\CAA-1123047_t122_ContrastTraining_Stage2.bin';

[analysis.timebase,analysis.signal,analysis.online_data] = LickingData_Reading(analysis.bin_fname);
analysis.sampling_rate = 10000;
analysis.timeout = 5;
analysis.output.total_time=analysis.timebase(end);                  % total time
try
    analysis.output.n_rewards_given=analysis.online_data.n_rewards_given;    % total licking triggered rewards
catch
end
analysis.lick_threshold = 2.0;
if isfield(analysis.online_data,'analysis.lick_threshold')
    analysis.lick_threshold = analysis.online_data.analysis.lick_threshold;
end
analysis.reward_threshold = 4;
analysis.lickDetect_trigger_threshold = 4;
analysis.idx.lick = zeros(1,length(analysis.timebase));
analysis.idx.pump = zeros(1,length(analysis.timebase));
analysis.idx.trigger = zeros(1,length(analysis.timebase));
for i=2:length(analysis.timebase)
    if length(analysis.lick_threshold)==1
        if analysis.signal.lick_signal(i-1)<analysis.lick_threshold & analysis.signal.lick_signal(i)>=analysis.lick_threshold
            analysis.idx.lick(i)=1;
        end
    elseif length(analysis.lick_threshold)==2
        if analysis.signal.lick_signal(i-1)<analysis.lick_threshold(1) & analysis.signal.lick_signal(i)>=analysis.lick_threshold(1) & analysis.signal.lick_signal(i)<=analysis.lick_threshold(2)
            analysis.idx.lick(i)=1;
        end
    end
    if analysis.signal.pump_signal(i-1)<analysis.reward_threshold & analysis.signal.pump_signal(i)>=analysis.reward_threshold
        analysis.idx.pump(i)=1;
    end
    if analysis.signal.LickDetect_trigger_signal(i-1)<analysis.lickDetect_trigger_threshold & analysis.signal.LickDetect_trigger_signal(i)>=analysis.lickDetect_trigger_threshold
        analysis.idx.trigger(i)=1;
    end
end
analysis.timestamp.lick = find(analysis.idx.lick==1)/analysis.sampling_rate;     % licking timestamps
analysis.timestamp.reward = find(analysis.idx.pump==1)/analysis.sampling_rate;   % reward timestamps
analysis.timestamp.trigger = find(analysis.idx.trigger==1)/analysis.sampling_rate;   % reward timestamps
analysis.output.n_licking=length(analysis.timestamp.lick);          % total licking
try
    analysis.output.n_rewards_manually=length(analysis.timestamp.reward)-analysis.online_data.n_rewards_given;   % manually given rewards
catch
end


analysis.output.n_trials = length(analysis.online_data.response);
analysis.trial.s_plus.trialidx = [];
analysis.trial.s_minus.trialidx = [];
for j = 1:length(unique(analysis.online_data.stimulus_typeid))
    analysis.trial.stimulus_type{j}.typename = analysis.online_data.stimulus_type(min(find(analysis.online_data.stimulus_typeid==j)));
    analysis.trial.stimulus_type{j}.trialidx = find(analysis.online_data.stimulus_typeid==j);
    analysis.trial.stimulus_type{j}.n_correct = sum(analysis.online_data.response(analysis.trial.stimulus_type{j}.trialidx));
    if contains(analysis.trial.stimulus_type{j}.typename,'s_plus')
        analysis.trial.s_plus.trialidx = [analysis.trial.s_plus.trialidx analysis.trial.stimulus_type{j}.trialidx];
    elseif contains(analysis.trial.stimulus_type{j}.typename,'s_minus')
        analysis.trial.s_minus.trialidx = [analysis.trial.s_minus.trialidx analysis.trial.stimulus_type{j}.trialidx];
    end
end
analysis.output.n_correct_trials_s_plus = sum(analysis.online_data.response(analysis.trial.s_plus.trialidx));
analysis.output.n_correct_trials_s_minus = sum(analysis.online_data.response(analysis.trial.s_minus.trialidx));
analysis.output.accuracy_s_plus = analysis.output.n_correct_trials_s_plus/length(analysis.trial.s_plus.trialidx);
analysis.output.accuracy_s_minus = analysis.output.n_correct_trials_s_minus/length(analysis.trial.s_minus.trialidx);

%     analysis.output.n_correct_all = [];

% latency
analysis.trial.latency = NaN(1,analysis.output.n_trials);
for i = 1:analysis.output.n_trials
    analysis.trial.validlicking{i} = find(analysis.timestamp.lick>analysis.timestamp.trigger(i) & analysis.timestamp.lick<analysis.timestamp.trigger(i)+analysis.timeout);
    if ~isempty(analysis.trial.validlicking{i})
        analysis.trial.latency(i) = analysis.timestamp.lick(min(analysis.trial.validlicking{i}))-analysis.timestamp.trigger(i);
    end
end
[~,analysis.temp.typeididx] = sort(analysis.online_data.stimulus_typeid);
for i = 1:analysis.output.n_trials
    analysis.latencytable.stimulus_type{i,1} = analysis.online_data.stimulus_type{analysis.temp.typeididx(i)};
    analysis.latencytable.latency(i,1) = analysis.trial.latency(analysis.temp.typeididx(i));
end
splus_type = analysis.latencytable.stimulus_type(1:analysis.output.n_trials/2);
sminus_type = analysis.latencytable.stimulus_type(analysis.output.n_trials/2+1:end);
latency_splus = analysis.latencytable.latency(1:analysis.output.n_trials/2);
latency_sminus = analysis.latencytable.latency(analysis.output.n_trials/2+1:end);
analysis.output.latencytable = table(splus_type,latency_splus,sminus_type,latency_sminus);
clear splus_type sminus_type latency_splus latency_sminus


% %{
        % raster plotting
    %%%%%%%  Parameters for Rasters    %%%%%%%%%%%%%%%%%%%%
    analysis.rasters.spike_line_width=1;         %%%放电raster线条的宽度
    analysis.rasters.raster_color=[255 0 0; 255 127 0; 255 255 0; 0 255 0; 0 0 255; 75 0 130; 148 0 211; 255*0.6 255*0.6 255*0.6];        %%%放电raster的颜色 [R G B]
    analysis.rasters.spikeHeight=0.8;              %%%
    analysis.rasters.graph_length=1000;        %%%整个图的长度（单位：点子数）,此时刚好，spike和LFP的长度为1000点
    analysis.rasters.graph_height=600;         %%%整个图的高度（单位：点子数）,此时如果LFPHeight=0.4,则LFP高度为500*0.4=200个点，如果spikeHeight=0.3,则spike高度为500*0.3个点
    analysis.rasters.t0=[-5.1 5.1];
    analysis.rasters.h=0.015;
    analysis.bin=0.5;
    analysis.binleft=analysis.rasters.t0(1):analysis.bin:analysis.rasters.t0(2);
    
    analysis.rasters.spkref = analysis.timestamp.trigger;
    analysis.t1=analysis.rasters.spkref+analysis.rasters.t0(1)-0.0005;
    analysis.t2=analysis.rasters.spkref+analysis.rasters.t0(2)+0.0005;
    analysis.count=zeros(1,length(analysis.binleft));
    analysis.f=figure;   % figure 1 
    analysis.n_lickingtrials = 0;

    for j=1:1:length(analysis.rasters.spkref)
        analysis.rasters.trial(j).spk=analysis.timestamp.lick;
        analysis.rasters.trial(j).spk(analysis.rasters.trial(j).spk>analysis.t2(j)|analysis.rasters.trial(j).spk<analysis.t1(j))=[];
        if size(analysis.rasters.trial(j).spk,1)==0 | size(analysis.rasters.trial(j).spk,2)==0
            continue
        else
            analysis.rasters.trial(j).perieventTs=analysis.rasters.trial(j).spk-analysis.rasters.spkref(j);
            for k=1:1:length(analysis.rasters.trial(j).spk)
                x=floor((analysis.rasters.trial(j).spk(k)-analysis.t1(j))/analysis.bin)+1;
                if x<=size(analysis.count,2)
                analysis.count(1,x)=analysis.count(1,x)+1;
                end
                    subplot('position',[0.13,0.95-analysis.rasters.h*j,0.6702668680765358,analysis.rasters.h]);  % figure 1 rasters
                    analysis.rasters.spike_color=analysis.rasters.raster_color(8,:);
                    for i = 1:length(analysis.trial.stimulus_type)
                        if ismember(j,analysis.trial.stimulus_type{i}.trialidx) & contains(analysis.trial.stimulus_type{i}.typename,'s_plus')
                            analysis.rasters.spike_color=analysis.rasters.raster_color(ceil(i/2),:);
                        end
                    end
                    
                    plot(analysis.rasters.trial(j).perieventTs(k)*ones(1,2),[0 1],'color',analysis.rasters.spike_color/255,'linewidth',analysis.rasters.spike_line_width);
                    hold on;
    
            end
            if ~isempty(analysis.rasters.trial(j).perieventTs)
                analysis.n_lickingtrials = analysis.n_lickingtrials+1;
            end
        end
        axis([analysis.rasters.t0(1) analysis.rasters.t0(2) 0 1]);
    %     set(gca,'xtick',[],'ytick',[],'box','off','xcolor',[1 1 1],'ycolor',[1 1 1]);
    %     set(get(gca,'parent'),'color',[1 1 1],'paperunits','points','paperposition',[0 0 analysis.rasters.graph_length analysis.rasters.graph_height]);
        axis off
    
    %         T=analysis.t1(j):analysis.bin:analysis.t2(j);
    %         for l=1:length(T)-1
    %             adtime=time_AD;
    %             adtime(adtime>T(l+1)|adtime<T(l))=[];
    %             ad=interp1(time_AD,AD,adtime);
    %             adFR(j,l)=mean(ad);
    %         end
    end
        
    analysis.firingrate=analysis.count/(length(analysis.rasters.spkref)*analysis.bin);
    analysis.firingrate=analysis.firingrate(1:length(analysis.binleft))';
    
    subplot('position',[0.13,0.3,0.6702668680765358,0.25]);  % figure 1 histograms
    analysis.p=bar(analysis.binleft,analysis.firingrate);
    set(get(analysis.p,'parent'),'box','off');
    set(get(gca,'children'),'edgecolor',[0/255 0/255 0/255],'facecolor',[0/255 0/255 0/255]);  %'edgecolor'bar描边颜色，'facecolor'bar填充颜色
    set(gca,'xlim',[analysis.rasters.t0(1) analysis.rasters.t0(2)],'box','off','xcolor',[0 0 0],'ycolor',[0 0 0]);
    set(gca,'tickdir','out') % 坐标轴刻度向外
    
    analysis.output.analysis.n_lickingtrials = analysis.n_lickingtrials;


clear i j k x;
clc
[analysis.filepath,analysis.filename,analysis.fileext]=fileparts(analysis.bin_fname);
fprintf(['\n' analysis.filename '\n']);
% analysis.output.n_correct_all
try
    analysis.output.latencytable
catch
end
%}