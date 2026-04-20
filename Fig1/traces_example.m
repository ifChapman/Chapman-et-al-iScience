%% plotting sample traces for figs 

% load deconvolved trace
trace_ex = load('109_REC289083_D1awake_BoxHab_DeconTrace.csv');

% z-score for scaling consistency
Decon_Z = zscore(trace_ex, 0, 2);

% gap between traces; adjust as needed for fig aesthetics 
gap = 10;

% create fig, plot one trace at a time from the loop
figure, hold on 

% pretty cells
%good = [1,3,4,5,7,11,13,15,16,19,22,23,24,25,28];
good = [3,4,7,15,16,19,23,24,25,28];
% make i iterate through the cells you want to show
for i = 1:length(good)
    % pull a trace; adjust column index for length of trace to show
    pull = Decon_Z(good(i),1:2000);
    % smooth by rolling mean; makes it look a little cleaner 
    pull = smoothdata(pull, 2,'movmean',5);
    % add gap then add to plot
    pull = pull + i*gap; 
    plot(pull,'LineWidth',1.5);
end
axis off
