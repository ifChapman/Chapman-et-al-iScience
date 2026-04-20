clear
load('ProcessedData\tables_compiled_shifterMag.mat');

%% classifier code; runs on increasingly larger random subsets of cells 

% % reorg main table if needed
% re_org = vertcat(tables_compiled{:});
% tables_compiled = cell(1,1);
% tables_compiled{1,1} = re_org;
tic
% run within days by iter; params for number of cells/iteration counts
iter_n = 100; % fig 100
starting_n = 50; % fig 50
steps = 25; % fig 25
max_n = 500; % fig 500
jumper = starting_n:steps:max_n;
% these two cells con the average and error values; each cell is a day
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
colors = ["black","cyan","red","yellow","magenta"];
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

%%
save('Fig_S3\runClassifier_peakMag_iter100.mat');
beep






