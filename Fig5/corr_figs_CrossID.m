%% run corrs to Day1 with same cell set, non-PreHab; by ID
clear
load('ProcessedData\tables_compiled.mat');
%% Corr to D1 no best sorting
figure, 
t = tiledlayout(1,5,'TileSpacing','Compact');
D_template = tables_compiled{1,1}.Deltas;
D_template = D_template.';
trial_cutoff = 8;
within = cell(1,5);
across = cell(1,5);
for i = 1:5
    day_now = tables_compiled{i,1}.Deltas;
    day_now = day_now.';
    % do the corrs 
    corr_now = corr(D_template,day_now);
    clims = [0,1];
    nexttile
    imagesc(corr_now,clims), colormap 'jet', grid on, 
    ax = gca;
    ax.GridAlpha = 1.0;
    ax.GridLineWidth = 2;
%     title(append('Day',num2str(i)));
    xticklabels('');
    yticklabels('');
    set(gca,'LineWidth',1.5)
    set(gca,'xtick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    set(gca,'ytick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    odor_pull = cell(2,6);
    odor_pull_across = cell(1,6);
    for j = 1:6
        within_loop = corr_now(j*8-7:j*8,j*8-7:j*8);
        across_loop = corr_now;
        across_loop = across_loop(~ismember(across_loop,within_loop));
        odor_pull{1,j} = within_loop;
        odor_pull_across{1,j} = across_loop;
    end
    within{1,i} = uniquetol(cell2mat(odor_pull)); % for panel 5E
    % across{1,i} = uniquetol(cell2mat(odor_pull_across));
    set(ax, 'LineWidth', 2);
end

for_prism5e = cell2mat(within(1,2:5));

% Set the figure to use a specific paper size (e.g., larger than your screen)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [30 6]); % Set paper size to 15x10 inches

% Set the position of the figure on the paper
set(gcf, 'PaperPosition', [0 0 30 6]);

% Print the figure to a high-resolution PDF
print('Fig5\corrs_toD1_byOdor.pdf', '-dpdf', '-r600'); % -r600 sets 600 DPI resolution

% Alternatively, save as a high-resolution image (e.g., TIFF)
print('Fig5\corrs_toD1_byOdor.tif', '-dtiff', '-r600');


%% Corr to D1 sorted best
clear
load('ProcessedData\tables_compiled_bestD1.mat');
figure, 
t = tiledlayout(1,5,'TileSpacing','Compact');
D_template = tables_compiled{1,1}.Deltas;
D_template = D_template.';
trial_cutoff = 8;
within = cell(1,5);
across = cell(1,5);
for i = 1:5
    day_now = tables_compiled{i,1}.Deltas;
    day_now = day_now.';
    % do the corrs 
    corr_now = corr(D_template,day_now);
    clims = [0,1];
    nexttile
    imagesc(corr_now,clims), colormap 'jet', grid on, 
    ax = gca;
    ax.GridAlpha = 1.0;
    ax.GridLineWidth = 2;
%     title(append('Day',num2str(i)));
    xticklabels('');
    yticklabels('');
    set(gca,'LineWidth',1.5)
    set(gca,'xtick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    set(gca,'ytick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    odor_pull = cell(3,6);
    odor_pull_across = cell(1,6);
    for j = 1:6
        within_loop = corr_now(j*8-7:j*8,j*8-7:j*8);
        within_loop = uniquetol(within_loop);
        within_loop = within_loop(within_loop <0.999999);
        odor_pull{1,j} = mean(within_loop,'all');
        odor_pull{2,j} = std(within_loop,0,'all')/sqrt(numel(within_loop));
        odor_pull{3,j} = numel(within_loop);
    end
    within{1,i} = odor_pull.';
    set(ax, 'LineWidth', 2);
end
% contains average within odor corrs from best to worst for panel 5D
for_prism = cell2mat(horzcat(within{:})); 

% Set the figure to use a specific paper size (e.g., larger than your screen)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [30 6]); % Set paper size to 15x10 inches

% Set the position of the figure on the paper
set(gcf, 'PaperPosition', [0 0 30 6]);

% Print the figure to a high-resolution PDF
print('Fig5\corrs_toD1_byBest.pdf', '-dpdf', '-r600'); % -r600 sets 600 DPI resolution

% Alternatively, save as a high-resolution image (e.g., TIFF)
print('Fig5\corrs_toD1_byBest.tif', '-dtiff', '-r600');

%% invert to D5
figure, 
t = tiledlayout(1,5,'TileSpacing','Compact');
D_template = tables_compiled{5,1}.Deltas;
D_template = D_template.';
trial_cutoff = 8;
within = cell(1,5);
across = cell(1,5);
for i = 1:5
    day_now = tables_compiled{i,1}.Deltas;
    day_now = day_now.';
    % do the corrs 
    corr_now = corr(D_template,day_now);
    clims = [0,1];
    nexttile
    imagesc(corr_now,clims), colormap 'jet', grid on, 
    ax = gca;
    ax.GridAlpha = 1.0;
    ax.GridLineWidth = 2;
%     title(append('Day',num2str(i)));
    xticklabels('');
    yticklabels('');
    set(gca,'LineWidth',1.5)
    set(gca,'xtick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    set(gca,'ytick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    odor_pull = cell(3,6);
    odor_pull_across = cell(1,6);
    for j = 1:6
        within_loop = corr_now(j*8-7:j*8,j*8-7:j*8);
        within_loop = uniquetol(within_loop);
        within_loop = within_loop(within_loop <0.999999);
        odor_pull{1,j} = mean(within_loop,'all');
        odor_pull{2,j} = std(within_loop,0,'all')/sqrt(numel(within_loop));
        odor_pull{3,j} = numel(within_loop);
    end
    within{1,i} = odor_pull.';
    set(ax, 'LineWidth', 2);
end
% contains average within odor corrs from best to worst for panel 5D
for_prism = cell2mat(horzcat(within{:})); 


% Set the figure to use a specific paper size (e.g., larger than your screen)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [30 6]); % Set paper size to 15x10 inches

% Set the position of the figure on the paper
set(gcf, 'PaperPosition', [0 0 30 6]);

% Print the figure to a high-resolution PDF
print('Fig5\corrs_toD5_byBest.pdf', '-dpdf', '-r600'); % -r600 sets 600 DPI resolution

% Alternatively, save as a high-resolution image (e.g., TIFF)
print('Fig5\corrs_toD5_byBest.tif', '-dtiff', '-r600');


%% only best odor from corr fig
clear
load('tables_compiled_bestD1.mat');
figure, 
t = tiledlayout(1,5,'TileSpacing','Compact');
D_template = tables_compiled{1,1}.Deltas;
D_template = D_template.';
figure,
t = tiledlayout(1,5,'TileSpacing','Compact');
trial_cutoff = 8;
for i = 1:5
    day_now = tables_compiled{i,1}.Deltas;
    day_now = day_now.';
    % do the corrs 
    corr_now = corr(D_template,day_now);
    corr_now = corr_now(1:8,1:8);
    clims = [0,1];
    nexttile
    imagesc(corr_now,clims), colormap 'jet', grid on, 
    ax = gca;   
    ax.GridAlpha = 1.0;
    ax.GridColor;
%     title(append('Day',num2str(i)));
    xticklabels('');
    yticklabels('');
    grid off
    set(gca,'xtick',[])
    set(gca,'ytick',[])
end
