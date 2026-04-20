clear
load('ProcessedData\tables_compiled_behaviorShifter_best.mat');

%% behavior for best odor trials cross days

behBest_meanDay = cell(1,5);
for i = 1:5
    day_now = tables_compiled{i,1};
    day_now = day_now(day_now.Odor == 1,:);
    behBest_meanDay{1,i} = mean(day_now.Beh_Index,2,'omitnan');
end

%% best odor corrs to D1; average by trialN

clear
load('tables_compiled_bestD1.mat');

D_template = tables_compiled{1,1}.Deltas;
D_template = D_template.';
trial_cutoff = 8;
corr_crossDay_avg = cell(1,5);
corr_errDay_avg = cell(1,5);
for i = 2:5
    day_now = tables_compiled{i,1}.Deltas;
    day_now = day_now.';
    % do the corrs 
    corr_now = corr(D_template,day_now);
    corr_now = corr_now(1:8,1:8);
    corr_crossDay_avg{1,i} = mean(corr_now,1);
    size_corr = size(corr_now);
    corr_errDay_avg{1,i} = std(corr_now,1,1)/sqrt(size_corr(1));
end