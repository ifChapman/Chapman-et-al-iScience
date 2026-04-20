clear
load('ProcessedData\tables_compiled_bestD1.mat');
%% generate heatmaps for trials by D1 responsive order

% for now, i'm editing colormaps in GUI as I haven't figured out
% how to to do that right in code as of yet
figure, tiledlayout(1,5)
D1 = tables_compiled{1,1}.Deltas(1:8,:).';
[~,idx] = sort(mean(D1,2),1,'descend');
for i = 1:length(tables_compiled)
    D_now = tables_compiled{i,1}.Deltas(1:8,:).';
    clim = [0,50];
    nexttile
    imagesc(D_now(idx,:),clim), colormap 'white'
    set(gca, 'XTick', [], 'Ytick',[]);
end

