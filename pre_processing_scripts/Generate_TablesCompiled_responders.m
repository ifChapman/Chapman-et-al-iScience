clear
%% load PreProcessed file
load('PreProcessed.mat');
% need the one from main Generate_TablesCompiled code to match; NaN
% indicates lack of response, so this is needed instead of the prior
% code to drop missing rows at the end
load('trial_drop_logical.mat');

%% Re-org deltas and drop lost trials so dataset has no missing values

% intialize empties and parameters
tables_compiled = cell(1,5);
trial_cutoff = 8; % number trials to keep 
norm_toggle = 0; % 0 to not, 1 to normalize as below

% pull table values, drop NaN to bottom of the table, drop later trials
% based on trial_cutoff number
for k = 1:5
    table_now = cell2table(cell(0,3), 'VariableNames', {'Deltas','Odor','TrialN'});
    % change what is responses all based on what type of data to use
    % (baseline, best odor, responders only, etc)
    responses_all = animal_odor_shifterByDay{1,k};
    responders_all = animal_odor_shifterByDay_responders{1,k};
    % ignore prehab animals
    responses_all = responses_all(~(strcmp(Behavior_Tag,'PreHab')));
    responses_all = cell2mat(responses_all);
    responders_all = responders_all(~(strcmp(Behavior_Tag,'PreHab')));
    responders_all = cell2mat(responders_all);
    for i = 1:length(Odors_All)
        responses_now = responses_all(:,i*10-9:i*10);
        responders_now = responders_all(:,i*10-9:i*10);
        Deltas_all = zeros(10,size(responses_now,1));
        Responders_all = zeros(10,size(responders_now,1));
        for j = 1:10
            pull = responses_now(:,j);
            Deltas_all(j,:) = pull.';
            pull = responders_now(:,j);
            Responders_all(j,:) = pull.';
        end
        [~,idr] = sort(isnan(Deltas_all),1);
        sorted_deltas = zeros(size(Deltas_all));
        sorted_responders = zeros(size(Deltas_all));
        for j = 1:size(Deltas_all,2)
            if sum(isnan(Deltas_all(:,j))) > 0
                resort_cell = Deltas_all(:,j);
                resort_cell = resort_cell(idr(:,j));
                sorted_deltas(:,j) = resort_cell;
                resort_cell = Responders_all(:,j);
                resort_cell = resort_cell(idr(:,j));
                sorted_responders(:,j) = resort_cell;
            else
                sorted_deltas(:,j) = Deltas_all(:,j);
                sorted_responders(:,j) = Responders_all(:,j);
            end
        end
        % final things for adding to the table
        Deltas = sorted_responders(1:trial_cutoff,:);
        Odor = repmat(Odors_All(i),trial_cutoff,1);
        TrialN = (1:trial_cutoff).';
        new_input = table(Deltas,Odor,TrialN);  
        table_now = [table_now;new_input];
    end
    tables_compiled{1,k} = table_now;
end
tables_compiled = tables_compiled.'; 

for i = 1:length(tables_compiled)
    tables_now = tables_compiled{i,1};
    tables_now.Deltas(:,dropper_final==1) = [];
    tables_compiled{i,1} = tables_now;
end

% normalize values if desired; min shift, then norm to max value each day for each cell
deltas_norm = tables_compiled{1,1}.Deltas;
if norm_toggle == 1
    for i = 1:length(tables_compiled)
        % change norm if you want to do every day or only on one day
        
        deltas_now = tables_compiled{i,1}.Deltas;
        % min shift
        min_table = min(deltas_now,[],1);
        min_norm = min(deltas_norm,[],1);
        deltas_norm = deltas_norm-min_norm;
        deltas_now = deltas_now-min_table;
        % norm to max for every cell
        deltas_now = deltas_now ./ max(deltas_norm,[],1);
        tables_compiled{i,1}.Deltas = deltas_now;
    end
end

%% save the needed tables_compiled array
save('tables_compiled_responders.mat','tables_compiled');
