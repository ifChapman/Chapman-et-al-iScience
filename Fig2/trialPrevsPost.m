clear
%%
load('ProcessedData\InputParameters.mat');
load('ProcessedData\OutputTable.mat');

%% Pre-Processing 

% any manual trimming of the main table or adjustments
% exmaple to drop to one animal or day 
%   OutputTable = OutputTable(strcmp('LEC285598', OutputTable.Animal) == true,:);
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

% unique lists of stuff for loops
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

%% demo fig to show overall deltaF pre/post odor
% sorted, but not using the trial number cap from tables_compiled code;
% main OutputTable file has absolute trial number information while the
% other table, at least as of now, does not

% drop to day 1
OutputTable(OutputTable.Day > 1,:) = [];
kept_prior = Animals_All(unique(animal_ID));
OutputTable = OutputTable(ismember(OutputTable.Animal,kept_prior),:);

% matrix for graphing output; rows 1 and 2 are mean/SEM of odor then rows
% 3 and 4 are mean/SEM of Pre Odor
mean_holder = zeros(4,max(OutputTable.Abs_TrialN));
for i = 1:max(OutputTable.Abs_TrialN)
    odor_pull = OutputTable.DeltaValue_Max(OutputTable.Abs_TrialN == i,:);
    pre_pull = OutputTable.Pre_DeltaValue_Max(OutputTable.Abs_TrialN == i,:);
    mean_holder(1,i) = mean(odor_pull,'omitnan');
    mean_holder(2,i) = std(odor_pull,0,'omitnan')/sqrt(length(odor_pull));
    mean_holder(3,i) = mean(pre_pull,'omitnan');
    mean_holder(4,i) = std(pre_pull,0,'omitnan')/sqrt(length(odor_pull));
end

figure, hold on
errorbar(mean_holder(1,:),mean_holder(2,:))
errorbar(mean_holder(3,:),mean_holder(4,:))





