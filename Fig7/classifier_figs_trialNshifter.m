clear
load('ProcessedData\tables_compiled.mat');

%% split simply by trialN

% reorg main table if needed; all days
% re_org = vertcat(tables_compiled{:});
% tables_compiled = cell(2,1);
% tables_compiled{1,1} = re_org(re_org.TrialN < 5,:);
% tables_compiled{2,1} = re_org(re_org.TrialN > 4,:);
% reorg main table, only days 2-5
re_org = vertcat(tables_compiled{2:5});
tables_compiled = cell(2,1);
tables_compiled{1,1} = re_org(re_org.TrialN < 3,:);
tables_compiled{2,1} = re_org(re_org.TrialN > 6,:);
tic
% run within days by iter; params for number of cells/iteration counts
iter_n = 50; % fig 100
starting_n = 50; % fig 50
steps = 50; % fig 25
max_n = 500; % fig 500
jumper = starting_n:steps:max_n;
day_error = cell(1,length(tables_compiled));
day_pct = cell(1,length(tables_compiled));
% set to comparison day for cross-day testing
drop_table_stable = tables_compiled{1,1};
for i = 1:length(tables_compiled)
    day_pull = tables_compiled{i,1};
    day_pull_odors = day_pull.Odor;
    drop_table_deltas = day_pull.Deltas;
    [~,col_drop] = find(isnan(drop_table_deltas));
    drop_table_deltas(:,col_drop) = [];
    % set seed for replicability
    rng(420); % lol
    seed_random = randperm(100000,iter_n);
    pct_by_count = zeros(1,length(jumper));
    error_by_count = zeros(1,length(jumper));
    for k = 1:length(jumper)
        pct_by_iter = zeros(1,iter_n);
        for j = 1:iter_n
            rng(seed_random(j));
            perm_now = randperm(size(drop_table_deltas,2),jumper(k));
            stable_pull = drop_table_stable.Deltas(:,perm_now);
            table_pull = drop_table_deltas(:,perm_now);
            predictions = cell(size(table_pull,1),1);
                for m = 1:size(table_pull,1)
                    % change to stable table for cross days comps
                    drop_table = table_pull;
                    drop_table(m,:) = [];
                    pull_trial = table_pull(m,:);
                    drop_odors = day_pull_odors;
                    drop_odors(m,:) = [];
                    mdl = fitcdiscr(drop_table,drop_odors,'CrossVal','off');
                    label = predict(mdl,pull_trial);
                    predictions{m,1} = label{:};
                    clear label
                end
            correct_log = strcmp(predictions,day_pull_odors);
            pct_by_iter(1,j) = sum(correct_log == 1)/size(table_pull,1)*100;
        end
        pct_by_count(1,k) = mean(pct_by_iter);
        error_by_count(1,k) = std(pct_by_iter,0,'all')/sqrt(length(pct_by_iter));
    end
    day_error{1,i} = error_by_count;
    day_pct{1,i} = pct_by_count;
end
toc

% graph above loop output 
colors = ["black","red"];
figure, 
hold on
for i = 1:length(tables_compiled)
    e(i) = errorbar(1:length(jumper),day_pct{1,i},day_error{1,i});
    e(i).Color = colors(i);
    e(i).LineWidth = 2.5;
end
xlabel('CellN');
ylabel('Percent Correct');
label_all = [0,jumper];
xticklabels(jumper); 
xlim([0 length(jumper)+1]);
ylim([0 100]);
leg = legend('Shifted Delta','Original Delta','Non-Odor Delta','Location','east');
title('Classifier by Day');

%% same but re-sort for behavior first; 50/50 high low

clear
load('ProcessedData\tables_compiled_behaviorShifter.mat');
beh_tables = tables_compiled;
clear tables_compiled
load('ProcessedData\tables_compiled.mat');
load('ProcessedData\PreProcessed.mat');
beh_drop = Animals_All;
beh_drop(strcmp(beh_drop,'NEC273332')==true,:) = [];
day_ranking = cell(length(tables_compiled),1);
for i = 1:length(beh_tables)
    table_now = beh_tables{i,1};
    odor_ranking = cell(length(Odors_All),1);
    for j = 1:length(Odors_All)
        odor_pull = table_now(strcmp(Odors_All(j),table_now.Odor)==true,:);
        [~,idx] = sort(odor_pull.Beh_Index,1,'descend');
        odor_rank_final = zeros(8,length(Animals_All));
        odor_rank_final(:,1:6) = idx(:,1:6);
        odor_rank_final(:,8:end) = idx(:,7:end);
        odor_ranking{j,:} = odor_rank_final;
    end
    day_ranking{i,:} = cell2mat(odor_ranking);
end
animals_neurons = unique(animal_ID);
sorted_deltas  = cell(size(tables_compiled));
for k = 1:length(tables_compiled)
    day_now = tables_compiled{k,:};
    rank_now = day_ranking{k,:};
    deltas_new = zeros(size(day_now.Deltas));
    for i = 1:length(unique(animal_ID))
        animal_now = animals_neurons(i);
        beh_idx_now = rank_now(:,animal_now);
        [~,cells_idx_now] = find(animal_ID == animal_now);
        og_deltas_now = day_now.Deltas(:,cells_idx_now);
        for j = 1:length(Odors_All)
            if unique(beh_idx_now) > 0
                odor_rows = strcmp(day_now.Odor,Odors_All(j));
                odor_deltas_now = day_now.Deltas(find(odor_rows==1),:);
                re_org_now = odor_deltas_now(beh_idx_now(j*8-7:j*8),:);
                deltas_new(find(odor_rows==1),cells_idx_now) = re_org_now(:,cells_idx_now);
            end
        end
    end
    day_now.Deltas = deltas_new;
    sorted_deltas{k,1} = day_now;
end

re_org = vertcat(sorted_deltas{2:5});
tables_compiled = cell(2,1);
tables_compiled{1,1} = re_org(re_org.TrialN < 5,:);
tables_compiled{2,1} = re_org(re_org.TrialN > 4,:);
tic
% run within days by iter; params for number of cells/iteration counts
iter_n = 100; 
starting_n = 50;
steps = 25; 
max_n = 500;
jumper = starting_n:steps:max_n;
day_error = cell(1,length(tables_compiled));
day_pct = cell(1,length(tables_compiled));
% set to comparison day for cross-day testing
drop_table_stable = tables_compiled{1,1};
for i = 1:length(tables_compiled)
    day_pull = tables_compiled{i,1};
    day_pull_odors = day_pull.Odor;
    drop_table_deltas = day_pull.Deltas;
    [~,col_drop] = find(isnan(drop_table_deltas));
    drop_table_deltas(:,col_drop) = [];
    % drop animal in table that doesn't have behavior
    col_drop = sum(drop_table_deltas,1) == 0;
    drop_table_deltas(:,col_drop==1) = [];
    % set seed for replicability
    rng(420); % lol
    seed_random = randperm(100000,iter_n);
    pct_by_count = zeros(1,length(jumper));
    error_by_count = zeros(1,length(jumper));
    for k = 1:length(jumper)
        pct_by_iter = zeros(1,iter_n);
        for j = 1:iter_n
            rng(seed_random(j));
            perm_now = randperm(size(drop_table_deltas,2),jumper(k));
            stable_pull = drop_table_stable.Deltas(:,perm_now);
            table_pull = drop_table_deltas(:,perm_now);
            predictions = cell(size(table_pull,1),1);
                for m = 1:size(table_pull,1)
                    % change to stable table for cross days comps
                    drop_table = table_pull;
                    drop_table(m,:) = [];
                    pull_trial = table_pull(m,:);
                    drop_odors = day_pull_odors;
                    drop_odors(m,:) = [];
                    mdl = fitcdiscr(drop_table,drop_odors,'CrossVal','off');
                    label = predict(mdl,pull_trial);
                    predictions{m,1} = label{:};
                    clear label
                end
            correct_log = strcmp(predictions,day_pull_odors);
            pct_by_iter(1,j) = sum(correct_log == 1)/size(table_pull,1)*100;
        end
        pct_by_count(1,k) = mean(pct_by_iter);
        error_by_count(1,k) = std(pct_by_iter,0,'all')/sqrt(length(pct_by_iter));
    end
    day_error{1,i} = error_by_count;
    day_pct{1,i} = pct_by_count;
end
toc

% graph above loop output 
colors = ["black","red"];
figure, 
hold on
for i = 1:length(tables_compiled)
    e(i) = errorbar(1:length(jumper),day_pct{1,i},day_error{1,i});
    e(i).Color = colors(i);
    e(i).LineWidth = 2.5;
end
xlabel('CellN');
ylabel('Percent Correct');
label_all = [0,jumper];
xticklabels(jumper); 
xlim([0 length(jumper)+1]);
ylim([0 100]);
title('Classifier by Day');

% save('classifier_behSort_d2thru5_50v50.mat');

%% same but re-sort for behavior first; top2 bottom two each day
clear
load('ProcessedData\tables_compiled_behaviorShifter.mat');
beh_tables = tables_compiled;
clear tables_compiled
load('ProcessedData\tables_compiled.mat');
load('ProcessedData\PreProcessed.mat');

beh_drop = Animals_All;
beh_drop(strcmp(beh_drop,'NEC273332')==true,:) = [];
day_ranking = cell(length(tables_compiled),1);
for i = 1:length(beh_tables)
    table_now = beh_tables{i,1};
    odor_ranking = cell(length(Odors_All),1);
    for j = 1:length(Odors_All)
        odor_pull = table_now(strcmp(Odors_All(j),table_now.Odor)==true,:);
        [~,idx] = sort(odor_pull.Beh_Index,1,'descend');
        odor_rank_final = zeros(8,length(Animals_All));
        odor_rank_final(:,1:6) = idx(:,1:6);
        odor_rank_final(:,8:end) = idx(:,7:end);
        odor_ranking{j,:} = odor_rank_final;
    end
    day_ranking{i,:} = cell2mat(odor_ranking);
end
animals_neurons = unique(animal_ID);
sorted_deltas  = cell(size(tables_compiled));
for k = 1:length(tables_compiled)
    day_now = tables_compiled{k,:};
    rank_now = day_ranking{k,:};
    deltas_new = zeros(size(day_now.Deltas));
    for i = 1:length(unique(animal_ID))
        animal_now = animals_neurons(i);
        beh_idx_now = rank_now(:,animal_now);
        [~,cells_idx_now] = find(animal_ID == animal_now);
        og_deltas_now = day_now.Deltas(:,cells_idx_now);
        for j = 1:length(Odors_All)
            if unique(beh_idx_now) > 0
                odor_rows = strcmp(day_now.Odor,Odors_All(j));
                odor_deltas_now = day_now.Deltas(find(odor_rows==1),:);
                re_org_now = odor_deltas_now(beh_idx_now(j*8-7:j*8),:);
                deltas_new(find(odor_rows==1),cells_idx_now) = re_org_now(:,cells_idx_now);
            end
        end
    end
    day_now.Deltas = deltas_new;
    sorted_deltas{k,1} = day_now;
end

re_org = vertcat(sorted_deltas{2:5});
tables_compiled = cell(2,1);
tables_compiled{1,1} = re_org(re_org.TrialN < 3,:);
tables_compiled{2,1} = re_org(re_org.TrialN > 6,:);
tic
% run within days by iter; params for number of cells/iteration counts
iter_n = 100; % fig 100
starting_n = 50; % fig 50
steps = 25; % fig 25
max_n = 500; % fig 500
jumper = starting_n:steps:max_n;
day_error = cell(1,length(tables_compiled));
day_pct = cell(1,length(tables_compiled));
% set to comparison day for cross-day testing
drop_table_stable = tables_compiled{1,1};
for i = 1:length(tables_compiled)
    day_pull = tables_compiled{i,1};
    day_pull_odors = day_pull.Odor;
    drop_table_deltas = day_pull.Deltas;
    [~,col_drop] = find(isnan(drop_table_deltas));
    drop_table_deltas(:,col_drop) = [];
    % drop animal in table that doesn't have behavior
    col_drop = sum(drop_table_deltas,1) == 0;
    drop_table_deltas(:,col_drop==1) = [];
    % set seed for replicability
    rng(420); % lol
    seed_random = randperm(100000,iter_n);
    pct_by_count = zeros(1,length(jumper));
    error_by_count = zeros(1,length(jumper));
    for k = 1:length(jumper)
        pct_by_iter = zeros(1,iter_n);
        for j = 1:iter_n
            rng(seed_random(j));
            perm_now = randperm(size(drop_table_deltas,2),jumper(k));
            stable_pull = drop_table_stable.Deltas(:,perm_now);
            table_pull = drop_table_deltas(:,perm_now);
            predictions = cell(size(table_pull,1),1);
                for m = 1:size(table_pull,1)
                    % change to stable table for cross days comps
                    drop_table = table_pull;
                    drop_table(m,:) = [];
                    pull_trial = table_pull(m,:);
                    drop_odors = day_pull_odors;
                    drop_odors(m,:) = [];
                    mdl = fitcdiscr(drop_table,drop_odors,'CrossVal','off');
                    label = predict(mdl,pull_trial);
                    predictions{m,1} = label{:};
                    clear label
                end
            correct_log = strcmp(predictions,day_pull_odors);
            pct_by_iter(1,j) = sum(correct_log == 1)/size(table_pull,1)*100;
        end
        pct_by_count(1,k) = mean(pct_by_iter);
        error_by_count(1,k) = std(pct_by_iter,0,'all')/sqrt(length(pct_by_iter));
    end
    day_error{1,i} = error_by_count;
    day_pct{1,i} = pct_by_count;
end
toc

% graph above loop output 
colors = ["black","red"];
figure, 
hold on
for i = 1:length(tables_compiled)
    e(i) = errorbar(1:length(jumper),day_pct{1,i},day_error{1,i});
    e(i).Color = colors(i);
    e(i).LineWidth = 2.5;
end
xlabel('CellN');
ylabel('Percent Correct');
label_all = [0,jumper];
xticklabels(jumper); 
xlim([0 length(jumper)+1]);
ylim([0 100]);
title('Classifier by Day');

save('Fig7\classifier_behSort_d2thru5_25v25.mat');

%% same but re-sort for behavior first; top2/bottom two each day
clear
load('Data\7s_shifterWindow\tables_compiled_behaviorShifter.mat');
beh_tables = tables_compiled;
clear tables_compiled
load('Data\7s_shifterWindow\tables_compiled.mat');
load('Data\7s_shifterWindow\PreProcessed.mat');
beh_drop = Animals_All;
beh_drop(strcmp(beh_drop,'NEC273332')==true,:) = [];
day_ranking = cell(length(tables_compiled),1);
for i = 1:length(beh_tables)
    table_now = beh_tables{i,1};
    odor_ranking = cell(length(Odors_All),1);
    for j = 1:length(Odors_All)
        odor_pull = table_now(strcmp(Odors_All(j),table_now.Odor)==true,:);
        [~,idx] = sort(odor_pull.Beh_Index,1,'descend');
        odor_rank_final = zeros(8,length(Animals_All));
        odor_rank_final(:,1:6) = idx(:,1:6);
        odor_rank_final(:,8:end) = idx(:,7:end);
        odor_ranking{j,:} = odor_rank_final;
    end
    day_ranking{i,:} = cell2mat(odor_ranking);
end
animals_neurons = unique(animal_ID);
sorted_deltas  = cell(size(tables_compiled));
for k = 1:length(tables_compiled)
    day_now = tables_compiled{k,:};
    rank_now = day_ranking{k,:};
    deltas_new = zeros(size(day_now.Deltas));
    for i = 1:length(unique(animal_ID))
        animal_now = animals_neurons(i);
        beh_idx_now = rank_now(:,animal_now);
        [~,cells_idx_now] = find(animal_ID == animal_now);
        og_deltas_now = day_now.Deltas(:,cells_idx_now);
        for j = 1:length(Odors_All)
            if unique(beh_idx_now) > 0
                odor_rows = strcmp(day_now.Odor,Odors_All(j));
                odor_deltas_now = day_now.Deltas(find(odor_rows==1),:);
                re_org_now = odor_deltas_now(beh_idx_now(j*8-7:j*8),:);
                deltas_new(find(odor_rows==1),cells_idx_now) = re_org_now(:,cells_idx_now);
            end
        end
    end
    day_now.Deltas = deltas_new;
    sorted_deltas{k,1} = day_now;
end

re_org = vertcat(sorted_deltas{2:5});
tables_compiled = cell(2,1);
tables_compiled{1,1} = re_org(re_org.TrialN < 3,:);
tables_compiled{2,1} = re_org(re_org.TrialN > 6,:);
tic
% run within days by iter; params for number of cells/iteration counts
iter_n = 100; % 100 fig
starting_n = 50; % 50 fig
steps = 25; % 25 fig
max_n = 500; % 500 fig
jumper = starting_n:steps:max_n;
day_error = cell(1,length(tables_compiled));
day_pct = cell(1,length(tables_compiled));
% set to comparison day for cross-day testing
drop_table_stable = tables_compiled{1,1};
for i = 1:length(tables_compiled)
    day_pull = tables_compiled{i,1};
    day_pull_odors = day_pull.Odor;
    drop_table_deltas = day_pull.Deltas;
    [~,col_drop] = find(isnan(drop_table_deltas));
    drop_table_deltas(:,col_drop) = [];
    % drop animal in table that doesn't have behavior
    col_drop = sum(drop_table_deltas,1) == 0;
    drop_table_deltas(:,col_drop==1) = [];
    % set seed for replicability
    rng(420); % lol
    seed_random = randperm(100000,iter_n);
    pct_by_count = zeros(1,length(jumper));
    error_by_count = zeros(1,length(jumper));
    for k = 1:length(jumper)
        pct_by_iter = zeros(1,iter_n);
        for j = 1:iter_n
            rng(seed_random(j));
            perm_now = randperm(size(drop_table_deltas,2),jumper(k));
            stable_pull = drop_table_stable.Deltas(:,perm_now);
            table_pull = drop_table_deltas(:,perm_now);
            predictions = cell(size(table_pull,1),1);
                for m = 1:size(table_pull,1)
                    % change to stable table for cross days comps
                    drop_table = table_pull;
                    drop_table(m,:) = [];
                    pull_trial = table_pull(m,:);
                    drop_odors = day_pull_odors;
                    drop_odors(m,:) = [];
                    mdl = fitcdiscr(drop_table,drop_odors,'CrossVal','off');
                    label = predict(mdl,pull_trial);
                    predictions{m,1} = label{:};
                    clear label
                end
            correct_log = strcmp(predictions,day_pull_odors);
            pct_by_iter(1,j) = sum(correct_log == 1)/size(table_pull,1)*100;
        end
        pct_by_count(1,k) = mean(pct_by_iter);
        error_by_count(1,k) = std(pct_by_iter,0,'all')/sqrt(length(pct_by_iter));
    end
    day_error{1,i} = error_by_count;
    day_pct{1,i} = pct_by_count;
end
toc

% graph above loop output 
colors = ["black","red"];
figure, 
hold on
for i = 1:length(tables_compiled)
    e(i) = errorbar(1:length(jumper),day_pct{1,i},day_error{1,i});
    e(i).Color = colors(i);
    e(i).LineWidth = 2.5;
end
xlabel('CellN');
ylabel('Percent Correct');
label_all = [0,jumper];
xticklabels(jumper); 
xlim([0 length(jumper)+1]);
ylim([0 100]);
title('Classifier by Day');

save('Data\7s_shifterWindow\classifier_behSort_d2thru5_t1only.mat');

%% same but re-sort for old behavior first; top2 bottom two each day
clear
load('Data\7s_shifterWindow\tables_compiled_behaviorOG.mat');
beh_tables = tables_compiled;
clear tables_compiled
load('Data\7s_shifterWindow\tables_compiled.mat');
load('Data\7s_shifterWindow\PreProcessed.mat');
beh_drop = Animals_All;
beh_drop(strcmp(beh_drop,'NEC273332')==true,:) = [];
day_ranking = cell(length(tables_compiled),1);
for i = 1:length(beh_tables)
    table_now = beh_tables{i,1};
    odor_ranking = cell(length(Odors_All),1);
    for j = 1:length(Odors_All)
        odor_pull = table_now(strcmp(Odors_All(j),table_now.Odor)==true,:);
        [~,idx] = sort(odor_pull.Beh_Index,1,'descend');
        odor_rank_final = zeros(8,length(Animals_All));
        odor_rank_final(:,1:6) = idx(:,1:6);
        odor_rank_final(:,8:end) = idx(:,7:end);
        odor_ranking{j,:} = odor_rank_final;
    end
    day_ranking{i,:} = cell2mat(odor_ranking);
end
animals_neurons = unique(animal_ID);
sorted_deltas  = cell(size(tables_compiled));
for k = 1:length(tables_compiled)
    day_now = tables_compiled{k,:};
    rank_now = day_ranking{k,:};
    deltas_new = zeros(size(day_now.Deltas));
    for i = 1:length(unique(animal_ID))
        animal_now = animals_neurons(i);
        beh_idx_now = rank_now(:,animal_now);
        [~,cells_idx_now] = find(animal_ID == animal_now);
        og_deltas_now = day_now.Deltas(:,cells_idx_now);
        for j = 1:length(Odors_All)
            if unique(beh_idx_now) > 0
                odor_rows = strcmp(day_now.Odor,Odors_All(j));
                odor_deltas_now = day_now.Deltas(find(odor_rows==1),:);
                re_org_now = odor_deltas_now(beh_idx_now(j*8-7:j*8),:);
                deltas_new(find(odor_rows==1),cells_idx_now) = re_org_now(:,cells_idx_now);
            end
        end
    end
    day_now.Deltas = deltas_new;
    sorted_deltas{k,1} = day_now;
end

re_org = vertcat(sorted_deltas{2:5});
tables_compiled = cell(2,1);
tables_compiled{1,1} = re_org(re_org.TrialN < 3,:);
tables_compiled{2,1} = re_org(re_org.TrialN > 6,:);
tic
% run within days by iter; params for number of cells/iteration counts
iter_n = 10; 
starting_n = 50;
steps = 25; 
max_n = 500;
jumper = starting_n:steps:max_n;
day_error = cell(1,length(tables_compiled));
day_pct = cell(1,length(tables_compiled));
% set to comparison day for cross-day testing
drop_table_stable = tables_compiled{1,1};
for i = 1:length(tables_compiled)
    day_pull = tables_compiled{i,1};
    day_pull_odors = day_pull.Odor;
    drop_table_deltas = day_pull.Deltas;
    [~,col_drop] = find(isnan(drop_table_deltas));
    drop_table_deltas(:,col_drop) = [];
    % drop animal in table that doesn't have behavior
    col_drop = sum(drop_table_deltas,1) == 0;
    drop_table_deltas(:,col_drop==1) = [];
    % set seed for replicability
    rng(420); % lol
    seed_random = randperm(100000,iter_n);
    pct_by_count = zeros(1,length(jumper));
    error_by_count = zeros(1,length(jumper));
    for k = 1:length(jumper)
        pct_by_iter = zeros(1,iter_n);
        for j = 1:iter_n
            rng(seed_random(j));
            perm_now = randperm(size(drop_table_deltas,2),jumper(k));
            stable_pull = drop_table_stable.Deltas(:,perm_now);
            table_pull = drop_table_deltas(:,perm_now);
            predictions = cell(size(table_pull,1),1);
                for m = 1:size(table_pull,1)
                    % change to stable table for cross days comps
                    drop_table = table_pull;
                    drop_table(m,:) = [];
                    pull_trial = table_pull(m,:);
                    drop_odors = day_pull_odors;
                    drop_odors(m,:) = [];
                    mdl = fitcdiscr(drop_table,drop_odors,'CrossVal','off');
                    label = predict(mdl,pull_trial);
                    predictions{m,1} = label{:};
                    clear label
                end
            correct_log = strcmp(predictions,day_pull_odors);
            pct_by_iter(1,j) = sum(correct_log == 1)/size(table_pull,1)*100;
        end
        pct_by_count(1,k) = mean(pct_by_iter);
        error_by_count(1,k) = std(pct_by_iter,0,'all')/sqrt(length(pct_by_iter));
    end
    day_error{1,i} = error_by_count;
    day_pct{1,i} = pct_by_count;
end
toc

% graph above loop output 
colors = ["black","red"];
figure, 
hold on
for i = 1:length(tables_compiled)
    e(i) = errorbar(1:length(jumper),day_pct{1,i},day_error{1,i});
    e(i).Color = colors(i);
    e(i).LineWidth = 2.5;
end
xlabel('CellN');
ylabel('Percent Correct');
label_all = [0,jumper];
xticklabels(jumper); 
xlim([0 length(jumper)+1]);
ylim([0 100]);
title('Classifier by Day');

%% same but re-sort for old behavior first; top2 bottom two each day
clear
load('tables_compiled_behaviorFull.mat');
beh_tables = tables_compiled;
clear tables_compiled
load('tables_compiled.mat');
load('PreProcessed.mat');
beh_drop = Animals_All;
beh_drop(strcmp(beh_drop,'NEC273332')==true,:) = [];
day_ranking = cell(length(tables_compiled),1);
for i = 1:length(beh_tables)
    table_now = beh_tables{i,1};
    odor_ranking = cell(length(Odors_All),1);
    for j = 1:length(Odors_All)
        odor_pull = table_now(strcmp(Odors_All(j),table_now.Odor)==true,:);
        [~,idx] = sort(odor_pull.Beh_Index,1,'descend');
        odor_rank_final = zeros(8,length(Animals_All));
        odor_rank_final(:,1:6) = idx(:,1:6);
        odor_rank_final(:,8:end) = idx(:,7:end);
        odor_ranking{j,:} = odor_rank_final;
    end
    day_ranking{i,:} = cell2mat(odor_ranking);
end
animals_neurons = unique(animal_ID);
sorted_deltas  = cell(size(tables_compiled));
for k = 1:length(tables_compiled)
    day_now = tables_compiled{k,:};
    rank_now = day_ranking{k,:};
    deltas_new = zeros(size(day_now.Deltas));
    for i = 1:length(unique(animal_ID))
        animal_now = animals_neurons(i);
        beh_idx_now = rank_now(:,animal_now);
        [~,cells_idx_now] = find(animal_ID == animal_now);
        og_deltas_now = day_now.Deltas(:,cells_idx_now);
        for j = 1:length(Odors_All)
            if unique(beh_idx_now) > 0
                odor_rows = strcmp(day_now.Odor,Odors_All(j));
                odor_deltas_now = day_now.Deltas(find(odor_rows==1),:);
                re_org_now = odor_deltas_now(beh_idx_now(j*8-7:j*8),:);
                deltas_new(find(odor_rows==1),cells_idx_now) = re_org_now(:,cells_idx_now);
            end
        end
    end
    day_now.Deltas = deltas_new;
    sorted_deltas{k,1} = day_now;
end

re_org = vertcat(sorted_deltas{2:5});
tables_compiled = cell(2,1);
tables_compiled{1,1} = re_org(re_org.TrialN < 3,:);
tables_compiled{2,1} = re_org(re_org.TrialN > 6,:);
tic
% run within days by iter; params for number of cells/iteration counts
iter_n = 10; 
starting_n = 50;
steps = 25; 
max_n = 500;
jumper = starting_n:steps:max_n;
day_error = cell(1,length(tables_compiled));
day_pct = cell(1,length(tables_compiled));
% set to comparison day for cross-day testing
drop_table_stable = tables_compiled{1,1};
for i = 1:length(tables_compiled)
    day_pull = tables_compiled{i,1};
    day_pull_odors = day_pull.Odor;
    drop_table_deltas = day_pull.Deltas;
    [~,col_drop] = find(isnan(drop_table_deltas));
    drop_table_deltas(:,col_drop) = [];
    % drop animal in table that doesn't have behavior
    col_drop = sum(drop_table_deltas,1) == 0;
    drop_table_deltas(:,col_drop==1) = [];
    % set seed for replicability
    rng(420); % lol
    seed_random = randperm(100000,iter_n);
    pct_by_count = zeros(1,length(jumper));
    error_by_count = zeros(1,length(jumper));
    for k = 1:length(jumper)
        pct_by_iter = zeros(1,iter_n);
        for j = 1:iter_n
            rng(seed_random(j));
            perm_now = randperm(size(drop_table_deltas,2),jumper(k));
            stable_pull = drop_table_stable.Deltas(:,perm_now);
            table_pull = drop_table_deltas(:,perm_now);
            predictions = cell(size(table_pull,1),1);
                for m = 1:size(table_pull,1)
                    % change to stable table for cross days comps
                    drop_table = table_pull;
                    drop_table(m,:) = [];
                    pull_trial = table_pull(m,:);
                    drop_odors = day_pull_odors;
                    drop_odors(m,:) = [];
                    mdl = fitcdiscr(drop_table,drop_odors,'CrossVal','off');
                    label = predict(mdl,pull_trial);
                    predictions{m,1} = label{:};
                    clear label
                end
            correct_log = strcmp(predictions,day_pull_odors);
            pct_by_iter(1,j) = sum(correct_log == 1)/size(table_pull,1)*100;
        end
        pct_by_count(1,k) = mean(pct_by_iter);
        error_by_count(1,k) = std(pct_by_iter,0,'all')/sqrt(length(pct_by_iter));
    end
    day_error{1,i} = error_by_count;
    day_pct{1,i} = pct_by_count;
end
toc

% graph above loop output 
colors = ["black","red"];
figure, 
hold on
for i = 1:length(tables_compiled)
    e(i) = errorbar(1:length(jumper),day_pct{1,i},day_error{1,i});
    e(i).Color = colors(i);
    e(i).LineWidth = 2.5;
end
xlabel('CellN');
ylabel('Percent Correct');
label_all = [0,jumper];
xticklabels(jumper); 
xlim([0 length(jumper)+1]);
ylim([0 100]);
title('Classifier by Day');
