% Final output is in a cell array called "best_day" for moving to prism.
% Regardless of which chunk you run, best_day is organized as a cell array
% for each day, which contains cell arrays for cells best responsive to
% each odor (nested). Odor always follows the order of Odors_All for arrays
% 1-6. Final numbers are trial averaged for each cell.  

clear
load('ProcessedData\tables_compiled.mat')
%% calculate sparsness for each cell
trial_cutoff = 8;
Sparseness_Lifetime = zeros(size(tables_compiled{1,1}.Deltas,2),5);
responsive_cutoff = 1; 
responsive_any = zeros(size(tables_compiled{1,1}.Deltas,2),5);
Max_Day = zeros(size(tables_compiled{1,1}.Deltas,2),5);
for j = 1:5
    Dnow_deltas = tables_compiled{j,1}.Deltas;
    odor_avgs = zeros(length(unique(tables_compiled{1,1}.Odor)),size(Dnow_deltas,2));
    for i = 1:length(unique(tables_compiled{1,1}.Odor))
        odor_pull = Dnow_deltas(i*trial_cutoff-(trial_cutoff-1):i*trial_cutoff,:);
        odor_avgs(i,:) = median(odor_pull,1);
    end
    odor_avgs = odor_avgs.';
    odor_avgs = max(odor_avgs,0);
    % do lifetime sparseness; broken in chunks as i cant read gud
    piece1 = sum((odor_avgs ./ size(odor_avgs,2)),2).^2;
    piece2 = sum((odor_avgs.^2 ./ size(odor_avgs,2)),2);
    Sparseness_Lifetime(:,j) = (1-(piece1./piece2))/(1-1/size(odor_avgs,2));
    Max_Day(:,j) = max(odor_avgs,[],2);
    responsive_any(:,j) = sum(odor_avgs > responsive_cutoff,2) > 0;
end
Max_Day = Max_Day.';
responsive_any = responsive_any.';
Sparseness_Lifetime = Sparseness_Lifetime.';
% added line to convert nan to 0; nan are result of cell as a negative on
% all trials, so across the board zeros are a sparsness of 0 
Sparseness_Lifetime(isnan(Sparseness_Lifetime)) = 0;

% population sparseness
piece1_pop = sum((odor_avgs ./ size(odor_avgs,1)),1).^2;
piece2_pop = sum((odor_avgs.^2 ./ size(odor_avgs,1)),1);
Sparseness_Population = (1-(piece1_pop./piece2_pop))/(1-1/size(odor_avgs,1));

%% sort cells by best tuned response on D1 and most narrowly tuned D1 cells

% best sort on D1 by magnitude; best_idx is final index file
Odors_All = unique(tables_compiled{1,1}.Odor);
D1_pull = tables_compiled{1,1}.Deltas;
avg_D1 = cell(1,length(Odors_All));
for i = 1:length(Odors_All)
    odors_now = D1_pull;
    odors_now = odors_now(i*8-7:i*8,:);
    odor_avg = median(odors_now,1,'omitnan');
    avg_D1{1,i} = odor_avg;
end
avg_D1 = cell2mat(avg_D1.');
[value,best_idx] = max(avg_D1,[],1,'omitnan');

% average response mag to each odor; sorting only by D1 best and only using
% the n = cutoff_sparse most narrowly tuned cells on D1
cutoff_sparse = ceil(size(tables_compiled{1,1}.Deltas,2)/5); % num cells to keep 
day_sparse = 1; % day to use for sparseness values 
Day_sparsensss = Sparseness_Lifetime(day_sparse,:);
[sorted,Day_idx] = sort(Day_sparsensss,'descend');
day_now_sparse_cutoff = sorted(cutoff_sparse+1);
day_now_SparseLog = Day_sparsensss > day_now_sparse_cutoff;
best_day = cell(1,5);
for d = 1:5
    day_now = tables_compiled{d,1}.Deltas;
    odor_best = cell(1,6);
    for i = 1:length(Odors_All)
        best_now_log = best_idx == i;
        odor_holder = cell(1,6);
        for j = 1:length(Odors_All)
            odors_now = day_now(j*trial_cutoff-trial_cutoff+1:j*trial_cutoff,:);
            odors_now = odors_now(:,(day_now_SparseLog+best_now_log == 2));
            odors_now = odors_now.';
            odor_holder{1,j} = mean(odors_now,2,'omitnan').';
        end
        odor_best{1,i} = vertcat(odor_holder{:});
    end
    best_day{1,d} = odor_best;
end
mean_array = zeros(6,6);
sem_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,1}{1,odor};
    mean_array(:,odor) = mean(resp_now,2);
    sem_array(:,odor) = std(resp_now,0,2)/sqrt(length(resp_now));
end
figure, hold on
bar(mean_array.')
title('Day1 --- Best Day1')
ylim([0,50])

mean_array = zeros(6,6);
sem_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,5}{1,odor};
    mean_array(:,odor) = mean(resp_now,2);
    sem_array(:,odor) = std(resp_now,0,2)/sqrt(length(resp_now));
end
figure, hold on
bar(mean_array.')
title('Day5 --- Best Day1')
ylim([0,50])

% average response mag to each odor; sorting only by D1 best and only using
% the n = cutoff_sparse most narrowly tuned cells on D1
cutoff_sparse = ceil(size(tables_compiled{1,1}.Deltas,2)/5); % num cells to keep 
day_sparse = 1; % day to use for sparseness values 
Day_sparsensss = Sparseness_Lifetime(day_sparse,:);
[sorted,Day_idx] = sort(Day_sparsensss,'descend');
day_now_sparse_cutoff = sorted(cutoff_sparse+1);
day_now_SparseLog = Day_sparsensss > day_now_sparse_cutoff;
best_day = cell(1,5);
for d = 1:5
    day_now = tables_compiled{d,1}.Deltas;
    odor_best = cell(1,6);
    for i = 1:length(Odors_All)
        best_now_log = best_idx == i;
        odor_holder = cell(1,6);
        for j = 1:length(Odors_All)
            odors_now = day_now(j*trial_cutoff-trial_cutoff+1:j*trial_cutoff,:);
            odors_now = odors_now(:,(day_now_SparseLog+best_now_log == 2));
            odors_now = odors_now.';
            odor_holder{1,j} = mean(odors_now(:,1:4),2,'omitnan').';
        end
        odor_best{1,i} = vertcat(odor_holder{:});
    end
    best_day{1,d} = odor_best;
end
mean_array = zeros(6,6);
sem_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,1}{1,odor};
    mean_array(:,odor) = mean(resp_now,2);
    sem_array(:,odor) = std(resp_now,0,2)/sqrt(length(resp_now));
end
figure, hold on
bar(mean_array.')
title('Day1 --- First 2 Best Day1')
ylim([0,50])

mean_array = zeros(6,6);
sem_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,5}{1,odor};
    mean_array(:,odor) = mean(resp_now,2);
    sem_array(:,odor) = std(resp_now,0,2)/sqrt(length(resp_now));
end
figure, hold on
bar(mean_array.')
title('Day5 --- First 2 Best Day1')
ylim([0,50])

% average response mag to each odor; sorting only by D1 best and only using
% the n = cutoff_sparse most narrowly tuned cells on D1
cutoff_sparse = ceil(size(tables_compiled{1,1}.Deltas,2)/5); % num cells to keep 
day_sparse = 1; % day to use for sparseness values 
Day_sparsensss = Sparseness_Lifetime(day_sparse,:);
[sorted,Day_idx] = sort(Day_sparsensss,'descend');
day_now_sparse_cutoff = sorted(cutoff_sparse+1);
day_now_SparseLog = Day_sparsensss > day_now_sparse_cutoff;
best_day = cell(1,5);
for d = 1:5
    day_now = tables_compiled{d,1}.Deltas;
    odor_best = cell(1,6);
    for i = 1:length(Odors_All)
        best_now_log = best_idx == i;
        odor_holder = cell(1,6);
        for j = 1:length(Odors_All)
            odors_now = day_now(j*trial_cutoff-trial_cutoff+1:j*trial_cutoff,:);
            odors_now = odors_now(:,(day_now_SparseLog+best_now_log == 2));
            odors_now = odors_now.';
            odor_holder{1,j} = mean(odors_now(:,5:end),2,'omitnan').';
        end
        odor_best{1,i} = vertcat(odor_holder{:});
    end
    best_day{1,d} = odor_best;
end
mean_array = zeros(6,6);
sem_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,1}{1,odor};
    mean_array(:,odor) = mean(resp_now,2);
    sem_array(:,odor) = std(resp_now,0,2)/sqrt(length(resp_now));
end
figure, hold on
bar(mean_array.')
title('Day1 --- Last 2 Best Day1')
ylim([0,50])

mean_array = zeros(6,6);
sem_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,5}{1,odor};
    mean_array(:,odor) = mean(resp_now,2);
    sem_array(:,odor) = std(resp_now,0,2)/sqrt(length(resp_now));
end
figure, hold on
bar(mean_array.')
title('Day5 --- Last 2 Best Day1')
ylim([0,50])


%% sort cells by best tuned response on D1 and most narrowly tuned D1 cells

cell_pick = 3; % batch n in file is this value for cells visualized
% best sort on D1 by magnitude; best_idx is final index file
Odors_All = unique(tables_compiled{1,1}.Odor);
D1_pull = tables_compiled{1,1}.Deltas;
avg_D1 = cell(1,length(Odors_All));
for i = 1:length(Odors_All)
    odors_now = D1_pull;
    odors_now = odors_now(i*8-7:i*8,:);
    odor_avg = median(odors_now,1,'omitnan');
    avg_D1{1,i} = odor_avg;
end
avg_D1 = cell2mat(avg_D1.');
[value,best_idx] = max(avg_D1,[],1,'omitnan');

% average response mag to each odor; sorting only by D1 best and only using
% the n = cutoff_sparse most narrowly tuned cells on D1
cutoff_sparse = ceil(size(tables_compiled{1,1}.Deltas,2)/5); % num cells to keep 
day_sparse = 1; % day to use for sparseness values 
Day_sparsensss = Sparseness_Lifetime(day_sparse,:);
[sorted,Day_idx] = sort(Day_sparsensss,'descend');
day_now_sparse_cutoff = sorted(cutoff_sparse+1);
day_now_SparseLog = Day_sparsensss > day_now_sparse_cutoff;
best_day = cell(1,5);
for d = 1:5
    day_now = tables_compiled{d,1}.Deltas;
    odor_best = cell(1,6);
    for i = 1:length(Odors_All)
        best_now_log = best_idx == i;
        odor_holder = cell(1,6);
        for j = 1:length(Odors_All)
            odors_now = day_now(j*trial_cutoff-trial_cutoff+1:j*trial_cutoff,:);
            odors_now = odors_now(:,(day_now_SparseLog+best_now_log == 2));
            odors_now = odors_now.';
            odor_holder{1,j} = median(odors_now,2,'omitnan').';
        end
        odor_best{1,i} = vertcat(odor_holder{:});
    end
    best_day{1,d} = odor_best;
end

odor_d1 = cell(1,6);
for odor = 1:6
d1 = best_day{1,1}{1,odor};
d1 = d1(:,cell_pick);
odor_d1{1,odor} = d1;
end

mean_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,1}{1,odor};
    mean_array(:,odor) = resp_now(:,cell_pick) ./ odor_d1{odor}(odor);
    % mean_array(:,odor) = resp_now(:,cell_pick);

end
figure, hold on
bar(mean_array.')
title('Day1 --- Best Day1')
ylim([0,2])

mean_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,2}{1,odor};
    mean_array(:,odor) = resp_now(:,cell_pick) ./ odor_d1{odor}(odor);
end
figure, hold on
bar(mean_array.')
title('Day2 --- Best Day1')
ylim([0,2])


mean_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,3}{1,odor};
    mean_array(:,odor) = resp_now(:,cell_pick) ./ odor_d1{odor}(odor);
end
figure, hold on
bar(mean_array.')
title('Day3 --- Best Day1')
ylim([0,2])


mean_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,4}{1,odor};
    mean_array(:,odor) = resp_now(:,cell_pick) ./ odor_d1{odor}(odor);
end
figure, hold on
bar(mean_array.')
title('Day4 --- Best Day1')
ylim([0,2])


mean_array = zeros(6,6);
for odor = 1:6
    resp_now = best_day{1,5}{1,odor};
    mean_array(:,odor) = resp_now(:,cell_pick) ./ odor_d1{odor}(odor);
end
figure, hold on
bar(mean_array.')
title('Day5 --- Best Day1')
ylim([0,2])


