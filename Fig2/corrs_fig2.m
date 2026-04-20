clear
% for all of these, just adapted my 5 day code; cropping for D1 in the fig
%% corr combined, 5 days, non PreHab, by ID, shifted window
load('ProcessedData\tables_compiled.mat');

figure,
tiledlayout(1,5,'TileSpacing','Compact');
trial_cutoff = 8;
within = cell(1,5);
across = cell(1,5);
for i = 1:5
    day_now = tables_compiled{i,1}.Deltas;
    day_now = day_now.';
    % day_now = day_now(top_cells,:);
    % do the corrs 
    corr_now = corr(day_now);
    % corr_now = corr(mean_cell);
    clims = [0,1];
    nexttile
    imagesc(corr_now,clims), colormap 'jet', grid on, 
    ax = gca;
    ax.GridAlpha = 1.0;
    ax.GridLineWidth = 2;
%   title(append('Day',num2str(i)));
    xticklabels('');
    yticklabels('');
    set(gca,'LineWidth',1.5)
    set(gca,'xtick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    set(gca,'ytick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    odor_pull = cell(1,6);
    for j = 1:6
        within_loop = uniquetol(corr_now(j*8-7:j*8,j*8-7:j*8));
        odor_pull{1,j} = within_loop;
    end
    within_day = uniquetol(cell2mat(odor_pull));
    within{1,i} = within_day(within_day<1);
    across_pull = uniquetol(corr_now);
    across_pull(ismember(across_pull,within_day)) = [];
    across{1,i} = uniquetol(across_pull(across_pull<1));
    set(ax, 'LineWidth', 2);
end

% Set the figure to use a specific paper size (e.g., larger than your screen)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [30 6]); % Set paper size to 15x10 inches

% Set the position of the figure on the paper
set(gcf, 'PaperPosition', [0 0 30 6]);

% Print the figure to a high-resolution PDF
print('Fig2\corrs_shiftedTimepoint.pdf', '-dpdf', '-r600'); % -r600 sets 600 DPI resolution

% Alternatively, save as a high-resolution image (e.g., TIFF)
print('Fig2\corrs_shiftedTimepoint.tif', '-dtiff', '-r600');


%% corr combined, 5 days, no shift
clear 
load('ProcessedData\tables_compiled_noShift.mat');
figure,
tiledlayout(1,5,'TileSpacing','Compact');
trial_cutoff = 8;
within = cell(1,5);
across = cell(1,5);
for i = 1:5
    day_now = tables_compiled{i,1}.Deltas;
    day_now = day_now.';
    % mean_cell = (day_now - mean(day_now,2))./std(day_now,0,2);
    % do the corrs 
    corr_now = corr(day_now);
    % corr_now = corr(mean_cell);
    clims = [0,1];
    nexttile
    imagesc(corr_now,clims), colormap 'jet', grid on, box on
    ax = gca;
    ax.GridAlpha = 1.0;
    ax.GridLineWidth = 2;
%   title(append('Day',num2str(i)));
    xticklabels('');
    yticklabels('');
    % set(gca,'LineWidth',1.5)
    set(gca,'xtick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    set(gca,'ytick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    odor_pull = cell(1,6);
    for j = 1:6
        within_loop = uniquetol(corr_now(j*8-7:j*8,j*8-7:j*8));
        odor_pull{1,j} = within_loop;
    end
    within_day = uniquetol(cell2mat(odor_pull));
    within{1,i} = within_day(within_day<1);
    across_pull = uniquetol(corr_now);
    across_pull(ismember(across_pull,within_day)) = [];
    across{1,i} = uniquetol(across_pull(across_pull<1));
    set(ax, 'LineWidth', 2);
end

% Set the figure to use a specific paper size (e.g., larger than your screen)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [30 6]); % Set paper size to 15x10 inches

% Set the position of the figure on the paper
set(gcf, 'PaperPosition', [0 0 30 6]);

% Print the figure to a high-resolution PDF
print('Fig2\corrs_originalTimepoint.pdf', '-dpdf', '-r600'); % -r600 sets 600 DPI resolution

% Alternatively, save as a high-resolution image (e.g., TIFF)
print('Fig2\corrs_originalTimepoint.tif', '-dtiff', '-r600');

%% corr combined, 5 days, non PreHab, by ID, pre odor shuffled + shifter
clear
load('ProcessedData\tables_compiled_preShift.mat');
figure,
tiledlayout(1,5,'TileSpacing','Compact');
trial_cutoff = 8;
within = cell(1,5);
across = cell(1,5);
for i = 1:5
    day_now = tables_compiled{i,1}.Deltas;
    day_now = day_now.';
    % do the corrs 
    corr_now = corr(day_now);
    clims = [0,1];
    nexttile
    imagesc(corr_now,clims), colormap 'jet', grid on, 
    ax = gca;
    ax.GridAlpha = 1.0;
    ax.GridLineWidth = 2;
%   title(append('Day',num2str(i)));
    xticklabels('');
    yticklabels('');
    set(gca,'LineWidth',1.5)
    set(gca,'xtick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    set(gca,'ytick',trial_cutoff + 0.5:trial_cutoff:size(corr_now,2));
    odor_pull = cell(1,6);
    for j = 1:6
        within_loop = uniquetol(corr_now(j*8-7:j*8,j*8-7:j*8));
        odor_pull{1,j} = within_loop;
    end
    within_day = uniquetol(cell2mat(odor_pull));
    within{1,i} = within_day(within_day<1);
    across_pull = uniquetol(corr_now);
    across_pull(ismember(across_pull,within_day)) = [];
    across{1,i} = uniquetol(across_pull(across_pull<1));
    set(ax, 'LineWidth', 2);
end

% Set the figure to use a specific paper size (e.g., larger than your screen)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [30 6]); % Set paper size to 15x10 inches

% Set the position of the figure on the paper
set(gcf, 'PaperPosition', [0 0 30 6]);

% Print the figure to a high-resolution PDF
print('Fig2\corrs_preShift.pdf', '-dpdf', '-r600'); % -r600 sets 600 DPI resolution

% Alternatively, save as a high-resolution image (e.g., TIFF)
print('Fig2\corrs_preShift.tif', '-dtiff', '-r600');

