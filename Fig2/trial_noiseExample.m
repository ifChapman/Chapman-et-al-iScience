clear

%% sample fig to show amount of activity pre/post trials
load('ProcessedData\InputParameters.mat');
load('ProcessedData\TrialTraces.mat');

% get z-scored trace data for one trial from one animal
pull = TrialTrace_Table(strcmp('REC286239',TrialTrace_Table.Animal) == true &...
    TrialTrace_Table.Day == 1 & TrialTrace_Table.Abs_TrialN == 1,:);
traces_trial = cell2mat(pull.Ztrace_trial_final);

% sort by strongest max in odor window
odor_resp = max(traces_trial(:,(inputValue.trialTrace_Pre*5+1):(inputValue.trialTrace_Pre*5+25)),[],2);
[~,idx] = sort(odor_resp,'descend');
traces_sorted = traces_trial(idx,:);

% make fig
figure,
clim = [-1,4];
imagesc(traces_sorted,clim),
colormap(redblue),
axis off


