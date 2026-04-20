% General point of this code is to reorganize the tables for graphing in
% prism; final output from a chunk is a cell array called "format_final"
% which contains cell arrays for the responses of the odors (rows are
% ordered best to worst). 

%% prism re-org; stand-alone behavior table, average by trialN
clear
load('ProcessedData\tables_compiled_behaviorShifter.mat');

final = cell(1,5);
for i = 1:length(tables_compiled)
    day_now = tables_compiled{i,1};
    odors = unique(day_now.Odor);
    odor_means = cell(8,1);
    for j = 1:8
        avg_odor = day_now.Beh_Index(day_now.TrialN == j,:);
        avg_odor = mean(avg_odor,1,'omitnan');
        odor_means{j,1} = avg_odor;
    end
    final{1,i} = cell2mat(odor_means);
end
final_combined = vertcat(final{:});

%% re-org for either all values or odor-averaging on a day

% flattened contains all trials by day, not averaged; mean_trial contains
% odor averaged values by day
flattened = cell(1,5);
mean_trial = cell(1,5);
for i = 1:length(tables_compiled)
    day_now = final{1,i};
    flattened{1,i} = reshape(day_now,1,size(day_now,2)*size(day_now,1)).';
    mean_trial{1,i} = mean(day_now,2,'omitnan');
end
flattened = cell2mat(flattened);
mean_trial = cell2mat(mean_trial);

%% prism re-org; stand-alone behavior table, average by trialN
clear
load('ProcessedData\tables_compiled_behaviorShifter.mat');

final = cell(1,5);
for i = 1:length(tables_compiled)
    day_now = tables_compiled{i,1};
    odors = unique(day_now.Odor);
    odor_means = cell(8,1);
    for j = 1:8
        avg_odor = day_now.Beh_Index(day_now.TrialN == j,:);
        avg_odor = mean(avg_odor,1,'omitnan');
        odor_means{j,1} = avg_odor;
    end
    final{1,i} = cell2mat(odor_means);
end
final_combined = vertcat(final{:});

%% all points for plotting means vs beh

clear
load('ProcessedData\tables_compiled_behaviorShifter.mat');

final = cell(1,5);
for i = 1:length(tables_compiled)
    day_now = tables_compiled{i,1};
    odors = unique(day_now.Odor);
    odor_means = cell(8,1);
    for j = 1:8
        avg_odor = day_now.Beh_Index(day_now.TrialN == j,:);
        odor_means{j,1} = avg_odor;
    end
    odor_means = cell2mat(odor_means);
    final{1,i} = odor_means(:);
end
final_combined = vertcat(final{:});

load('ProcessedData\tables_compiled.mat')

final = cell(1,5);
for i = 1:length(tables_compiled)
    day_now = tables_compiled{i,1};
    odors = unique(day_now.Odor);
    odor_means = cell(8,1);
    for j = 1:8
        avg_odor = day_now.Deltas(day_now.TrialN == j,:);
        odor_means{j,1} = avg_odor;
    end
    odor_means = cell2mat(odor_means);
    final{1,i} = odor_means(:);
end
final_combined_resp = vertcat(final{:});
