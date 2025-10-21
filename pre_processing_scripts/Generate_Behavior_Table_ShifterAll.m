%% generate new tables compiled with behavior values included
clear
load('InputParameters.mat');
load('PreProcessed.mat');
load('Behavior_TraceTable.mat');

% expected frame count; used to weed out missing trials at one point
max_frames = (inputValue.trialTrace_Pre*60 + inputValue.trialTrace_Post*60);
% other pre-loop settings
used_animals = Animals_All(~(strcmp(Behavior_Tag,'PreHab')));
% making sure animal with no behavior isn't in there
used_animals(strcmp(used_animals,'NEC273332')==true) = [];
tables_compiled = cell(1,5);
trial_cutoff = 8; % number trials to keep
beh_fr = inputValue.frate_BEH;
converter = inputValue.frate_BEH / inputValue.frate;
pre_trial_start = inputValue.behaviorTrace_Pre * inputValue.frate_BEH - (inputValue.trialTrace_Pre * inputValue.frate_BEH);
trial_start = inputValue.behaviorTrace_Pre * inputValue.frate_BEH;

% first compile a list of all behavior, adjusted for the corr shift 
% timepoint to be used for normalization.
BEHnose_allNormer = cell(1,5);
BEHmotion_allNormer = cell(1,5);
BEH_allTrials = cell(1,5);
for k = 1:5
    table_now = cell2table(cell(0,3), 'VariableNames', {'Beh_Index','Odor','TrialN'});
    responses_all = animal_odor_shifterByDay{1,k};
    Pre_delay_all = Pre_Delay_byDay{1,k};
    delay_all = Delay_byDay{1,k};
    % make sure animals that shouldn't be in there aren't
    responses_all = responses_all(~(strcmp(Behavior_Tag,'PreHab')));
    responses_all = responses_all(~(strcmp(used_animals,'NEC273332')));
    final_day = cell(length(Odors_All),length(responses_all));
    animal_nose_normer = cell(length(responses_all),1);
    animal_motion_normer = cell(length(responses_all),1);
    animal_Trials = cell(length(responses_all),2);
    for p = 1:length(responses_all)
        responses_animal = responses_all{p,1};
        pre_delay_animal = Pre_delay_all{p,1};
        delay_animal = delay_all{p,1};
        motion_holder = zeros(2,length(pre_delay_animal));
        nose_holder = zeros(2,length(pre_delay_animal));
        motion_trials = cell(2,length(pre_delay_animal));
        nose_trials = cell(2,length(pre_delay_animal));
        % take values you want for all trials of a behavior for the animal
        % you're on (max for nose, average for motion), pull at max trial
        % value for each measure to use as a normalization value (0-1 scale
        % for all subsequent trials)
        for i = 1:length(pre_delay_animal)
            % pull delay, convert from scope to behavior framerate
            BEH_now = BEHTrace_Table(strcmp(BEHTrace_Table.Animal,used_animals(p))==true &...
                BEHTrace_Table.Day == k & BEHTrace_Table.Abs_TrialN == i,:);
            odor_now = find(strcmp(BEH_now.Odor,Odors_All)==true);
            trial_delay = odor_now*10-9 + (BEH_now.Stim_TrialN-1);
            pre_delay_now= pre_delay_animal(:,trial_delay);
            pre_start = (pre_delay_now* converter) + pre_trial_start - (converter-1);
            pre_endpoint = pre_start + (inputValue.postTrial * beh_fr);
            delay_now = delay_animal(:,trial_delay);
            start = (delay_now* converter) + trial_start - (converter-1);
            endpoint = start + (inputValue.postTrial * beh_fr);
            total_frames = length(cell2mat(BEH_now.Motion_trial_final));
            if total_frames < max_frames
                motion_holder(:,i) = NaN;
                nose_holder(:,i) = NaN;
            else
            motion_now = cell2mat(BEH_now.Motion_trial_final);
            nose_now = cell2mat(BEH_now.NoseDisp_trial_final);  
            pre_motion_now = motion_now(:,pre_start:pre_endpoint);
            pre_nose_now = nose_now(:,pre_start:pre_endpoint);
            pre_motion_trial = mean(pre_motion_now,'omitnan');
            [~,max_idx] = max(pre_nose_now, [], 'omitnan');
            window = max_idx-6:max_idx+6;
            window = window(window > 0 & window < 302);
            pre_nose_trial = mean(pre_nose_now(:,window),'omitnan');
            motion_holder(1,i) = pre_motion_trial;
            nose_holder(1,i) = pre_nose_trial;
            trial_motion_now = motion_now(:,start:endpoint);
            trial_nose_now = nose_now(:,start:endpoint);
            [~,max_idx] = max(trial_nose_now, [], 'omitnan');
            window = max_idx-6:max_idx+6;
            window = window(window > 0 & window < 302);
            nose_trial = mean(trial_nose_now(:,window),'omitnan');
            motion_trials{2,i} = trial_motion_now;
            nose_trials{2,i} = trial_nose_now;
            motion_holder(2,i) = mean(trial_motion_now, 'omitnan');
            nose_holder(2,i) = mean(nose_trial, 'omitnan');
            motion_trials{1,i} = mean(trial_motion_now, 'omitnan');
            nose_trials{1,i} = mean(nose_trial, 'omitnan');
            end
        end
        animal_Trials{p,1} = motion_trials;
        animal_Trials{p,2} = nose_trials;
        animal_nose_normer{p,1} = nose_holder;
        animal_motion_normer{p,1} = motion_holder;
    end
    BEH_allTrials{1,k} = animal_Trials;
    BEHmotion_allNormer{1,k} = animal_motion_normer;
    BEHnose_allNormer{1,k} = animal_nose_normer;
end

% make new matrix of nose min/max and motion max trial values for norm
animal_Normer = zeros(length(responses_all),2);
for p = 1:length(responses_all)
    combo_nose = cell(1,5);
    combo_motion = cell(1,5);
    for i = 1:5
        day_pull_motion = BEHmotion_allNormer{1,i};
        day_pull_nose = BEHnose_allNormer{1,i}; 
        day_pull_motion = day_pull_motion{p,1};
        day_pull_nose = day_pull_nose{p,1};
        combo_nose{1,i} = day_pull_nose;
        combo_motion{1,i} = day_pull_motion;
    end
    animal_Normer(p,1) = max(cell2mat(combo_nose),[],'all','omitnan');
    animal_Normer(p,3) = max(cell2mat(combo_motion),[],'all','omitnan');
    animal_Normer(p,2) = min(cell2mat(combo_nose),[],'all','omitnan');
end

% pull behavior values at shifted timepoints; normalizing to max of any
% trial for any behavior
for k = 1:5
    table_now = cell2table(cell(0,10), 'VariableNames', {'Beh_Index','Nose','Motion',...
        'Beh_Index_Pre','Nose_Pre','Motion_Pre','Nose_Raw','Nose_Raw_Pre','Odor','TrialN'});
    responses_all = animal_odor_shifterByDay{1,k};
    responses_all = responses_all(~(strcmp(Behavior_Tag,'PreHab')));
    % drop animal without behavior
    responses_all = responses_all(~(strcmp(used_animals,'NEC273332')));
    final_day = cell(length(Odors_All),length(responses_all));
    final_day_noseBEH = cell(length(Odors_All),length(responses_all));
    final_day_motionBEH = cell(length(Odors_All),length(responses_all));
    pre_final_day = cell(length(Odors_All),length(responses_all));
    nose_final_raw = cell(length(Odors_All),length(responses_all));
    pre_nose_final_raw = cell(length(Odors_All),length(responses_all));
    pre_final_day_noseBEH = cell(length(Odors_All),length(responses_all));
    pre_final_day_motionBEH = cell(length(Odors_All),length(responses_all));
    Odor = cell(6,1);
    Pre_delay_all = Pre_Delay_byDay{1,k};
    delay_all = Delay_byDay{1,k};
    for p = 1:length(responses_all)
        pre_delay_animal = Pre_delay_all{p,1};
        delay_animal = delay_all{p,1};
        responses_animal = responses_all{p,1};
        motion_max = animal_Normer(p,3);
        nose_min = animal_Normer(p,2);
        nose_max = animal_Normer(p,1) + abs(nose_min);

        for i = 1:length(Odors_All)
            responses_now = (responses_animal(:,i*10-9:i*10)).';
            pre_delay_now= (pre_delay_animal(:,i*10-9:i*10)).';
            delay_now = (delay_animal(:,i*10-9:i*10)).';
            BEH_now = BEHTrace_Table(strcmp(BEHTrace_Table.Animal,used_animals(p))==true &...
                BEHTrace_Table.Day == k & strcmp(BEHTrace_Table.Odor,Odors_All(i))==true,:);
            %decide behavior to use; edit here for switching
            motion_now = BEH_now.Motion_trial_final;
            nose_now = BEH_now.NoseDisp_trial_final;  
            nose_beh = zeros(10,3);
            motion_beh = zeros(10,2);
            motion_idx = zeros(10,2);

            for j = 1:length(motion_now)
                % pull values for each trial; min shift nose
                pre_delay_trial = pre_delay_now(j,:);
                pre_start = (pre_delay_trial * converter) + pre_trial_start - (converter-1);
                pre_endpoint = pre_start + (inputValue.postTrial * beh_fr);
                delay_trial = delay_now(j,:);
                start = (delay_trial * converter) + trial_start - (converter-1);
                endpoint = start + (inputValue.postTrial * beh_fr);
                motion_pull = motion_now{j,1};
                nose_pull = nose_now{j,1};
                if length(motion_pull) < max_frames
                    motion_idx(j,:) = NaN;
                else
                pre_motion_trial = mean(motion_pull(:,pre_start:pre_endpoint),'all','omitnan');
                pre_nose_now = nose_pull(:,pre_start:pre_endpoint);
                [~,max_idx] = max(pre_nose_now, [], 'omitnan');
                window = max_idx-6:max_idx+6;
                window = window(window > 0 & window < 302);
                pre_nose_trial = mean(pre_nose_now(window),'omitnan');
                motion_trial = mean(motion_pull(:,start:endpoint),'all','omitnan');
                trial_nose_now = nose_pull(:,start:endpoint);
                [~,max_idx] = max(trial_nose_now, [], 'omitnan');
                window = max_idx-6:max_idx+6;
                window = window(window > 0 & window < 302);
                nose_trial = mean(trial_nose_now(window),'omitnan');
                % norm to prior day calculated average for each
                pre_motion_trial_norm = pre_motion_trial / motion_max;
                pre_nose_trial_norm = (pre_nose_trial + abs(nose_min)) / nose_max;
                % this was the code to norm earlier; realized I goofed as
                % was norming on values before picking at neural
                % timepoints, meant I had close to the correct values (but
                % not quite) due to the shift. Corrected by just making
                % this step not normalizing then fixing it post completion
                % of tables compiled in a new loop. Really not pretty code,
                % but it yields the correct result now. 
                motion_trial_norm = motion_trial;
                nose_trial_norm = nose_trial;
                % motion_trial_norm = motion_trial / motion_max;
                % nose_trial_norm = (nose_trial + abs(nose_min)) / nose_max;
                % make sure norm worked right
                % if nose_trial_norm > 1
                %     pause
                % end
                % combine into a single metric by averaging norm values;
                % omits nan so any time nose displacement isn't there, its
                % just ignored; should always between 0 and 1
                nose_beh(j,1) = pre_nose_trial_norm;
                nose_beh(j,2) = nose_trial_norm;
                nose_beh(j,3) = nose_trial;
                nose_beh(j,4) = pre_nose_trial;
                motion_beh(j,1) = pre_motion_trial_norm;
                motion_beh(j,2) = motion_trial_norm;
                motion_idx(j,1) = mean([pre_motion_trial_norm;pre_nose_trial_norm],'omitnan');
                motion_idx(j,2) = mean([motion_trial_norm;nose_trial_norm],'omitnan');
                end
            end

            % continue with sorting for nan to trim down to cutoff
            % sorting AS WITH NEURAL RESPONSES so that they match; not just
            % the same re-sort by NaN trials as with the response values
            [~,idr] = sort(isnan(responses_now),1);
            sorted_deltas = responses_now(idr(:,1),:);
            sorted_motion = motion_idx(idr(:,1),:);
            sorted_nose_beh = nose_beh(idr(:,1),:);
            sorted_motion_beh = motion_beh(idr(:,1),:);
    
            % trim last trials to cutoff
            sorted_deltas = sorted_deltas(1:trial_cutoff,:);
            sorted_motion = sorted_motion(1:trial_cutoff,:);
            sorted_nose_beh = sorted_nose_beh(1:trial_cutoff,:);
            sorted_motion_beh = sorted_motion_beh(1:trial_cutoff,:);
            % resort by behavior index before moving to final table
            final_deltas = sorted_motion;
            final_day{i,p} = final_deltas(:,2);
            final_day_noseBEH{i,p} = sorted_nose_beh(:,2);
            final_day_motionBEH{i,p} = sorted_motion_beh(:,2);
            pre_final_day{i,p} = final_deltas(:,1);
            pre_final_day_noseBEH{i,p} = sorted_nose_beh(:,1);
            nose_final_raw{i,p} = sorted_nose_beh(:,3);
            pre_nose_final_raw{i,p} = sorted_nose_beh(:,4);
            pre_final_day_motionBEH{i,p} = sorted_motion_beh(:,1);
            Odor{i,1} = repmat(Odors_All(i),trial_cutoff,1);
        end
    end
    final_day = cell2mat(final_day);
    final_day_noseBEH = cell2mat(final_day_noseBEH);
    final_day_motionBEH = cell2mat(final_day_motionBEH);
    pre_final_day = cell2mat(pre_final_day);
    pre_final_day_noseBEH = cell2mat(pre_final_day_noseBEH);
    pre_final_day_motionBEH = cell2mat(pre_final_day_motionBEH);
    Beh_Index = final_day;
    Nose_Raw = cell2mat(nose_final_raw);
    Nose_Raw_Pre = cell2mat(pre_nose_final_raw);
    Nose = final_day_noseBEH;
    Motion = final_day_motionBEH;
    Beh_Index_Pre = pre_final_day;
    Nose_Pre = pre_final_day_noseBEH;
    Motion_Pre = pre_final_day_motionBEH;
    Odor = vertcat(Odor{:});
    TrialN = repmat((1:trial_cutoff).',length(unique(Odor)),1);
    new_input = table(Beh_Index,Nose,Motion,Beh_Index_Pre,Nose_Pre,Motion_Pre,Nose_Raw,Nose_Raw_Pre,Odor,TrialN);  
    table_now = [table_now;new_input];
    tables_compiled{1,k} = table_now;
end
tables_compiled = tables_compiled.';

%% new final loop to normalize correctly now
all_for_norm = vertcat(tables_compiled{:});
nose_all = all_for_norm.Nose;
motion_all = all_for_norm.Motion;
nose_min = min(nose_all,[],1);
nose_max = max(nose_all,[],1);
motion_max = max(motion_all,[],1);
motion_norm = (motion_all ./ motion_max);
nose_norm = (nose_all+abs(nose_min))./ (nose_max+abs(nose_min));
beh_index = mean(cat(3,nose_norm,motion_norm),3,'omitnan');
for i = 1:size(tables_compiled,1)
    day_now = tables_compiled{i,1};
    %spacing hard coded
    day_now.Beh_Index = beh_index(i*48-48+1:i*48,:);
    tables_compiled{i,1} = day_now;
end

%% save things
save('ProcessedData\tables_compiled_behaviorShifter.mat','tables_compiled');
save('ProcessedData\BEH_respShifted_Trials.mat','BEH_allTrials');
