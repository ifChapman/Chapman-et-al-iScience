clear
%% reorg behaviors to odor average for overall fig
% deltas index
load('ProcessedData\tables_compiled.mat');
final_output = cell(5,1);
animals = unique(animal_ID);
for i = 1:length(tables_compiled)
    day_now = tables_compiled{i,1};
    trials_all = unique(day_now.TrialN);
    pull_day = zeros(length(trials_all),length(animals));
    for k = 1:length(animals)
    log_now = animal_ID == animals(k);
        for j = 1:length(trials_all)
            pull = mean(day_now.Deltas(day_now.TrialN == j,:),1,'omitnan');
            pull = pull(:,log_now==1);
            pull_day(j,k) = mean(pull,'all','omitnan');
        end
    end
    final_output{i,1} = pull_day; % copied to prism for byTrial when needed 
end

flattened = cell(1,5);
mean_trial = cell(1,5);
for i = 1:length(tables_compiled)
    day_now = final_output{i,1};
    flattened{1,i} = reshape(day_now,1,size(day_now,2)*size(day_now,1)).';
    mean_trial{1,i} = mean(day_now,2);
end
flattened = cell2mat(flattened); % copied to prism for byDay 
mean_trial = cell2mat(mean_trial);

%% responder values
clear tables_compiled
load('ProcessedData\tables_compiled_responders.mat');
final_output = cell(5,1);
animals = unique(animal_ID);
for i = 1:length(tables_compiled)
    day_now = tables_compiled{i,1};
    trials_all = unique(day_now.TrialN);
    pull_day = zeros(length(trials_all),length(animals));
    for k = 1:length(animals)
    log_now = animal_ID == animals(k);
        for j = 1:length(trials_all)
            pull = mean(day_now.Deltas(day_now.TrialN == j,:),1,'omitnan');
            pull = pull(:,log_now==1);
            pull_day(j,k) = mean(pull,'all','omitnan');
        end
    end
    final_output{i,1} = pull_day; % copied to prism for byTrial when needed %
end

flattened = cell(1,5);
mean_trial = cell(1,5);
for i = 1:length(tables_compiled)
    day_now = final_output{i,1};
    flattened{1,i} = reshape(day_now,1,size(day_now,2)*size(day_now,1)).';
    mean_trial{1,i} = mean(day_now,2);
end
flattened = cell2mat(flattened); % copied to prism for byDay 
mean_trial = cell2mat(mean_trial);

%% percent responders
clear tables_compiled
load('ProcessedData\tables_compiled_responders.mat');
final_output = cell(5,1);
animals = unique(animal_ID);
for i = 1:length(tables_compiled)
    day_now = tables_compiled{i,1};
    trials_all = unique(day_now.TrialN);
    pull_day = zeros(length(trials_all),length(animals));
    for k = 1:length(animals)
    log_now = animal_ID == animals(k);
        for j = 1:length(trials_all)
            pull = day_now.Deltas(day_now.TrialN == j,:);
            pull = pull(:,log_now==1);
            pct = sum(~isnan(pull),2) ./ size(pull,2);
            pull_day(j,k) = mean(pct,'all','omitnan')*100;
        end
    end
    final_output{i,1} = pull_day; % copied to prism for byTrial when needed %
end

flattened = cell(1,5);
mean_trial = cell(1,5);
for i = 1:length(tables_compiled)
    day_now = final_output{i,1};
    flattened{1,i} = reshape(day_now,1,size(day_now,2)*size(day_now,1)).';
    mean_trial{1,i} = mean(day_now,2);
end
flattened = cell2mat(flattened); % copied to prism for byDay 
mean_trial = cell2mat(mean_trial);

