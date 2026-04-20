%% plotting sample traces for figs 

% load deconvolved trace
trace_ex = load("085_LEC286239_D1awake_DeconTrace.csv");
times = readtable("085_LEC286239_D1awake_notes.csv");
% z-score for scaling consistency
Decon_Z = zscore(trace_ex, 0, 2);
frames_odors = ceil(times.Var1/1000*5);

% gap between traces; adjust as needed for fig aesthetics 
gap = 10;

% create fig, plot one trace at a time from the loop
figure, hold on 

% pretty cells

%good = [1,3,4,5,7,11,13,15,16,19,22,23,24,25,28];
% picked = [3,4,7,15,16,19,23,24,25,28,29,30,31];
picked = 1:30;
[vals,idx] = sort(mean(Decon_Z(:,frames_odors(1):frames_odors(1)+50),2),'descend');
% make i iterate through the cells you want to show
for i = 1:length(picked)
    % pull a trace; adjust column index for length of trace to show
    pull = Decon_Z(idx(i),2800:3200);
    % smooth by rolling mean; makes it look a little cleaner 
    pull = smoothdata(pull, 2,'movmean',5);
    % add gap then add to plot
    pull = pull - i*gap; 
    plot(pull,'LineWidth',1.5);
end

for i=1:sum(frames_odors<3200)
    time_now = (frames_odors(i)-2800);
    pos = [time_now, -300, 1, 400];
    rectangle('Position', pos, ...
              'FaceColor', [1,1,1])
end
axis off

gap = 10;

% create fig, plot one trace at a time from the loop
figure, hold on 

% pretty cells

%good = [1,3,4,5,7,11,13,15,16,19,22,23,24,25,28];
% picked = [3,4,7,15,16,19,23,24,25,28,29,30,31];
picked = 1:30;
[vals,idx] = sort(mean(Decon_Z(:,frames_odors(2):frames_odors(2)+50),2),'descend');
% make i iterate through the cells you want to show
for i = 1:length(picked)
    % pull a trace; adjust column index for length of trace to show
    pull = Decon_Z(idx(i),frames_odors(2)-100:frames_odors(2)+100);
    % smooth by rolling mean; makes it look a little cleaner 
    pull = smoothdata(pull, 2,'movmean',5);
    % add gap then add to plot
    pull = pull - i*gap; 
    plot(pull,'LineWidth',1.5);
end

time_now = (frames_odors(2)-frames_odors(2)+200);
pos = [time_now, -300, 1, 400];
rectangle('Position', pos, ...
          'FaceColor', [1,1,1])
axis off


% first five trials, best 40 resonders
for trial = 1:5
figure, hold on
%good = [1,3,4,5,7,11,13,15,16,19,22,23,24,25,28];
% picked = [3,4,7,15,16,19,23,24,25,28,29,30,31];
picked = 1:40;
delta = (max(Decon_Z(:,frames_odors(trial):frames_odors(trial)+25),[],2))-mean(Decon_Z(:,frames_odors(trial):frames_odors(trial)+10),2)
[vals,idx] = sort(delta,'descend');
% make i iterate through the cells you want to show
for i = 1:length(picked)
    % pull a trace; adjust column index for length of trace to show
    pull = Decon_Z(idx(i),frames_odors(trial)-100:frames_odors(trial)+100);
    % smooth by rolling mean; makes it look a little cleaner 
    pull = smoothdata(pull, 2,'movmean',5);
    % add gap then add to plot
    pull = pull - i*gap; 
    plot(pull,'LineWidth',1.5);
end

time_now = (frames_odors(trial)-frames_odors(trial)+100);
pos = [time_now, -500, 1, 700];
rectangle('Position', pos, ...
          'FaceColor', [1,1,1])
axis off

end


% 5 random times pre-odors, best 40 resonders

frames_pre = randi([0,3000], 1, 5); % 1425, 878, 192 in figure
for trial = 1:3
figure, hold on
%good = [1,3,4,5,7,11,13,15,16,19,22,23,24,25,28];
% picked = [3,4,7,15,16,19,23,24,25,28,29,30,31];
picked = 1:40;
delta = (max(Decon_Z(:,frames_pre(trial):frames_pre(trial)+25),[],2))-mean(Decon_Z(:,frames_pre(trial):frames_pre(trial)+10),2)
[vals,idx] = sort(delta,'descend');
% make i iterate through the cells you want to show
for i = 1:length(picked)
    % pull a trace; adjust column index for length of trace to show
    pull = Decon_Z(idx(i),frames_pre(trial)-100:frames_pre(trial)+100);
    % smooth by rolling mean; makes it look a little cleaner 
    pull = smoothdata(pull, 2,'movmean',5);
    % add gap then add to plot
    pull = pull - i*gap; 
    plot(pull,'LineWidth',1.5);
end

time_now = (frames_pre(trial)-frames_pre(trial)+100);
pos = [time_now, -500, 1, 700];
rectangle('Position', pos, ...
          'FaceColor', [1,1,1])
axis off

end



