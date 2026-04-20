clear
load('ProcessedData\tables_compiled.mat');
%% Indivial corr figs for day 1
ID_unique = unique(animal_ID);
D1_deltas = tables_compiled{1,1}.Deltas;
figure, 
t = tiledlayout(3,5,'TileSpacing','Compact');
trial_cutoff = 8;
for i = 1:length(used_ID)
    animal_now = ID_unique(i);
    delta_now = D1_deltas(:,animal_ID==animal_now).';
    corr_now = corr(delta_now);
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
    set(ax, 'LineWidth', 2);
end


% Set the figure to use a specific paper size (e.g., larger than your screen)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [30 18]); % Set paper size to 15x10 inches

% Set the position of the figure on the paper
set(gcf, 'PaperPosition', [0 0 30 18]);

% Print the figure to a high-resolution PDF
print('Fig_S2\corrs_animal.pdf', '-dpdf', '-r600'); % -r600 sets 600 DPI resolution

% Alternatively, save as a high-resolution image (e.g., TIFF)
print('Fig_S2\corrs_animalr.tif', '-dtiff', '-r600');