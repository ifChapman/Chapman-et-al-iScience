% For any classifier code below, there's no error as i'm pulling a set
% group of cells each time. Final output of the values as is are in an
% array called day_pct for each chunk; reformated into "viewer" to make
% copy/paste easier. 

clear
load('ProcessedData\tables_compiled.mat');
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

%% graph for lifetime sparsness error; standalone lines
mean_odor = mean(Sparseness_Lifetime,2,'omitnan');
error = std(Sparseness_Lifetime,0,2,'omitnan') ./ sqrt(length(Sparseness_Lifetime));
error_low = zeros(1,size(Sparseness_Lifetime,1));
sizer = 1:size(Sparseness_Lifetime,1);
figure,
er = errorbar(sizer,mean_odor,error,error);
er.LineWidth = 2.5;
er.Color = [0 0 0];
ylim([0 0.5])
xlim([0,6])
xticklabels('')

%% violin plot for lifetime sparseness
colors = {'black',[0.82,0.12,0.41],[0.12,0.7,0.56],...
     [0.37,0.22,0.74],[0.58,0.54,0.83]};
grayColor = [.4 .4 .4];
gap = ones(1,length(Sparseness_Lifetime));
figure, hold on
for i = 1:size(Sparseness_Lifetime,1)
    swarmchart(gap*i,Sparseness_Lifetime(i,:),30,colors{i},'filled')
    mean_day = mean(Sparseness_Lifetime(i,:),2);
    line([i-0.4,i+0.4],[mean_day,mean_day],'Color',[0,0,1],'Linewidth',6)
    set(gca,'xtick',[],'ytick',[])
end
xlim([0,6]);

%% run classifier using more sparse cells found each day 
tic
% run within days by iter; params for number of cells/iteration counts
starting_n = 50;
steps = 50; 
max_n = 500;
jumper = starting_n:steps:max_n;
day_error = cell(1,5);
day_pct = cell(1,5);
for i = 1:5
    % change to n number instead of i if you want to use a single day
    drop_table_stable = tables_compiled{i,1};
    day_pull = tables_compiled{i,1};
    day_pull_odors = day_pull.Odor;
    drop_table_deltas = day_pull.Deltas;
    [~,col_drop] = find(isnan(drop_table_deltas));
    drop_table_deltas(:,col_drop) = [];
    % if you wanna sort by sparseness; i for every day, change to num for
%     % set day if you want to use the same ones 
    Day_sparsensss = Sparseness_Lifetime(i,:);
    [~,Day_idx] = sort(Day_sparsensss,'descend');
    % if you wanna sort by max instead of sparseness
%     Day_sparsensss =  mean(tables_compiled{i,1}.Deltas,1);
%     [~,Day_idx] = sort(Day_sparsensss,'descend');
    % set seed for replicability
    pct_by_count = zeros(1,length(jumper));
    for k = 1:length(jumper)
        group_now = 1:jumper(k);
        stable_pull = drop_table_stable.Deltas(:,Day_idx(1:jumper(k)));
        table_pull = drop_table_deltas(:,Day_idx(1:jumper(k)));
        predictions = cell(size(table_pull,1),1);
            for m = 1:size(table_pull,1)
                drop_table = stable_pull;
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
        pct_by_count(1,k) = sum(correct_log == 1)/size(table_pull,1)*100;
    end
    day_pct{1,i} = pct_by_count;
end
toc
%panel 6B
viewer = cell2mat(day_pct.');
% graph above loop output 
colors = {'black',[0.05,0.34,0.05],[0.62,0.62,0.13],...
     [0.05,0.20,0.57],[0.57,0.02,0.02]};
figure, 
hold on
for i = 1:5
    e(i) = plot(1:length(jumper),day_pct{1,i});
    e(i).Color = colors{i};
    e(i).LineWidth = 2.5;
end
xlabel('CellN');
ylabel('Percent Correct');
label_all = [0,jumper];
xticklabels(label_all(1:2:end)); 
xlim([0 length(jumper)+1]);
xticks([0:2:length(day_pct{1,1})]);
ylim([0 100]);
leg = legend('Day1','Day2','Day3','Day4','Day5','Location','southeast');
title('Classifier by Day');

%% run classifier using least sparse cells each day 
tic
% run within days by iter; params for number of cells/iteration counts
starting_n = 50;
steps = 50; 
max_n = 500;
jumper = starting_n:steps:max_n;
day_error = cell(1,5);
day_pct = cell(1,5);
for i = 1:5
    % change to n number instead of i if you want to use a single day
    drop_table_stable = tables_compiled{i,1};
    day_pull = tables_compiled{i,1};
    day_pull_odors = day_pull.Odor;
    drop_table_deltas = day_pull.Deltas;
    [~,col_drop] = find(isnan(drop_table_deltas));
    drop_table_deltas(:,col_drop) = [];
    % if you wanna sort by sparseness; i for every day, change to num for
    % set day if you want to use the same ones 
    Day_sparsensss = Sparseness_Lifetime(i,:);
    [~,Day_idx] = sort(Day_sparsensss,'ascend');
    % set seed for replicability
    pct_by_count = zeros(1,length(jumper));
    for k = 1:length(jumper)
        group_now = 1:jumper(k);
        stable_pull = drop_table_stable.Deltas(:,Day_idx(1:jumper(k)));
        table_pull = drop_table_deltas(:,Day_idx(1:jumper(k)));
        predictions = cell(size(table_pull,1),1);
            for m = 1:size(table_pull,1)
                drop_table = stable_pull;
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
        pct_by_count(1,k) = sum(correct_log == 1)/size(table_pull,1)*100;
    end
    day_pct{1,i} = pct_by_count;
end
toc
viewer = cell2mat(day_pct.');
% graph above loop output 
colors = {'black',[0.05,0.34,0.05],[0.62,0.62,0.13],...
     [0.05,0.20,0.57],[0.57,0.02,0.02]};
figure, 
hold on
for i = 1:5
    e(i) = plot(1:length(jumper),day_pct{1,i});
    e(i).Color = colors{i};
    e(i).LineWidth = 2.5;
end
xlabel('CellN');
ylabel('Percent Correct');
label_all = [0,jumper];
xticklabels(label_all(1:2:end)); 
xlim([0 length(jumper)+1]);
xticks([0:2:length(day_pct{1,1})]);
ylim([0 100]);
leg = legend('Day1','Day2','Day3','Day4','Day5','Location','southeast');
title('Classifier by Day');

%% run classifier using most sparse cells on D1; train each day
tic
% run within days by iter; params for number of cells/iteration counts
starting_n = 50;
steps = 50; 
max_n = 500;
jumper = starting_n:steps:max_n;
day_error = cell(1,5);
day_pct = cell(1,5);
for i = 1:5
    % change to n number instead of i if you want to use a single day
    drop_table_stable = tables_compiled{i,1};
    day_pull = tables_compiled{i,1};
    day_pull_odors = day_pull.Odor;
    drop_table_deltas = day_pull.Deltas;
    [~,col_drop] = find(isnan(drop_table_deltas));
    drop_table_deltas(:,col_drop) = [];
    % if you wanna sort by sparseness; i for every day, change to num for
    % set day if you want to use the same ones 
    Day_sparsensss = Sparseness_Lifetime(1,:);
    [~,Day_idx] = sort(Day_sparsensss,'descend');
    % if you wanna sort by max instead of sparseness
%     Day_sparsensss =  mean(tables_compiled{1,1}.Deltas,1);
%     [~,Day_idx] = sort(Day_sparsensss,'descend');
    % set seed for replicability
    pct_by_count = zeros(1,length(jumper));
    for k = 1:length(jumper)
        group_now = 1:jumper(k);
        stable_pull = drop_table_stable.Deltas(:,Day_idx(1:jumper(k)));
        table_pull = drop_table_deltas(:,Day_idx(1:jumper(k)));
        predictions = cell(size(table_pull,1),1);
            for m = 1:size(table_pull,1)
                drop_table = stable_pull;
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
        pct_by_count(1,k) = sum(correct_log == 1)/size(table_pull,1)*100;
    end
    day_pct{1,i} = pct_by_count;
end
toc
% for 6C
viewer = cell2mat(day_pct.');
% graph above loop output 
colors = {'black',[0.05,0.34,0.05],[0.62,0.62,0.13],...
     [0.05,0.20,0.57],[0.57,0.02,0.02]};
figure, 
hold on
for i = 1:5
    e(i) = plot(1:length(jumper),day_pct{1,i});
    e(i).Color = colors{i};
    e(i).LineWidth = 2.5;
end
xlabel('CellN');
ylabel('Percent Correct');
label_all = [0,jumper];
xticklabels(label_all(1:2:end)); 
xlim([0 length(jumper)+1]);
xticks([0:2:length(day_pct{1,1})]);
ylim([0 100]);
leg = legend('Day1','Day2','Day3','Day4','Day5','Location','southeast');
title('Classifier by Day');

%% run classifier using most sparse cells on D1 and train model on D1 data only
tic
% run within days by iter; params for number of cells/iteration counts
starting_n = 50;
steps = 50; 
max_n = 500;
jumper = starting_n:steps:max_n;
day_error = cell(1,5);
day_pct = cell(1,5);
for i = 1:5
    % change to n number instead of i if you want to use a single day
    drop_table_stable = tables_compiled{1,1};
    day_pull = tables_compiled{i,1};
    day_pull_odors = day_pull.Odor;
    drop_table_deltas = day_pull.Deltas;
    [~,col_drop] = find(isnan(drop_table_deltas));
    drop_table_deltas(:,col_drop) = [];
    % if you wanna sort by sparseness; i for every day, change to num for
    % set day if you want to use the same ones 
    Day_sparsensss = Sparseness_Lifetime(1,:);
    [~,Day_idx] = sort(Day_sparsensss,'descend');
    % if you wanna sort by max instead of sparseness
%     Day_sparsensss =  mean(tables_compiled{1,1}.Deltas,1);
%     [~,Day_idx] = sort(Day_sparsensss,'descend');
    % set seed for replicability
    pct_by_count = zeros(1,length(jumper));
    for k = 1:length(jumper)
        group_now = 1:jumper(k);
        stable_pull = drop_table_stable.Deltas(:,Day_idx(1:jumper(k)));
        table_pull = drop_table_deltas(:,Day_idx(1:jumper(k)));
        predictions = cell(size(table_pull,1),1);
            for m = 1:size(table_pull,1)
                drop_table = stable_pull;
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
        pct_by_count(1,k) = sum(correct_log == 1)/size(table_pull,1)*100;
    end
    day_pct{1,i} = pct_by_count;
end
toc
% for 6D
viewer = cell2mat(day_pct.');
% graph above loop output 
colors = {'black',[0.05,0.34,0.05],[0.62,0.62,0.13],...
     [0.05,0.20,0.57],[0.57,0.02,0.02]};
figure, 
hold on
for i = 1:5
    e(i) = plot(1:length(jumper),day_pct{1,i});
    e(i).Color = colors{i};
    e(i).LineWidth = 2.5;
end
xlabel('CellN');
ylabel('Percent Correct');
label_all = [0,jumper];
xticklabels(label_all(1:2:end)); 
xlim([0 length(jumper)+1]);
xticks([0:2:length(day_pct{1,1})]);
ylim([0 100]);
leg = legend('Day1','Day2','Day3','Day4','Day5','Location','southeast');
title('Classifier by Day');

%% lifetime sparseness stats; one way anova + post hocs

[p,tbl,stats] = anova1(Sparseness_Lifetime.');
% post-hoc, default is tukey 
figure,
[c,m,h] = multcompare(stats);

