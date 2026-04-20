%% corr combined, 5 days, non PreHab, by ID
clear
load('ProcessedData\tables_compiled_shifterMag.mat');
%%
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
    odor_pull_across = cell(1,6);
    for j = 1:6
        within_loop = corr_now(j*8-7:j*8,j*8-7:j*8);
        across_loop = corr_now;
        across_loop = across_loop(~ismember(across_loop,within_loop));
        odor_pull{1,j} = within_loop;
        odor_pull_across{1,j} = across_loop;
    end
    within{1,i} = uniquetol(cell2mat(odor_pull));
    across{1,i} = uniquetol(cell2mat(odor_pull_across));
    set(ax, 'LineWidth', 2);
end

% within has all within odor corrs for panel C
within = horzcat(within{1,:});
across = horzcat(across{1,:});
within(169,:) = [];


% Set the figure to use a specific paper size (e.g., larger than your screen)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [30 6]); % Set paper size to 15x10 inches

% Set the position of the figure on the paper
set(gcf, 'PaperPosition', [0 0 30 6]);

% Print the figure to a high-resolution PDF
print('Fig_S3\corrs_byOdor.pdf', '-dpdf', '-r600'); % -r600 sets 600 DPI resolution

% Alternatively, save as a high-resolution image (e.g., TIFF)
print('Fig_S3\corrs_byOdor.tif', '-dtiff', '-r600');

%% corr combined, 5 days, by best
clear
load('ProcessedData\tables_compiled_shifterMag_bestD1.mat');
figure,
t = tiledlayout(1,5,'TileSpacing','Compact');
trial_cutoff = 8;
within_by_day = cell(5,1);
across_by_day = cell(5,1);
for i = 1:5
    day_now = tables_compiled{i,1}.Deltas;
    day_now = day_now.';
    % do the corrs 
    corr_now = corr(day_now);
    corr_by_odor = cell(6,1);
    corr_by_odor_across = cell(6,1);
    for j = 1:6
        pull = corr_now(j*trial_cutoff-7:j*trial_cutoff,j*trial_cutoff-7:j*trial_cutoff);
        pull2 = uniquetol(pull(pull < 0.9999999999));
        corr_by_odor{j,1} = pull2.';
        across = corr_now(j*trial_cutoff-7:j*trial_cutoff,:);
        across(:,max(across,[],1)>0.99999) = [];
        across = uniquetol(across);
        corr_by_odor_across{j,1} = across;
    end
    % within odor corrs sep by best odor for panel E
    within_by_day{i,1} = corr_by_odor;
    across_by_day{i,1} = corr_by_odor_across;
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
    set(ax, 'LineWidth', 2);
end


% Set the figure to use a specific paper size (e.g., larger than your screen)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [30 6]); % Set paper size to 15x10 inches

% Set the position of the figure on the paper
set(gcf, 'PaperPosition', [0 0 30 6]);

% Print the figure to a high-resolution PDF
print('Fig_S3\corrs_byBest.pdf', '-dpdf', '-r600'); % -r600 sets 600 DPI resolution

% Alternatively, save as a high-resolution image (e.g., TIFF)
print('Fig_S3\corrs_byBest.tif', '-dtiff', '-r600');