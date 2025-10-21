clear
%% load file

load('OutputTable.mat');
load('InputParameters.mat');
load('Behavior_TraceTable.mat');

%% Pre-Processing 

% any manual trimming of the main table or adjustments
% exmaple to drop to one animal or day 
  % OutputTable = OutputTable(strcmp('NEC273332', OutputTable.Animal) ~= true,:);
%   OutputTable = OutputTable(OutputTable.Day == 1,:);
% drop all from a behavior group 
% OutputTable(strcmp(OutputTable.BehaviorGroup,'PreHab')==true,:) = [];
% drop a subset of days; create vector of days first
% convert AC stamps to E4; makes it easier later on for coding (just don't forget)
% OutputTable.Odor(strcmp(OutputTable.Odor,'AC')==true) = cellstr('E4');

% drop initial days from pre-hab animals (for now, just helps speed); main
% dataset starts at day = 6; also drop post day for now (11) as context
% data not the focus
days_toDrop = 6;
dropper = ismember(OutputTable.Day,days_toDrop);
% set to fales if you want to drop selected; true if you want to keep them
OutputTable = OutputTable(dropper == false,:);

%clear junk for memory 
clear dropper 

%% Keep cells that are present in (numDays) number of days

% unique lists for loops
Animals_All = unique(OutputTable.Animal);
Days_All = unique(OutputTable.Day);
Odors_All = unique(OutputTable.Odor);

% number of days needed to appear in the dataset to be kept, currently 5 (6-10) 
numDays = 5;
for k = 1:length(Animals_All)
    
    % max length of index holder set to 5000; make bigger if your dataset
    % is shockingly huge i guess 
    CR_Index_Day = zeros(5000,length(Days_All));
    Animal_Current = strcmp(Animals_All(k), OutputTable.Animal) == true;
    for i = 1:length(Days_All)
        % trim output file to only the first trial of the animal you're on
        % for all indices of that day 
        trunc_output = OutputTable(((OutputTable.Abs_TrialN == 1) & (strcmp(Animals_All(k), OutputTable.Animal) == true)),:); 
        % pull indices from current day and drop in combined matrix 
        CR_Index_holder = trunc_output.CellReg_Index(trunc_output.Day == Days_All(i));
        CR_Index_Day(1:length(CR_Index_holder),i) = CR_Index_holder;
        clear CR_Index_holder
    end
    
    % get counts of each cell and drop the first row (counts of zeros),
    % then generate logical for whether cells are present on all days
    [binCounts,IDX] = histc(CR_Index_Day,unique(CR_Index_Day));
    binCounts = binCounts(2:end,:);    
    AllDays_Cells = sum(binCounts,2) >= numDays; 
    composite_list = find(AllDays_Cells==1);
    Logical = zeros(length(OutputTable.Animal),1);

    % use the generated logical, only keep ones that are on all the days
    for i = 1:length(OutputTable.Day)
        Current_Cell = OutputTable.CellReg_Index(i);
        if   Animal_Current(i) ~= 1
           Logical(i) = 1;
        elseif   Animal_Current(i) == 1 && ismember(Current_Cell,composite_list) == 1
           Logical(i) = 1;
        else
           Logical(i) = 0;
        end
    end
OutputTable = OutputTable(Logical == 1,:);
end

% clear junk for memory 
clear Animal_Current Logical 

%% pull new delta value from shifter window array based on best alignment by corr 

% specify window length to use for pulling max corr trial, IN FRAMES
window = 35; 

% seed multiplier for window shuffling
rng(10); %10 for fig

% reinitialize unique lists in case you dropped any from above chunk
Animals_All = unique(OutputTable.Animal);
Days_All = unique(OutputTable.Day);
Odors_All = unique(OutputTable.Odor);

% pull behavior groups but with matching size to animals_all array
[BehG,Animal_Tag,Behavior_Tag] = findgroups(OutputTable.Animal,OutputTable.BehaviorGroup);  

% pull deltas; for shifter, uses max corr value between all trials of the
% same odor within a day in the given frame window
OG_delta_byDay = cell(1,length(Days_All));
Delay_byDay = cell(1,length(Days_All));
Pre_Delay_byDay = cell(1,length(Days_All));
Pre_delta_byDay = cell(1,length(Days_All));
Pre_animal_odor_shifterByDay = cell(1,length(Days_All));
animal_odor_shifterByDay = cell(1,length(Days_All));
animal_odor_shifterByDay_responders = cell(1,length(Days_All));
Pre_animal_odor_shifterByDay_responders = cell(1,length(Days_All));
ID_validator = cell(1,length(Days_All));
for d = 1:length(Days_All)
    animal_odor_OG = cell(length(Animals_All),1);
    animal_odor_Delay = cell(length(Animals_All),1);
    Pre_animal_odor_Delay = cell(length(Animals_All),1);
    animal_odor_Pre = cell(length(Animals_All),1);
    animal_odor_shifterBest = cell(length(Animals_All),1);
    Pre_animal_odor_shifterBest = cell(length(Animals_All),1);
    animal_odor_shifterResponders = cell(length(Animals_All),1);
    Pre_animal_odor_shifterResponders = cell(length(Animals_All),1);
    animal_id_final = cell(length(Animals_All),1);
    for i = 1:length(Animals_All)
        cells_allID = unique(OutputTable.CellReg_Index(strcmp(OutputTable.Animal,Animals_All(i))==true,:));
        shifter_odor_final = cell(1,length(Odors_All));
        Pre_shifter_odor_final = cell(1,length(Odors_All));
        shifter_odor_delay = cell(1,length(Odors_All));
        Pre_shifter_odor_delay = cell(1,length(Odors_All));
        shifter_odor_final_responders = cell(1,length(Odors_All));
        Pre_shifter_odor_finalresponders = cell(1,length(Odors_All));
        OG_odor_final = cell(1,length(Odors_All));
        % shuffle for Pre; creates full matrix here for all 60 trials, then
        % indexes during the loop as if columns are odors and rows are trials
        pseudo_shuffle = 1:max(OutputTable.Abs_TrialN);
        pseudo_shuffle = pseudo_shuffle(randperm(length(pseudo_shuffle)));
        pseudo_shuffle = reshape(pseudo_shuffle,max(OutputTable.Stim_TrialN),length(Odors_All));
        for j = 1:length(Odors_All)
            behavior_odor = BEHTrace_Table.NoseDisp_trial_final((strcmp(BEHTrace_Table.Odor,Odors_All(j))==true) ...
                    & BEHTrace_Table.Day == Days_All(d) &...
                    strcmp(BEHTrace_Table.Animal,Animals_All(i))==true,:);
            motion_odor = BEHTrace_Table.Motion_trial_final((strcmp(BEHTrace_Table.Odor,Odors_All(j))==true) ...
                    & BEHTrace_Table.Day == Days_All(d) &...
                    strcmp(BEHTrace_Table.Animal,Animals_All(i))==true,:);
            prepped_for_corr = cell(1,max(OutputTable.Stim_TrialN));
            Pre_prepped_for_corr = cell(1,max(OutputTable.Stim_TrialN));
            cells_sorted = zeros(length(cells_allID),inputValue.shifter_maxFrames);
            OG_sorted = zeros(length(cells_allID),1);
            OG_sorted_final = zeros(length(cells_allID),max(OutputTable.Stim_TrialN));
            Pre_sorted = zeros(length(cells_allID),inputValue.shifter_maxFrames);
            pre_responders_sorted = zeros(length(cells_allID),inputValue.shifter_maxFrames);
            responders_sorted = zeros(length(cells_allID),inputValue.shifter_maxFrames);
            Pre_prepped_for_corr_responders = cell(1,max(OutputTable.Stim_TrialN));
            prepped_for_corr_responders = cell(1,max(OutputTable.Stim_TrialN));
            sorted_id = zeros(length(cells_allID),1);
            for k = 1:max(OutputTable.Stim_TrialN)
                cells_now = OutputTable.DeltaValue_MaxShifter((OutputTable.Stim_TrialN == k) & ...
                    strcmp(OutputTable.Odor,Odors_All(j))==true & OutputTable.Day == Days_All(d) &...
                    strcmp(OutputTable.Animal,Animals_All(i))==true,:);
                OG_cells_now = OutputTable.DeltaValue_Max((OutputTable.Stim_TrialN == k) & ...
                    strcmp(OutputTable.Odor,Odors_All(j))==true & OutputTable.Day == Days_All(d) &...
                    strcmp(OutputTable.Animal,Animals_All(i))==true,:);
                % change to below if wanting a set timepoint post onset for
                % the shifter to test 
                % OG_cells_now = OutputTable.DeltaValue_MaxShifter((OutputTable.Stim_TrialN == k) & ...
                %     strcmp(OutputTable.Odor,Odors_All(j))==true & OutputTable.Day == Days_All(d) &...
                %     strcmp(OutputTable.Animal,Animals_All(i))==true,:); 
                % OG_cells_now = OG_cells_now(:,6);
                Pre_cells_now = OutputTable.Pre_DeltaValue_MaxShifter((OutputTable.Abs_TrialN == pseudo_shuffle(k,j)) & ...
                    OutputTable.Day == Days_All(d) & strcmp(OutputTable.Animal,Animals_All(i))==true,:);
                % drop pre's to one column if not using shifter
                %Pre_cells_now = Pre_cells_now(:,1);
                responders_now = OutputTable.Responders_CombinedEX_Shifter((OutputTable.Stim_TrialN == k) & ...
                    strcmp(OutputTable.Odor,Odors_All(j))==true & OutputTable.Day == Days_All(d) &...
                    strcmp(OutputTable.Animal,Animals_All(i))==true,:);
                Pre_responders_now = OutputTable.Pre_Responders_CombinedEX((OutputTable.Abs_TrialN == pseudo_shuffle(k,j)) & ...
                    OutputTable.Day == Days_All(d) & strcmp(OutputTable.Animal,Animals_All(i))==true,:);
                IDs_now = OutputTable.CellReg_Index((OutputTable.Stim_TrialN == k) & ...
                    strcmp(OutputTable.Odor,Odors_All(j))==true & OutputTable.Day == Days_All(d) &...
                    strcmp(OutputTable.Animal,Animals_All(i))==true,:);
                % sort everybody by their cell reg ID to align across days 
                [Log,idx_id] = ismember(cells_allID,IDs_now);
                for q = 1:length(cells_allID)
                    if idx_id(q) > 0
                        cells_sorted(q,:) = cells_now(idx_id(q),:);
                        OG_sorted(q,:) = OG_cells_now(idx_id(q),:);
                        Pre_sorted(q,:) = Pre_cells_now(idx_id(q),:);
                        sorted_id(q,:) = IDs_now(idx_id(q));
                        responders_sorted(q,:) = responders_now(idx_id(q),:);
                        pre_responders_sorted(q,:) = Pre_responders_now(idx_id(q),:);
                    else
                        OG_sorted(q,:) = OG_sorted(q,:);
                        Pre_sorted(q,:) = Pre_sorted(q,:);
                        cells_sorted(q,:) = cells_sorted(q,:);
                        responders_sorted(q,:) = responders_sorted(q,:);
                        pre_responders_sorted(q,:) = pre_responders_sorted(q,:);
                    end
                end
                cells_sorted(cells_sorted == 0) = NaN;
                OG_sorted(OG_sorted == 0) = NaN;
                Pre_sorted(Pre_sorted == 0) = NaN;
                responders_sorted(responders_sorted == 0) = NaN;
                pre_responders_sorted(pre_responders_sorted == 0) = NaN;
                OG_sorted_final(:,k) = OG_sorted;
                prepped_for_corr_responders{1,k} = responders_sorted;
                Pre_prepped_for_corr_responders{1,k} = pre_responders_sorted;
                prepped_for_corr{1,k} = cells_sorted; 
                Pre_prepped_for_corr{1,k} = Pre_sorted;
            end
            corr_singOdor = corr(cell2mat(prepped_for_corr));
            shifter_best_idx = zeros(1,max(OutputTable.Stim_TrialN));
            for n = 1:max(OutputTable.Stim_TrialN)
                down_match = 1:(60/5):(60*7);
                if length(behavior_odor) > 0
                    for_avg = movmean(behavior_odor{n},12,'omitnan');
                    for_avg = for_avg(1501:1920);
                    check_any = find(for_avg > -500);
                    if sum(check_any)>0
                        [~,check_max] = max(for_avg);
                        [~,idx] = min(abs(down_match-check_max));
                        shifter_best_idx(1,n) = idx;
                    else
                        for_avg = movmean(motion_odor{n},12,'omitnan');
                        for_avg = for_avg(1501:1920);
                        [~,check_max] = max(for_avg);
                        [~,idx] = min(abs(down_match-check_max));
                        shifter_best_idx(1,n) = 1;
                    end
                else
                    shifter_best_idx(1,n) = 1;
                end
            end
            Pre_corr_singOdor = corr(cell2mat(Pre_prepped_for_corr),'rows','complete');
            Pre_shifter_best_idx = zeros(1,max(OutputTable.Stim_TrialN));
            for n = 1:max(OutputTable.Stim_TrialN)
            if length(behavior_odor) > 0
                down_match = 1:(60/5):(60*7);
                for_avg = movmean(behavior_odor{n},12,'omitnan');
                for_avg = for_avg(1501:1920);
                check_any = find(for_avg > -500);
                if sum(check_any)>0
                    [~,check_max] = max(for_avg);
                    [~,idx] = min(abs(down_match-check_max));
                    Pre_shifter_best_idx(1,n) = idx;
                else
                    for_avg = movmean(motion_odor{n},12,'omitnan');
                    for_avg = for_avg(1501:1920);
                    [~,check_max] = max(for_avg);
                    [~,idx] = min(abs(down_match-check_max));
                    Pre_shifter_best_idx(1,n) = idx;
                end
            else
                Pre_shifter_best_idx(1,n) = 1;
            end
            end
            shifter_best_odor = zeros(size(cells_allID,1),max(OutputTable.Stim_TrialN));
            Pre_shifter_best_odor = zeros(size(cells_allID,1),max(OutputTable.Stim_TrialN));
            shifter_best_odor_responders = zeros(size(cells_allID,1),max(OutputTable.Stim_TrialN));
            Pre_shifter_odorresponders = zeros(size(cells_allID,1),max(OutputTable.Stim_TrialN));
            for k = 1:max(OutputTable.Stim_TrialN)
                cells_now = prepped_for_corr{1,k};
                Pre_cells_now = Pre_prepped_for_corr{1,k};
                responders_now = prepped_for_corr_responders{1,k};
                pre_responders_now = Pre_prepped_for_corr_responders{1,k};
                shifter_best_cell_responders = responders_now(:,shifter_best_idx(k));
                Pre_shifter_best_cell_responders = pre_responders_now(:,Pre_shifter_best_idx(k));
                shifter_best_cell = cells_now(:,shifter_best_idx(k));
                shifter_best_odor(:,k) = shifter_best_cell; 
                shifter_best_odor_responders(:,k) = shifter_best_cell .* shifter_best_cell_responders;
                Pre_shifter_best_cell = Pre_cells_now(:,Pre_shifter_best_idx(k));
                Pre_shifter_best_odor(:,k) = Pre_shifter_best_cell;
                Pre_shifter_odorresponders(:,k) = Pre_shifter_best_cell .* Pre_shifter_best_cell_responders;
            end
            shifter_best_odor_responders(shifter_best_odor_responders == 0) = NaN;
            Pre_shifter_odorresponders(Pre_shifter_odorresponders == 0) = NaN;
            shifter_odor_final_responders{1,j} = shifter_best_odor_responders;
            shifter_odor_final{1,j} = shifter_best_odor;
            Pre_shifter_odor_final{1,j} = Pre_shifter_best_odor;
            Pre_shifter_odor_finalresponders{1,j} = Pre_shifter_odorresponders;
            % adding logicals in to drop missing trials; prior code still
            % tries to calculated a shifted time for a missing trial. Not
            % an issue for cell selection as the NaN for the trial is still
            % inserted into the arrray.
            shifter_odor_delay{1,j} = shifter_best_idx .* ~isnan(sum(shifter_best_odor,1));
            Pre_shifter_odor_delay{1,j} = Pre_shifter_best_idx .* ~isnan(sum(Pre_shifter_best_odor,1));
            OG_odor_final{1,j} = OG_sorted_final; 
        end
        animal_id_final{i,1} = sorted_id;
        animal_odor_Delay{i,1} = cell2mat(shifter_odor_delay);
        Pre_animal_odor_Delay{i,1} = cell2mat(Pre_shifter_odor_delay);
        animal_odor_OG{i,1} = cell2mat(OG_odor_final);
        Pre_animal_odor_shifterBest{i,1} = cell2mat(Pre_shifter_odor_final);
        Pre_animal_odor_shifterResponders{i,1} = cell2mat(Pre_shifter_odor_finalresponders);
        animal_odor_shifterBest{i,1} = cell2mat(shifter_odor_final);
        animal_odor_shifterResponders{i,1} = cell2mat(shifter_odor_final_responders);
    end
    % ID validator to check alignment
    ID_validator{1,d} = animal_id_final;
    Delay_byDay{1,d} = animal_odor_Delay;
    Pre_Delay_byDay{1,d} = Pre_animal_odor_Delay;
    OG_delta_byDay{1,d} = animal_odor_OG;
    Pre_delta_byDay{1,d} = animal_odor_Pre;
    Pre_animal_odor_shifterByDay{1,d} = Pre_animal_odor_shifterBest;
    Pre_animal_odor_shifterByDay_responders{1,d} = Pre_animal_odor_shifterResponders;
    animal_odor_shifterByDay{1,d} = animal_odor_shifterBest;
    animal_odor_shifterByDay_responders{1,d} = animal_odor_shifterResponders;
end

%% sort from best to worst odor on first day, then use that on all days

% initialize empties, then generate best odor order from D1 data
animal_sorted_bestCorr = cell(length(Animals_All),1);
corr_idx_D1 = cell(length(Animals_All),1);
day_now = animal_odor_shifterByDay{1,1};
corr_cutoff = 0.5;
log_cutoff = zeros(length(Animals_All),1);
for i = 1:length(Animals_All)
    cells_now = day_now{i,1};
    cells_now(sum(isnan(cells_now),2)==size(cells_now,2),:) = [];
    corr_now = corr(cells_now);
    odor_mean_Corr = zeros(1,length(Odors_All));
    for m = 1:length(Odors_All)
       odor_now = corr_now(m*10-9:m*10,m*10-9:m*10);
       odor_meanCorr_holder = mean(odor_now(odor_now<1),'all','omitnan');
       odor_mean_Corr(1,m) = odor_meanCorr_holder;
    end
    [sorted,corr_idx] = sort(odor_mean_Corr,'descend');
    if max(sorted) > corr_cutoff
        log_cutoff(i) = 1;
    end
    corr_idx_D1{i,1} = corr_idx;
end

% initialize empties, then sort based on the D1 index
animal_sorted_bestCorrDay = cell(1,length(Days_All));
animal_sorted_bestCorrDay_responders = cell(1,length(Days_All));
for d = 1:length(Days_All)
    day_now = animal_odor_shifterByDay{1,d};
    day_now_responder = animal_odor_shifterByDay_responders{1,d};
    day_holder = cell(length(Animals_All),1);
    responder_holder = cell(length(Animals_All),1);
    for i = 1:length(Animals_All)
        responders_now = day_now_responder{i,1};
        cells_now = day_now{i,1};
        responder_sorted = cell(1,length(Odors_All));
        odor_sorted = cell(1,length(Odors_All));
        corr_idx = corr_idx_D1{i,1};
        for t = 1:length(Odors_All)
            m = corr_idx(t);
            odor_meanSorter = cells_now(:,m*10-9:m*10);
            responder_meanSorter = responders_now(:,m*10-9:m*10);
            odor_sorted{1,t} = odor_meanSorter;
            responder_sorted{1,t} = responder_meanSorter;
        end
    day_holder{i,1} = cell2mat(odor_sorted);
    responder_holder{i,1} = cell2mat(responder_sorted);
    end
    animal_sorted_bestCorrDay{1,d} = day_holder; 
    animal_sorted_bestCorrDay_responders{1,d} = responder_holder;
end

%% sort from best to worst odor on every day 

% initialize empties, then sort based on best corr each day 
sorted_bestCorr_EveryDay = cell(1,length(Days_All));
sorted_bestCorr_EveryDay_responders = cell(1,length(Days_All));
sorted_bestCorr_EveryDay_idx = cell(1,length(Days_All));
sorted_bestCorr_EveryDay_value = cell(1,length(Days_All));
for d = 1:length(Days_All)
    day_now = animal_odor_shifterByDay{1,d};
    day_now_responder = animal_odor_shifterByDay_responders{1,d};
    day_holder = cell(length(Animals_All),1);
    responder_holder = cell(length(Animals_All),1);
    corr_value_day = cell(length(Animals_All),1);
    corr_idx_nDay = cell(length(Animals_All),1);
    for i = 1:length(Animals_All)
        cells_now = day_now{i,1};
        cells_now(sum(isnan(cells_now),2)==size(cells_now,2),:) = [];
        corr_now = corr(cells_now);
        odor_mean_Corr = zeros(1,length(Odors_All));
        for m = 1:length(Odors_All)
           odor_now = corr_now(m*10-9:m*10,m*10-9:m*10);
           odor_meanCorr_holder = mean(odor_now(odor_now<1),'all','omitnan');
           odor_mean_Corr(1,m) = odor_meanCorr_holder;
        end
        [sorted,corr_idx] = sort(odor_mean_Corr,'descend');
        if max(sorted) > corr_cutoff
            log_cutoff(i) = 1;
        end
        corr_value_day{i,1} = sorted;
        corr_idx_nDay{i,1} = corr_idx;
    end
    for i = 1:length(Animals_All)
        responders_now = day_now_responder{i,1};
        cells_now = day_now{i,1};
        responder_sorted = cell(1,length(Odors_All));
        odor_sorted = cell(1,length(Odors_All));
        corr_idx = corr_idx_nDay{i,1};
        for t = 1:length(Odors_All)
            m = corr_idx(t);
            odor_meanSorter = cells_now(:,m*10-9:m*10);
            responder_meanSorter = responders_now(:,m*10-9:m*10);
            odor_sorted{1,t} = odor_meanSorter;
            responder_sorted{1,t} = responder_meanSorter;
        end
    day_holder{i,1} = cell2mat(odor_sorted);
    responder_holder{i,1} = cell2mat(responder_sorted);
    end
    sorted_bestCorr_EveryDay_value{1,d} = corr_value_day;
    sorted_bestCorr_EveryDay_idx{1,d} = corr_idx_nDay;
    sorted_bestCorr_EveryDay{1,d} = day_holder; 
    sorted_bestCorr_EveryDay_responders{1,d} = responder_holder;
end

%% Dump all output into a single file; load to generate tables_compiled
save('PreProcessed_behaviorShifter_smoothed.mat');

