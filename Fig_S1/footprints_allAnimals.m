clear

load('ProcessedData\Footprints_MasterTable.mat')
load("ProcessedData\OutputTable.mat")
load("ProcessedData\PreProcessed.mat")
load('ProcessedData\tables_compiled.mat');
% load('animal_Names_Responses.mat')

%% set these things first

% scaling value for cell size; bigger number makes the cells smaller
size_scalar = 12;
% norm value for tuning 
tuning_cap = 2.5;
% colors for odors

%% Figure of all footprint days, color-coded to show cells present on all

% make cell array for cells present in all sessions
all_day_cutoff = 5;
all_days_cells = cell(size(used_ID));
for k = 1:length(used_ID)
    Animal_pull = Footprints_MasterTable(strcmp(used_ID{k},...
    Footprints_MasterTable.Animal)==true,:);
    match_hold = zeros(1000,length(Days_All));
    for i = 1:length(Days_All)
        all_day = Animal_pull.CellReg_Index(Animal_pull.Day==i);
        all_day(all_day == 0) = [];
        match_hold(all_day,i) = 1;
    end
    all_days_cells{k,1} = find(sum(match_hold,2)==all_day_cutoff);
end

figure
t = tiledlayout(7,length(Days_All));
t.TileSpacing = 'tight';
for k = 1:7
    Animal_pull = Footprints_MasterTable(strcmp(used_ID{k},...
        Footprints_MasterTable.Animal)==true,:);
    all_days_now = all_days_cells{k,1};
    for i = 1:length(Days_All)
        day_pull = Animal_pull(Animal_pull.Day==Days_All(i),:);
        projection = zeros(size(squeeze(day_pull.Footprint{1,1})));
        for j = 1:length(unique(day_pull.Abs_CellNumber))
            cell_now = day_pull.Footprint{j,1};
            cell_now_id = day_pull.CellReg_Index(j,1);
            cell_now = squeeze(cell_now);
            top = unique(cell_now(cell_now>0));
            sizer = floor(length(top)/size_scalar);
            top = top(length(top)-sizer:length(top),:);
            cell_now(cell_now < min(top,[],'all')) = 0;
            overlap_log = (cell_now > 0) + (projection > 0);
            cell_now(overlap_log>1) = 0;
            if ismember(cell_now_id,all_days_now) == 1
                cell_now(cell_now > 0) = 2;
            else
                cell_now(cell_now > 0) = 1;
            end
            projection = projection + cell_now;
        end
        nexttile
        imagesc(projection), colormap 'bone', axis off
    end
end

figure
t = tiledlayout(7,length(Days_All));
t.TileSpacing = 'tight';
for k = 8:14
    Animal_pull = Footprints_MasterTable(strcmp(used_ID{k},...
        Footprints_MasterTable.Animal)==true,:);
    all_days_now = all_days_cells{k,1};
    for i = 1:length(Days_All)
        day_pull = Animal_pull(Animal_pull.Day==Days_All(i),:);
        projection = zeros(size(squeeze(day_pull.Footprint{1,1})));
        for j = 1:length(unique(day_pull.Abs_CellNumber))
            cell_now = day_pull.Footprint{j,1};
            cell_now_id = day_pull.CellReg_Index(j,1);
            cell_now = squeeze(cell_now);
            top = unique(cell_now(cell_now>0));
            sizer = floor(length(top)/size_scalar);
            top = top(length(top)-sizer:length(top),:);
            cell_now(cell_now < min(top,[],'all')) = 0;
            overlap_log = (cell_now > 0) + (projection > 0);
            cell_now(overlap_log>1) = 0;
            if ismember(cell_now_id,all_days_now) == 1
                cell_now(cell_now > 0) = 2;
            else
                cell_now(cell_now > 0) = 1;
            end
            projection = projection + cell_now;
        end
        nexttile
        imagesc(projection), colormap 'bone', axis off
    end
end
