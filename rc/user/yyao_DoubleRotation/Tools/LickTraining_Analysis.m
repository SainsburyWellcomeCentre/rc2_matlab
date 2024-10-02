if exist('analysis')
    try
    close(analysis.f.Number)
    end
end
clear analysis

analysis.bin_fname = 'C:\Users\Margrie_Lab1\Documents\raw_data\CAA-1121231\CAA-1121231_240216_e20_PassiveRotationInDarkness_Stage2_e80.bin';

[analysis.timebase,analysis.signal,analysis.online_data] = LickingData_Reading(analysis.bin_fname);
analysis.sampling_rate = 10000;

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
    if analysis.signal.lick_signal(i-1)<analysis.lick_threshold & analysis.signal.lick_signal(i)>=analysis.lick_threshold
        analysis.idx.lick(i)=1;
    end
    if analysis.signal.pump_signal(i-1)<analysis.reward_threshold & analysis.signal.pump_signal(i)>=analysis.reward_threshold
        analysis.idx.pump(i)=1;
    end
    if analysis.signal.LickDetect_trigger_signal(i-1)<analysis.lickDetect_trigger_threshold & analysis.signal.LickDetect_trigger_signal(i)>=analysis.lickDetect_trigger_threshold
        analysis.idx.trigger(i)=1;
    end
end
analysis.timestamp.lick = find(analysis.idx.lick==1)/analysis.sampling_rate;     % licking analysis.timestamps
analysis.timestamp.reward = find(analysis.idx.pump==1)/analysis.sampling_rate;   % reward analysis.timestamps
analysis.timestamp.trigger = find(analysis.idx.trigger==1)/analysis.sampling_rate;   % reward analysis.timestamps
analysis.output.n_licking=length(analysis.timestamp.lick);          % total licking
try
analysis.output.n_rewards_manually=length(analysis.timestamp.reward)-analysis.online_data.n_rewards_given;   % manually given rewards
catch
end

if isfield(analysis.online_data,'response') & isfield(analysis.online_data,'stimulus_type')
    analysis.output.n_analysis.trials = length(analysis.online_data.response);
    for i = 1:analysis.output.n_analysis.trials
        analysis.trial.s_plusCCW(i) = strcmp(analysis.online_data.stimulus_type(i),'s_plusL');
        analysis.trial.s_plusCW(i) = strcmp(analysis.online_data.stimulus_type(i),'s_plusR');
        analysis.trial.s_minusCCW(i) = strcmp(analysis.online_data.stimulus_type(i),'s_minusL');
        analysis.trial.s_minusCW(i) = strcmp(analysis.online_data.stimulus_type(i),'s_minusR');
%         analysis.trial.s_plus(i) = strcmp(analysis.online_data.stimulus_type(i),'s_plusL')|strcmp(analysis.online_data.stimulus_type(i),'s_plusR');
        analysis.trial.s_minus(i) = strcmp(analysis.online_data.stimulus_type(i),'s_minusL')|strcmp(analysis.online_data.stimulus_type(i),'s_minusR');
%         analysis.trial.ccw(i) = strcmp(analysis.online_data.stimulus_type(i),'s_minusL')|strcmp(analysis.online_data.stimulus_type(i),'s_plusL');
%         analysis.trial.cw(i) = strcmp(analysis.online_data.stimulus_type(i),'s_minusR')|strcmp(analysis.online_data.stimulus_type(i),'s_plusR');
    end
    analysis.trialidx.s_plusCCW = find(analysis.trial.s_plusCCW==1);
    analysis.output.n_s_plusCCW_analysis.trials = length(analysis.trialidx.s_plusCCW);
    analysis.trialidx.s_plusCW = find(analysis.trial.s_plusCW==1);
    analysis.output.n_s_plusCW_analysis.trials = length(analysis.trialidx.s_plusCW);
    analysis.trialidx.s_minusCCW = find(analysis.trial.s_minusCCW==1);
    analysis.output.n_s_minusCCW_analysis.trials = length(analysis.trialidx.s_minusCCW);
    analysis.trialidx.s_minusCW = find(analysis.trial.s_minusCW==1);
    analysis.output.n_s_minusCW_analysis.trials = length(analysis.trialidx.s_minusCW);
    analysis.output.n_s_plus_analysis.trials = analysis.output.n_s_plusCCW_analysis.trials+analysis.output.n_s_plusCW_analysis.trials;
    analysis.output.n_s_minus_analysis.trials = analysis.output.n_s_minusCCW_analysis.trials+analysis.output.n_s_minusCW_analysis.trials;
%     analysis.trialidx.s_plus = find(analysis.trial.s_plus==1);
%     analysis.output.n_s_plus_analysis.trials = length(analysis.trialidx.s_plus);
%     analysis.trialidx.s_minus = find(analysis.trial.s_minus==1);
%     analysis.output.n_s_minus_analysis.trials = length(analysis.trialidx.s_minus);
    analysis.output.n_correct_s_plusCCW_analysis.trials = sum(analysis.online_data.response(analysis.trialidx.s_plusCCW));
    analysis.output.n_correct_s_plusCW_analysis.trials = sum(analysis.online_data.response(analysis.trialidx.s_plusCW));
    analysis.output.n_correct_s_minusCCW_analysis.trials = sum(analysis.online_data.response(analysis.trialidx.s_minusCCW));
    analysis.output.n_correct_s_minusCW_analysis.trials = sum(analysis.online_data.response(analysis.trialidx.s_minusCW));
%     analysis.output.n_correct_s_plus_analysis.trials = sum(analysis.online_data.response(analysis.trialidx.s_plus));
%     analysis.output.n_correct_s_minus_analysis.trials = sum(analysis.online_data.response(analysis.trialidx.s_minus));
    analysis.output.n_correct_s_plus_analysis.trials = analysis.output.n_correct_s_plusCCW_analysis.trials + analysis.output.n_correct_s_plusCW_analysis.trials;
    analysis.output.n_correct_s_minus_analysis.trials = analysis.output.n_correct_s_minusCCW_analysis.trials + analysis.output.n_correct_s_minusCW_analysis.trials;
    analysis.output.accuracy_s_plus = analysis.output.n_correct_s_plus_analysis.trials/analysis.output.n_s_plus_analysis.trials;
    analysis.output.accuracy_s_minus = analysis.output.n_correct_s_minus_analysis.trials/analysis.output.n_s_minus_analysis.trials;
    analysis.output.accuracy = analysis.output.accuracy_s_plus;
    if analysis.output.n_s_minus_analysis.trials~=0
    	analysis.output.accuracy = (analysis.output.accuracy_s_plus*analysis.output.n_s_plus_analysis.trials+analysis.output.accuracy_s_minus*analysis.output.n_s_minus_analysis.trials)/(analysis.output.n_s_plus_analysis.trials+analysis.output.n_s_minus_analysis.trials);
    end
%     analysis.trialidx.ccw = find(analysis.trial.ccw==1);
%     analysis.output.n_ccw_analysis.trials = length(analysis.trialidx.ccw);
%     analysis.trialidx.cw = find(analysis.trial.cw==1);
%     analysis.output.n_cw_analysis.trials = length(analysis.trialidx.cw);
%     analysis.output.n_correct_ccw_analysis.trials = sum(analysis.online_data.response(analysis.trialidx.ccw));
%     analysis.output.n_correct_cw_analysis.trials = sum(analysis.online_data.response(analysis.trialidx.cw));
    analysis.output.n_correct_ccw_analysis.trials = analysis.output.n_correct_s_plusCCW_analysis.trials + analysis.output.n_correct_s_minusCCW_analysis.trials;
    analysis.output.n_correct_cw_analysis.trials = analysis.output.n_correct_s_plusCW_analysis.trials + analysis.output.n_correct_s_minusCW_analysis.trials;
    analysis.output.accuracy_ccw = analysis.output.n_correct_ccw_analysis.trials/(analysis.output.n_s_plusCCW_analysis.trials+analysis.output.n_s_minusCCW_analysis.trials);
    analysis.output.accuracy_cw = analysis.output.n_correct_cw_analysis.trials/(analysis.output.n_s_plusCW_analysis.trials+analysis.output.n_s_minusCW_analysis.trials);
end


% %{
try         % raster plotting
%%%%%%%  Parameters for analysis.rasters    %%%%%%%%%%%%%%%%%%%%
analysis.rasters.spike_line_width=1;         %%%放电raster线条的宽度
analysis.rasters.raster_color=[255 0 0; 255*0.6 255*0.6 255*0.6];        %%%放电raster的颜色 [R G B]
analysis.rasters.spikeHeight=0.8;              %%%
analysis.rasters.graph_length=1000;        %%%整个图的长度（单位：点子数）,此时刚好，spike和LFP的长度为1000点
analysis.rasters.graph_height=600;         %%%整个图的高度（单位：点子数）,此时如果LFPHeight=0.4,则LFP高度为500*0.4=200个点，如果spikeHeight=0.3,则spike高度为500*0.3个点
analysis.rasters.t0=[-15.5 15.5];
analysis.rasters.h=0.015;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
analysis.bin=0.5;
analysis.binleft=analysis.rasters.t0(1):analysis.bin:analysis.rasters.t0(2);

analysis.rasters.spkref = analysis.timestamp.trigger;
analysis.t1=analysis.rasters.spkref+analysis.rasters.t0(1)-0.0005;
analysis.t2=analysis.rasters.spkref+analysis.rasters.t0(2)+0.0005;
analysis.count=zeros(1,length(analysis.binleft));
analysis.f=figure;   % figure 1 
analysis.n_lickinganalysis.trials = 0;
for j=1:1:length(analysis.rasters.spkref)
    analysis.rasters.spk=analysis.timestamp.lick;
    analysis.rasters.spk(analysis.rasters.spk>analysis.t2(j)|analysis.rasters.spk<analysis.t1(j))=[];
    if size(analysis.rasters.spk,1)==0 | size(analysis.rasters.spk,2)==0
        continue
    else
        analysis.rasters.analysis.trial(j).perieventTs=analysis.rasters.spk-analysis.rasters.spkref(j);
        for k=1:1:length(analysis.rasters.spk)
            analysis.x=floor((analysis.rasters.spk(k)-analysis.t1(j))/analysis.bin)+1;
            if analysis.x<=size(analysis.count,2)
            analysis.count(1,analysis.x)=analysis.count(1,analysis.x)+1;
            end
                subplot('position',[0.13,0.95-analysis.rasters.h*j,0.6702668680765358,analysis.rasters.h]);  % figure 1 analysis.rasters
                analysis.rasters.spike_color=analysis.rasters.raster_color(1,:);
                if analysis.trial.s_minus(j)==1
                    analysis.rasters.spike_color=analysis.rasters.raster_color(2,:);
                end
                plot(analysis.rasters.analysis.trial(j).perieventTs(k)*ones(1,2),[0 1],'color',analysis.rasters.spike_color/255,'linewidth',analysis.rasters.spike_line_width);
                hold on;

        end
        if ~isempty(analysis.rasters.analysis.trial(j).perieventTs)
            analysis.n_lickinganalysis.trials = analysis.n_lickinganalysis.trials+1;
        end
    end
    axis([analysis.rasters.t0(1) analysis.rasters.t0(2) 0 1]);
%     set(gca,'xtick',[],'ytick',[],'box','off','xcolor',[1 1 1],'ycolor',[1 1 1]);
%     set(get(gca,'parent'),'color',[1 1 1],'paperunits','points','paperposition',[0 0 analysis.rasters.graph_length analysis.rasters.graph_height]);
    axis off

%         T=analysis.t1(j):bin:analysis.t2(j);
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

analysis.output.analysis.n_lickinganalysis.trials = analysis.n_lickinganalysis.trials;

analysis.rw_idx=find(analysis.binleft>=0&analysis.binleft<=5);
analysis.nrw_idx=find(analysis.binleft<0|analysis.binleft>5);
analysis.output.peak_targeting_index = (max(analysis.firingrate(analysis.rw_idx))-mean(analysis.firingrate(analysis.nrw_idx)))/(3*std(analysis.firingrate(analysis.nrw_idx)));

catch
end

clear i j k;

[analysis.filepath,analysis.filename,analysis.fileext]=fileparts(analysis.bin_fname);

fprintf(['\n' analysis.filename '\n']);
fprintf('n_correct_s_plus_analysis.trials  %i \n', analysis.output.n_correct_s_plus_analysis.trials); 
fprintf('n_correct_s_minus_analysis.trials  %i \n', analysis.output.n_correct_s_minus_analysis.trials);
fprintf('n_correct_ccw_analysis.trials  %i \n', analysis.output.n_correct_ccw_analysis.trials); 
fprintf('n_correct_cw_analysis.trials  %i \n', analysis.output.n_correct_cw_analysis.trials);
fprintf('n_correct_s_plusCCW_analysis.trials  %i \n', analysis.output.n_correct_s_plusCCW_analysis.trials); 
fprintf('n_correct_s_plusCW_analysis.trials  %i \n', analysis.output.n_correct_s_plusCW_analysis.trials);
fprintf('n_correct_s_minusCCW_analysis.trials  %i \n', analysis.output.n_correct_s_minusCCW_analysis.trials); 
fprintf('n_correct_s_minusCW_analysis.trials  %i \n', analysis.output.n_correct_s_minusCW_analysis.trials);
fprintf('\n');
%}