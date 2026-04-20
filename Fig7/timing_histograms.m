clear
%% get all vals for shifts

load('ProcessedData\PreProcessed.mat');

vals_corrShifter = [];
for day = 1:5
    for animal = 1:16
        vals_corrShifter = [vals_corrShifter,Delay_byDay{1,day}{animal,1}];
    end
end
vals_corrShifter(vals_corrShifter>34 | vals_corrShifter<2) = NaN;
vals_corrShifter(vals_corrShifter==0) = NaN;

load('ProcessedData\PreProcessed_behaviorShifter_smoothed.mat');

vals_peakBeh = [];
for day = 1:5
    for animal = 1:16
        vals_peakBeh = [vals_peakBeh,Delay_byDay{1,day}{animal,1}];
    end
end

vals_peakBeh(vals_peakBeh>34 | vals_peakBeh<2) = NaN;
vals_peakBeh(vals_peakBeh==0) = NaN;

load('ProcessedData\PreProcessed_behaviorShifter_smoothed_retuned_firstPeak_021726.mat');
vals_beh_first= [];
for day = 1:5
    for animal = 1:16
        vals_beh_first = [vals_beh_first,Delay_byDay{1,day}{animal,1}];
    end
end

vals_beh_first(vals_beh_first>34 | vals_beh_first<2) = NaN;
vals_beh_first(vals_beh_first==0) = NaN;



%% do some plotting

figure, hold on
% formatting nonsense to match prism
xticks(0:5:35)
xticklabels(string(0:7));
ylim([0,400])
yticks(0:100:400)
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
% Create first histogram
h1 = histogram(vals_corrShifter, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Blue, semi-transparent
hold on; % Keep the plot for overlay
prism_corr = histcounts(vals_corrShifter);

% Create second histogram
h2 = histogram(vals_beh_first, 'FaceColor', 'r', 'FaceAlpha', 0.5); % Red, semi-transparent
prism_beh_first = histcounts(vals_beh_first);
figure, hold on

cdf1 = cdfplot(vals_corrShifter);
set(cdf1, 'Color', 'k');

cdf2 = cdfplot(vals_beh_first);
set(cdf2, 'Color', 'r');


figure, hold on

% Create first histogram
h3 = histogram(vals_peakBeh, 'FaceColor', 'r', 'FaceAlpha', 0.5); % Blue, semi-transparent
hold on; % Keep the plot for overlay
prism_behPeak = histcounts(vals_peakBeh);
% Create second histogram
h4 = histogram(vals_corrShifter, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Red, semi-transparent
xticks(0:5:35)
xticklabels(string(0:7));
ylim([0,400])
yticks(0:100:400)
set(gca, 'TickDir', 'out');
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
figure, hold on
h1 = histogram(vals_corrShifter-vals_beh_first, 'BinEdges', -30:3:30, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Blue, semi-transparent
xticks(-30:10:30), xticklabels(-6:2:6);
ylim([0,400])
yticks(0:100:400)
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
xl1 = xline(0, 'LineWidth', 1.5);
xl2 = xline(nanmean(vals_corrShifter-vals_beh_first), 'LineWidth', 1.5, 'Color', 'r');


xline(0)
figure, hold on
h1 = histogram(vals_corrShifter-vals_peakBeh, 'BinEdges', -30:3:30, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Blue, semi-transparent
xticks(-30:10:30), xticklabels(-6:2:6);
ylim([0,400])
yticks(0:100:400)
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
xl1 = xline(0, 'LineWidth', 1.5);
xl2 = xline(nanmean(vals_corrShifter-vals_peakBeh), 'LineWidth', 1.5, 'Color', 'r');


%% get D1
clear
load('ProcessedData\PreProcessed.mat');

vals_corrShifter = [];
for day = 1
    for animal = 1:16
        vals_corrShifter = [vals_corrShifter,Delay_byDay{1,day}{animal,1}];
    end
end
vals_corrShifter(vals_corrShifter>34 | vals_corrShifter<2) = NaN;
vals_corrShifter(vals_corrShifter==0) = NaN;

load('ProcessedData\PreProcessed_behaviorShifter_smoothed.mat');

vals_peakBeh = [];
for day = 1
    for animal = 1:16
        vals_peakBeh = [vals_peakBeh,Delay_byDay{1,day}{animal,1}];
    end
end

vals_peakBeh(vals_peakBeh>34 | vals_peakBeh<2) = NaN;
vals_peakBeh(vals_peakBeh==0) = NaN;

load('ProcessedData\PreProcessed_behaviorShifter_smoothed_retuned_firstPeak_021726.mat');
vals_beh_first= [];
for day = 1
    for animal = 1:16
        vals_beh_first = [vals_beh_first,Delay_byDay{1,day}{animal,1}];
    end
end

vals_beh_first(vals_beh_first>34 | vals_beh_first<2) = NaN;
vals_beh_first(vals_beh_first==0) = NaN;



%% do some plotting

figure, hold on
% formatting nonsense to match prism
xticks(0:5:35)
xticklabels(string(0:7));
ylim([0,100])
yticks(0:20:100)
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
% Create first histogram
h1 = histogram(vals_corrShifter, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Blue, semi-transparent
hold on; % Keep the plot for overlay
prism_corr = histcounts(vals_corrShifter);

% Create second histogram
h2 = histogram(vals_beh_first, 'FaceColor', 'r', 'FaceAlpha', 0.5); % Red, semi-transparent
prism_beh_first = histcounts(vals_beh_first);
figure, hold on

cdf1 = cdfplot(vals_corrShifter);
set(cdf1, 'Color', 'k');

cdf2 = cdfplot(vals_beh_first);
set(cdf2, 'Color', 'r');


figure, hold on

% Create first histogram
h3 = histogram(vals_peakBeh, 'FaceColor', 'r', 'FaceAlpha', 0.5); % Blue, semi-transparent
hold on; % Keep the plot for overlay
prism_behPeak = histcounts(vals_peakBeh);
% Create second histogram
h4 = histogram(vals_corrShifter, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Red, semi-transparent
xticks(0:5:35)
xticklabels(string(0:7));
ylim([0,100])
yticks(0:20:100)
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
figure, hold on
h1 = histogram(vals_corrShifter-vals_beh_first, 'BinEdges', -30:3:30, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Blue, semi-transparent
xticks(-30:10:30), xticklabels(-6:2:6);
ylim([0,100])
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
xl1 = xline(0, 'LineWidth', 1.5);
xl2 = xline(nanmean(vals_corrShifter-vals_beh_first), 'LineWidth', 1.5, 'Color', 'r');


figure, hold on
h1 = histogram(vals_corrShifter-vals_peakBeh, 'BinEdges', -30:3:30, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Blue, semi-transparent
xticks(-30:10:30), xticklabels(-6:2:6);
xticklabels(-6:2:6);

ylim([0,100])
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
xl1 = xline(0, 'LineWidth', 1.5);
xl2 = xline(nanmean(vals_corrShifter-vals_peakBeh), 'LineWidth', 1.5, 'Color', 'r');


%% get D5 trials
clear
load('ProcessedData\PreProcessed.mat');

vals_corrShifter = [];
for day = 5
    for animal = 1:16
        vals_corrShifter = [vals_corrShifter,Delay_byDay{1,day}{animal,1}];
    end
end
vals_corrShifter(vals_corrShifter>34 | vals_corrShifter<2) = NaN;
vals_corrShifter(vals_corrShifter==0) = NaN;

load('ProcessedData\PreProcessed_behaviorShifter_smoothed.mat');

vals_peakBeh = [];
for day = 5
    for animal = 1:16
        vals_peakBeh = [vals_peakBeh,Delay_byDay{1,day}{animal,1}];
    end
end

vals_peakBeh(vals_peakBeh>34 | vals_peakBeh<2) = NaN;
vals_peakBeh(vals_peakBeh==0) = NaN;

load('ProcessedData\PreProcessed_behaviorShifter_smoothed_retuned_firstPeak_021726.mat');
vals_beh_first= [];
for day = 5
    for animal = 1:16
        vals_beh_first = [vals_beh_first,Delay_byDay{1,day}{animal,1}];
    end
end

vals_beh_first(vals_beh_first>34 | vals_beh_first<2) = NaN;
vals_beh_first(vals_beh_first==0) = NaN;



%% do some plotting

figure, hold on
% formatting nonsense to match prism
xticks(0:5:35)
xticklabels(string(0:7));
ylim([0,100])
yticks(0:20:100)
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
% Create first histogram
h1 = histogram(vals_corrShifter, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Blue, semi-transparent
hold on; % Keep the plot for overlay
prism_corr = histcounts(vals_corrShifter);

% Create second histogram
h2 = histogram(vals_beh_first, 'FaceColor', 'r', 'FaceAlpha', 0.5); % Red, semi-transparent
prism_beh_first = histcounts(vals_beh_first);
figure, hold on

cdf1 = cdfplot(vals_corrShifter);
set(cdf1, 'Color', 'k');

cdf2 = cdfplot(vals_beh_first);
set(cdf2, 'Color', 'r');


figure, hold on

% Create first histogram
h3 = histogram(vals_peakBeh, 'FaceColor', 'r', 'FaceAlpha', 0.5); % Blue, semi-transparent
hold on; % Keep the plot for overlay
prism_behPeak = histcounts(vals_peakBeh);
% Create second histogram
h4 = histogram(vals_corrShifter, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Red, semi-transparent
xticks(0:5:35)
xticklabels(string(0:7));
ylim([0,100])
yticks(0:20:100)
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
figure, hold on
h1 = histogram(vals_corrShifter-vals_beh_first, 'BinEdges', -30:3:30, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Blue, semi-transparent
xticks(-30:10:30), xticklabels(-6:2:6);
ylim([0,100])
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
xl1 = xline(0, 'LineWidth', 1.5);
xl2 = xline(nanmean(vals_corrShifter-vals_beh_first), 'LineWidth', 1.5, 'Color', 'r');

figure, hold on
h1 = histogram(vals_corrShifter-vals_peakBeh, 'BinEdges', -30:3:30, 'FaceColor', 'k', 'FaceAlpha', 0.5); % Blue, semi-transparent
xticks(-30:10:30), xticklabels(-6:2:6);
ylim([0,100])
set(gca, 'TickDir', 'out');
set(gca, 'FontName', 'Arial')
fontsize(gcf, 20, 'points')
set(gca, 'LineWidth', 1.5)
xl1 = xline(0, 'LineWidth', 1.5);
xl2 = xline(nanmean(vals_corrShifter-vals_peakBeh), 'LineWidth', 1.5, 'Color', 'r');

