clear;
% Note before starting; mouse NEC273332 does not have any behavioral data,
% given the current way this script is written, a behavior file is
% expected, so I have supplied a dummy file in the main directory. Didn't
% want to use seperate trace extraction scripts for behavior/no behahvior
% and I haven't updated this code to have behavioral flags in it. Because
% of this, mouse NEC273332 is removed from the behavior tables at the end
% of the code before saving the output files. 

%% Input Parameters

% ***READ THROUGH THIS SECTION FIRST***
% Some alternate methods commented in the code, otherwise just change
% parameters below. All input parameters are saved in a structure termed
% "inputValue" and have descriptions below.

% Key file for sorting trial days, framerates, animal number, etc.
inputValue.KeyTable = readtable('data_sample\Key.csv'); 
% Folder where raw files are; easy to just use the same one as the key file
myFolder = '.\data_sample';

% Settings for smoothing raw data if desired; toggle for choosing to use
% method and set value for number of frames to smooth over
inputValue.SmoothToggle = 0; % 1 to smooth; 0 to not smooth 
inputValue.SmoothWindow = 3; % number of frames to smooth over if toggled on

% Detection settings; cutoffs for DF detection and thresholding optios if
% combining with a z-cutoff; peak finder settings included
% for both combined detection and for whole trace event detection

inputValue.SDcutoff = 2.5; % SD cutoff in DF detection; same for excitation and inhibition as of now
inputValue.Zcutoff_combinedDetect = 1.0; % z score cutoff for combined detection with DF
inputValue.Zcutoff_wholeTrace = 1; % z score cutoff for whole trace peak and activeness detection
inputValue.PeakDistance = 5; % min distance between peaks IN FRAMES; avoids double counting peaks at flat areas, default 5 for 1s with gcamp6s @ 5 fps
inputValue.Prominence = 0.5; % measure of how high peaks stand out (z-scored) from neighbers; also avoids double counting flat areas

% trace details; framerate input, inputValue.timePoints to look at for DF
% calculations; specifications for pre/post windows; bin size for whole
% trial activity analysis 
inputValue.preTrial = 2; % time for pre-trial df measurement in seconds
inputValue.postTrial = 5; % time for post-trial df measurement in seconds 
inputValue.trialTrace_Pre = 15; % time for trace extraction pre odor in seconds 
inputValue.trialTrace_Post = 25; % time for trace extraction post odor in seconds 
inputValue.totalZ_Bins = 300; % length of time IN SECONDS for binning zPeaks across whole trace
inputValue.totalZ_Bins_max = 20; % cap value to z bins to avoid mis-matched sizing; make larger than biggest possible
inputValue.shifter_maxFrames = 50; % total frames to move shifter DF value past OG timepoint
inputValue.shifter_pre = 2; % time for pre-trial on shifter in seconds
inputValue.shifter_post = 5; % time for post-trial on shifter in seconds
inputValue.preValue_shift = 15; % time before timepoints in seconds to calculate pre-window values
inputValue.behaviorTrace_Pre = 25; % time for trace extraction of pre behavior in seconds

% settings for behavioral scoring from DLC files
inputValue.DLC_cutoff = .95; % confidence cutoff for using DLC coord values
inputValue.frate_BEH = 60; % set value for behavior camera framerate; has some jitter in actuality, but this is only used for trial window determination

%% Things to be done globally before loop time

% Initialize empty output tables; grows as things get added with each loop;
% matlab will complain about this, but i don't have a better solution as of yet
OutputTable = cell2table(cell(0,42), 'VariableNames', {'Animal','BehaviorGroup','State','Day','Odor','Abs_CellNumber','CellReg_Index',...
    'Abs_TrialN','Stim_TrialN','DeltaValue_Max','DeltaValue_Mean','DeltaValue_Max_Z','DeltaValue_Min','Responders_EX','Responders_IN',...
    'Responders_CombinedEX','ZPeaksN_byTrial','MotionPost','MotionPre','NoseDisp','MotionCorr','Pre_DeltaValue_Mean','Pre_DeltaValue_Max_Z',...
    'Pre_DeltaValue_Max','Pre_DeltaValue_Min','Pre_Responders_CombinedEX','Pre_Responders_EX','Pre_Responders_IN','Pre_ZPeaksN_byTrial',...
    'Pre_MotionPost','Pre_MotionPre','Pre_NoseDisp','Pre_MotionCorr','DeltaValue_Max_adjustNose','Responders_EX_adjustNose','Responders_CombinedEX_adjustNose',...
    'DeltaValue_MaxShifter','DeltaValue_MaxZShifter','Responders_CombinedEX_Shifter','Pre_DeltaValue_MaxShifter','Pre_DeltaValue_MaxZShifter','Pre_Responders_CombinedEX_Shifter'});
TrialTrace_Table = cell2table(cell(0,11), 'VariableNames', {'Animal','BehaviorGroup','State','Day','Odor','Abs_CellNumber',...
    'CellReg_Index','Abs_TrialN','Stim_TrialN','Ztrace_trial_final','Rawtrace_trial_final'});
Pre_TrialTrace_Table = cell2table(cell(0,11), 'VariableNames', {'Animal','BehaviorGroup','State','Day','Odor','Abs_CellNumber',...
    'CellReg_Index','Abs_TrialN','Stim_TrialN','Pre_Ztrace_trial_final','Pre_Rawtrace_trial_final'});
WholeTrace_Table = cell2table(cell(0,9), 'VariableNames', {'Animal','BehaviorGroup','State','Day',...
    'Abs_CellNumber','CellReg_Index','RecordingLength','Sum_All_PeaksN','Peaks_Bins'});
BEHTrace_Table = cell2table(cell(0,9), 'VariableNames', {'Animal','BehaviorGroup','State','Day','Odor'...
    ,'Abs_TrialN','Stim_TrialN','Motion_trial_final','NoseDisp_trial_final'});
ZTraces = {};
Peaks_Array = {};
Footprints_MasterTable = cell2table(cell(0,7), 'VariableNames',{'Animal','BehaviorGroup','State','Day','Abs_CellNumber','CellReg_Index','Footprint'});
Behavior_Array = {};

% Check to make sure that folder actually exists.  Warn user if it doesn't.
if ~isdir(myFolder)
  errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
  uiwait(warndlg(errorMessage));
  return;
end
% Get a list of all files in the folder with the desired file name pattern.
Deconvolved_Trace_Pattern = fullfile(myFolder, '*DeconTrace.csv'); % Deconvolved traces
Deconvolved_Traces_List = dir(Deconvolved_Trace_Pattern);
Raw_Trace_Pattern = fullfile(myFolder, '*RawTrace.csv'); % Raw traces
Raw_Trace_List = dir(Raw_Trace_Pattern);
Timestamp_Pattern = fullfile(myFolder, '*timeStamps.csv'); % Timestamps
Timestamp_List = dir(Timestamp_Pattern);
Note_Pattern = fullfile(myFolder, '*notes.csv'); % Event points with stamps
Note_List = dir(Note_Pattern);
Index_Pattern = fullfile(myFolder, '*index.csv'); % Deconvolved traces
Index_List = dir(Index_Pattern);
Footprints_Pattern = fullfile(myFolder,'*.mat'); % footprints files
Footprints_List = dir(Footprints_Pattern); 
Behavior_Pattern = fullfile(myFolder, '*Behavior.csv'); % behavior values
Behavior_List = dir(Behavior_Pattern);
BehaviorStamps_Pattern = fullfile(myFolder, '*stampsBeh.csv'); % behavior stamps
BehaviorStamps_List = dir(BehaviorStamps_Pattern);

%% Loop through matching traces/timestamps
% make sure to follow formatting guide here; organized so that files are
% listed in the folder in the correct ordered to match traces with their
% respective timestamps, notes, and index

%typically runs to length(Deconvolved_Traces_List); alter to manual
%numbers if you only want to run a specific set of animals 
for k = 1:length(Deconvolved_Traces_List)
    
  baseDecon_TraceName = Deconvolved_Traces_List(k).name; % base name of file
  fullDecon_TraceName = fullfile(myFolder, baseDecon_TraceName); % file name + relative folder directory
  inputValue.deconvolvedTrace = load(fullDecon_TraceName); % loaded trace
    
  baseRaw_TraceName = Raw_Trace_List(k).name; % base name of file
  fullRaw_TraceName = fullfile(myFolder, baseRaw_TraceName); % file name + relative folder directory
  inputValue.rawTrace = load(fullRaw_TraceName); % loaded file
  
  baseTimestamp_Name = Timestamp_List(k).name; % base name of file
  fullTimestamp_Name = fullfile(myFolder, baseTimestamp_Name); % file name + relative folder directory
  inputValue.timestamp = readtable(fullTimestamp_Name); % loaded file
  
  baseNote_Name = Note_List(k).name; % base name of file
  fullNote_Name = fullfile(myFolder, baseNote_Name); % file name + relative folder directory
  inputValue.notes = readtable(fullNote_Name); % loaded file
  
  baseIndex_Name = Index_List(k).name; % base name of file
  fullIndex_Name = fullfile(myFolder, baseIndex_Name); % file name + relative folder directory
  inputValue.Index = load(fullIndex_Name); % loaded file

  baseFootprints_Name = Footprints_List(k).name; % base name of file
  fullFootprints_Name = fullfile(myFolder, baseFootprints_Name); % file name + relative folder directory
  inputValue.Footprints = load(fullFootprints_Name); % loaded file
  
  baseBehavior_Name = Behavior_List(k).name; % base name of file
  fullBehavior_Name = fullfile(myFolder, baseBehavior_Name); % file name + relative folder directory
  inputValue.Behavior = readmatrix(fullBehavior_Name, 'NumHeaderLines', 3); % loaded file
  inputValue.Behavior = inputValue.Behavior(:,2:end);
  
  baseBehaviorStamps_Name = BehaviorStamps_List(k).name; % base name of file
  fullBehaviorStamps_Name = fullfile(myFolder, baseBehaviorStamps_Name); % file name + relative folder directory
  inputValue.BehaviorStamps = readtable(fullBehaviorStamps_Name); % loaded file

  % have to change/reformat scope timestamps based on scope version number; coded to V4,
  % change the column calls for the vectors if the names be different
  Times_Vector = table2array(inputValue.notes(:,1));
  Stamps_TimeVector = inputValue.timestamp.('TimeStamp_ms_');
  Stamps_FrameVector = inputValue.timestamp.('FrameNumber');
  
% generates timepoints from the notes/timestamps files; adjusts frame value for downsample input 
      for i = 1:length(Times_Vector)
       time_holder = Times_Vector(i);
       [val,idx]=min(abs(Stamps_TimeVector-time_holder));
       inputValue.timePoints(i) = Stamps_FrameVector(idx);
      end
inputValue.downSampleFactor = table2array(inputValue.KeyTable(k,'StampDownsampleFactor')); % used to convert time stamps if using downsampled data      
inputValue.frate = table2array(inputValue.KeyTable(k,'FrameRateFinal')); %frames per second
inputValue.timePoints = round(inputValue.timePoints ./ inputValue.downSampleFactor); %downsample timepoints     

% generates timepoints for behavior file from the notes/timestamps files 
Stamps_TimeVector_BEH = inputValue.BehaviorStamps.('TimeStamp_ms_');
Stamps_FrameVector_BEH = inputValue.BehaviorStamps.('FrameNumber');
      for i = 1:length(Times_Vector)
       time_holder = Times_Vector(i);
       [val,idx]=min(abs(Stamps_TimeVector_BEH-time_holder));
       inputValue.timePoints_BEH(i) = Stamps_FrameVector_BEH(idx);
      end

% Behavior stuff for total file
% eudlidean displacement of all tracked components from frame to frame
    %avg_beh_FR = max(inputValue.BehaviorStamps.('FrameNumber')) / (max(inputValue.BehaviorStamps.('TimeStamp_ms_')) / 1000);
    % find total number of tracked points, initialize empty arrays
    total_n = (size(inputValue.Behavior,2))/3;
    euclid_all = zeros(length(inputValue.Behavior),total_n);
    log_all = zeros(length(inputValue.Behavior),total_n);
    % for each set of x/y points, find euclidean distance from point to
    % point for each frame recorded
    for i = 1:total_n
       current_coords = inputValue.Behavior(:,((3*i)-2):((3*i)-1)); 
       log_all(:,i) = inputValue.Behavior(:,(3*i)) > inputValue.DLC_cutoff;
        for ii = 1:(length(current_coords)-1)
            euc_distance_scope_point = sqrt((current_coords(ii+1,1)-current_coords(ii,1))^2 + ...
                (current_coords(ii+1,2)-current_coords(ii,2))^2 );
            euclid_scope(ii+1) = euc_distance_scope_point; 
        end
        euclid_all(:,i) = euclid_scope;
        clear euclid_scope
    end
    
    % remove any points that don't meet the input confidence cutoff and
    % calculate average across all tracked points, sum across moving window
    % for downsampled version (adjusted to match scope final frate)
    euclid_all(log_all == 0) = NaN;
    average_euclid = mean(euclid_all,2,'omitNaN');
    euclid_down = movsum(average_euclid,(inputValue.frate_BEH/inputValue.frate)); 

% nose displacement from either ear (use left if possible) 
    log_nose_left = sum(inputValue.Behavior(:,[3,6]) > inputValue.DLC_cutoff,2) == 2;
    log_nose_right = sum(inputValue.Behavior(:,[3,9]) > inputValue.DLC_cutoff,2) == 2;
    displacement_nose_left = (inputValue.Behavior(:,2) - inputValue.Behavior(:,5));
    displacement_nose_right = (inputValue.Behavior(:,2) - inputValue.Behavior(:,8));
    displacement_final = zeros(length(inputValue.Behavior),1);
    % using left ear as default; only use right if its the only one, averaging
    % when both there can cause some weird jitter in the signal with it coming
    % and going from in frame
    for i = 1:length(inputValue.Behavior)
       if log_nose_left(i) == 1 && log_nose_right(i) == 1
           displacement_final(i) = displacement_nose_left(i);
       elseif log_nose_left(i) == 1 && log_nose_right(i) == 0
           displacement_final(i) = displacement_nose_left(i);
       elseif log_nose_left(i) == 0 && log_nose_right(i) == 1
           displacement_final(i) = displacement_nose_right(i);
       elseif log_nose_left(i) == 0 && log_nose_right(i) == 0  
           displacement_final(i) = NaN;
       end
    end
    displacement_final = displacement_final .* -1;
    clear log_nose_left log_nose_right
% Zscoring for deconvolved values; input array, sample std dev (not pop), dimension (rows = 2)     
Decon_Z = zscore(inputValue.deconvolvedTrace, 0, 2); 
Raw_Z = zscore(inputValue.rawTrace, 0, 2);
% Smoothing function if used on raw data; input array, dimension (rows = 2), method, window
if inputValue.SmoothToggle == 1
    RawTrace_PostSmooth = smoothdata(inputValue.rawTrace, 2, 'movmean', inputValue.SmoothWindow);
else if inputValue.SmoothToggle == 0
        RawTrace_PostSmooth = inputValue.rawTrace;
    end
end
% subtract min value from all values to shift to avoid negative values  
RawTrace_PostSmooth = RawTrace_PostSmooth - min(RawTrace_PostSmooth, [], 2);

% Peak detection from z-scored data; coded by britgod 

allZPeaks = zeros(size(Decon_Z)); %peak location and size saved to this array
allZPeaks_logical = zeros(size(Decon_Z));
allrawPeaks = zeros(size(Decon_Z));

for ii = 1:size(Decon_Z, 1) 
   [dummy_pks, dummy_locs] = findpeaks(Decon_Z(ii,:),'MinPeakHeight', inputValue.Zcutoff_wholeTrace, 'MinPeakWidth', inputValue.PeakDistance, 'MinPeakProminence', inputValue.Prominence);
   placeholderZ = zeros(1,length(Decon_Z));
        placeholderZ(dummy_locs) = dummy_pks;
   placeholderraw = zeros(1,length(Decon_Z));
        placeholderraw(dummy_locs) = Decon_Z(ii,dummy_locs);
        
   allZPeaks(ii,:) = placeholderZ;
   allZPeaks_logical(ii,:) = (placeholderZ >0);
   allrawPeaks(ii,:) = placeholderraw;
   
   clear dummy_pks dummy_locs placeholder
end

PeakTotal_perCell = sum(allZPeaks_logical,2);
Zabove_threshold = Decon_Z > inputValue.Zcutoff_wholeTrace;

% DF calculation at stimulus inputValue.timePoints for raw signal 
% initializing empty arrays    
preMean_Z = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
postMaxV_Z = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
pre_stdD = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
preMean = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
postMean = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
postMaxV = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
postMinV = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Responders_Zthreshold = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
ZPeaksN_timepoints = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Ztrace_trial = cell(1,size(inputValue.timePoints,2));
Rawtrace_trial = cell(1,size(inputValue.timePoints,2));
Motion_trial = cell(1,size(inputValue.timePoints,2));
NoseDisp_trial = cell(1,size(inputValue.timePoints,2));
preMotion = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
postMotion = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
postNose = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
postNose_IDX = zeros(1,size(inputValue.timePoints,2));

% check for NaN in timepoints (dropped trials); fill those as NaN, then
% actually pull real values from trials that were not dropped
    for ii = 1:size(inputValue.timePoints,2)
        if inputValue.timePoints(ii) == 0
            preMean_Z(:,ii) =  NaN(size(inputValue.deconvolvedTrace,1),1);
            postMaxV_Z(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            pre_stdD(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            preMean(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            postMean(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            postMaxV(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            postMinV(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            Responders_Zthreshold(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            ZPeaksN_timepoints(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            Ztrace_trial{ii} = NaN(size(inputValue.deconvolvedTrace,1),((inputValue.trialTrace_Pre*inputValue.frate)+(inputValue.trialTrace_Post*inputValue.frate)));
            Rawtrace_trial{ii} = NaN(size(inputValue.deconvolvedTrace,1),((inputValue.trialTrace_Pre*inputValue.frate)+(inputValue.trialTrace_Post*inputValue.frate)));
            Motion_trial{ii} = NaN(size(inputValue.deconvolvedTrace,1),((inputValue.behaviorTrace_Pre*inputValue.frate)+(inputValue.trialTrace_Post*inputValue.frate)));
            NoseDisp_trial{ii} = NaN(size(inputValue.deconvolvedTrace,1),((inputValue.behaviorTrace_Pre*inputValue.frate)+(inputValue.trialTrace_Post*inputValue.frate)));
            preMotion(:,ii) =  NaN(size(inputValue.deconvolvedTrace,1),1);
            postMotion(:,ii) =  NaN(size(inputValue.deconvolvedTrace,1),1);
            postNose(:,ii) =  NaN(size(inputValue.deconvolvedTrace,1),1);
        else
        % first group is taking raw or ztrace values from timepoints and
        % splitting to new arrays; trial measures include pre window while
        Ztrace_trial_holder = Decon_Z(:,(inputValue.timePoints(ii)-(inputValue.frate * inputValue.trialTrace_Pre)):(inputValue.timePoints(ii) + ((inputValue.frate * inputValue.trialTrace_Post))-1));
        Ztrace_trial{ii} = Ztrace_trial_holder;
        Rawtrace_trial_holder = RawTrace_PostSmooth(:,(inputValue.timePoints(ii)-(inputValue.frate * inputValue.trialTrace_Pre)):(inputValue.timePoints(ii) + ((inputValue.frate * inputValue.trialTrace_Post))-1));
        Rawtrace_trial{ii} = Rawtrace_trial_holder;     
        Motion_trial_holder = average_euclid((inputValue.timePoints_BEH(ii)-(inputValue.frate_BEH * inputValue.behaviorTrace_Pre)):(inputValue.timePoints_BEH(ii) + ((inputValue.frate_BEH * inputValue.trialTrace_Post))-1));
        Motion_trial{ii} = Motion_trial_holder.';  
        NoseDisp_trial_holder = displacement_final((inputValue.timePoints_BEH(ii)-(inputValue.frate_BEH * inputValue.behaviorTrace_Pre)):(inputValue.timePoints_BEH(ii) + ((inputValue.frate_BEH * inputValue.trialTrace_Post))-1));
        NoseDisp_trial{ii} = NoseDisp_trial_holder.'; 
        
        % second group is calculating values of interest around timepoints;
        % includes pre/post means, max's, responders, etc.
        pre_stdD(:,ii) = std(RawTrace_PostSmooth(:,((inputValue.timePoints(ii)-(inputValue.preTrial * inputValue.frate))):(inputValue.timePoints(ii)-1)), 0, 2);
        preMean(:,ii) = mean(RawTrace_PostSmooth(:,((inputValue.timePoints(ii)-(inputValue.preTrial * inputValue.frate))):(inputValue.timePoints(ii)-1)), 2);
        preMean_Z(:,ii) = mean(Raw_Z(:,((inputValue.timePoints(ii)-(inputValue.preTrial * inputValue.frate))):(inputValue.timePoints(ii)-1)), 2);
        postMean(:,ii) = mean(RawTrace_PostSmooth(:,(inputValue.timePoints(ii)):((inputValue.timePoints(ii)-1)+(inputValue.postTrial*inputValue.frate))), 2);
        [postMaxHolder,postMaxIndex] = max(RawTrace_PostSmooth(:,(inputValue.timePoints(ii)):((inputValue.timePoints(ii)-1)+(inputValue.postTrial*inputValue.frate))), [], 2);
        postMaxV(:,ii) = postMaxHolder;   
        [postMaxZHolder,postMaxZIndex] = max(Raw_Z(:,(inputValue.timePoints(ii)):((inputValue.timePoints(ii)-1)+(inputValue.postTrial*inputValue.frate))), [], 2);
        postMaxV_Z(:,ii) = postMaxZHolder; 
        postMinHolder = min(RawTrace_PostSmooth(:,(inputValue.timePoints(ii)):((inputValue.timePoints(ii)-1)+(inputValue.postTrial*inputValue.frate))), [], 2);
        postMinV(:,ii) = postMinHolder;  
        zMaxHolder = max(Decon_Z(:,(inputValue.timePoints(ii)):((inputValue.timePoints(ii)-1)+(inputValue.postTrial*inputValue.frate))), [], 2);
        Responders_Zthreshold(:,ii) = zMaxHolder; 
        ZPeaksN_timepoints(:,ii) = sum(allZPeaks_logical(:,(inputValue.timePoints(ii)):((inputValue.timePoints(ii)-1)+(inputValue.postTrial*inputValue.frate))),2);
        %DLC behavior things; nose displacement is an average +/- 2 frames
        %on either side of the displacment peak in the post trial window
        preMotion(:,ii) = repmat(mean(average_euclid((inputValue.timePoints_BEH(ii)-(inputValue.preTrial * inputValue.frate_BEH)):(inputValue.timePoints_BEH(ii)-1))),size(Decon_Z,1),1);
        postMotion(:,ii) = repmat(mean(average_euclid(inputValue.timePoints_BEH(ii):((inputValue.timePoints_BEH(ii)-1)+(inputValue.postTrial*inputValue.frate_BEH)))),size(Decon_Z,1),1);
        [postNose_max,postNose_max_idx] = max(displacement_final(inputValue.timePoints_BEH(ii):((inputValue.timePoints_BEH(ii)-1)+(inputValue.postTrial*inputValue.frate_BEH))));
        postNose(:,ii) = mean(displacement_final((inputValue.timePoints_BEH(ii)+postNose_max_idx-3):(inputValue.timePoints_BEH(ii)+postNose_max_idx+1)),'omitNaN');
        postNose_IDX(:,ii) = postNose_max_idx; 
        end
    end

% new set of timepoints for shifting delta window to time of nose
% raising minus 3 frames as a small buffer to the behavior point

inputValue.timePoints_BEH_New = (inputValue.timePoints_BEH + postNose_IDX);

      for q = 1:length(Times_Vector)
       time_holder = inputValue.timePoints_BEH_New(q);
       [val,idx]=min(abs(Stamps_FrameVector_BEH-time_holder));
       inputValue.times_BEH_new(q) = Stamps_TimeVector_BEH(idx);
      end

      for r = 1:length(Times_Vector)
       time_holder = inputValue.times_BEH_new(r);
       [val,idx]=min(abs(Stamps_TimeVector-time_holder));
       inputValue.timePoints_BEH_adjustedNose(r) = Stamps_FrameVector(idx);
      end

% downsample new adjusted behavior timepoints to match scope frames 
inputValue.timePoints_BEH_adjustedNose = round(inputValue.timePoints_BEH_adjustedNose ./ inputValue.downSampleFactor);

% create extra empty arrays and pull stuff of interest from any adjusted timepoints 
preMean_adjustNose = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
postMaxV_adjustNose = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
pre_stdD_adjustNose = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
% check for NaN in timepoints (dropped trials); fill those as NaN, then
% actually pull real values from trials that were not dropped
    for ii = 1:size(inputValue.timePoints,2)
        if inputValue.timePoints(ii) == 0
            preMean_adjustNose(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            postMaxV_adjustNose(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            pre_stdD_adjustNose(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
        else
        pre_stdD_adjustNose(:,ii) = std(RawTrace_PostSmooth(:,((inputValue.timePoints_BEH_adjustedNose(ii)-(inputValue.preTrial * inputValue.frate))):(inputValue.timePoints_BEH_adjustedNose(ii)-1)), 0, 2);
        [postMaxHolder_adjustNose,postMaxIndex_adjustNose] = max(RawTrace_PostSmooth(:,(inputValue.timePoints_BEH_adjustedNose(ii)):((inputValue.timePoints_BEH_adjustedNose(ii)-1)+(inputValue.postTrial*inputValue.frate))), [], 2);
        postMaxV_adjustNose(:,ii) = postMaxHolder_adjustNose;
        preMean_adjustNose(:,ii) = mean(RawTrace_PostSmooth(:,((inputValue.timePoints_BEH_adjustedNose(ii)-(inputValue.preTrial * inputValue.frate))):(inputValue.timePoints_BEH_adjustedNose(ii)-1)), 2);
        end
    end


% calculate desired outputs
    deltaV_mean = postMean - preMean;
    deltaV_max_Z = (postMaxV_Z - preMean_Z);
    deltaV_max = ((postMaxV - preMean));
    deltaV_min = ((preMean - postMinV));
    delta_detect_EX = ((postMaxV - preMean) ./ (pre_stdD) > inputValue.SDcutoff);
    delta_detect_IN = ((preMean - postMinV) ./ (pre_stdD) > inputValue.SDcutoff);
    combined_detectEX = (delta_detect_EX .* (Responders_Zthreshold > inputValue.Zcutoff_combinedDetect));
    post_motion_corr = repmat((corr(postMotion(1,:).',postMaxV.','rows','complete')).',1,size(inputValue.timePoints,2));
    deltaV_max_adjustNose = (postMaxV_adjustNose-preMean);
    delta_detect_EX_adjustNose = ((postMaxV_adjustNose - preMean_adjustNose) ./ (pre_stdD_adjustNose) > inputValue.SDcutoff);
    combined_detect_EX_adjustNose = (delta_detect_EX_adjustNose .* (Responders_Zthreshold > inputValue.Zcutoff_combinedDetect));

% DF calculation at time before stimulus inputValue.timePoints; 
% post-measure window size used to determine how long pre the normal 
% timepoint to set the new, pre-timepoints 
Pre_preMean_Z = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre_postMaxV_Z = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre__stdD = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre_Mean = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre_postMean = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre_postMaxV = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre_postMinV = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre_Responders_Zthreshold = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre_ZPeaksN_timepoints = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre_Ztrace_trial = cell(1,size(inputValue.timePoints,2));
Pre_Rawtrace_trial = cell(1,size(inputValue.timePoints,2));
Pre_preMotion = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre_postMotion = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));
Pre_postNose = zeros(size(Decon_Z,1),size(inputValue.timePoints,2));

% check for NaN in timepoints (dropped trials); fill those as NaN, then
% actually pull real values from trials that were not dropped
    for ii = 1:size(inputValue.timePoints,2)
        if inputValue.timePoints(ii) == 0
            Pre_preMean_Z(:,ii) =  NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre_postMaxV_Z(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre__stdD(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre_Mean(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre_postMean(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre_postMaxV(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre_postMinV(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre_Responders_Zthreshold(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre_ZPeaksN_timepoints(:,ii) = NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre_Ztrace_trial{ii} = NaN(size(inputValue.deconvolvedTrace,1),((inputValue.trialTrace_Pre*inputValue.frate)+(inputValue.trialTrace_Post*inputValue.frate)));
            Pre_Rawtrace_trial{ii} = NaN(size(inputValue.deconvolvedTrace,1),((inputValue.trialTrace_Pre*inputValue.frate)+(inputValue.trialTrace_Post*inputValue.frate)));
            Pre_preMotion(:,ii) =  NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre_postMotion(:,ii) =  NaN(size(inputValue.deconvolvedTrace,1),1);
            Pre_postNose(:,ii) =  NaN(size(inputValue.deconvolvedTrace,1),1);
        else
        % first group is taking raw or ztrace values from timepoints and
        % splitting to new arrays; trial measures include pre window while
        % behavior is only the freezing window
        Ztrace_trial_holder = Decon_Z(:,(inputValue.timePoints(ii)-(inputValue.frate * inputValue.trialTrace_Pre)-(inputValue.frate*inputValue.postTrial)):(inputValue.timePoints(ii) + ((inputValue.frate * inputValue.trialTrace_Post))-1-(inputValue.frate*inputValue.postTrial)));
        Pre_Ztrace_trial{ii} = Ztrace_trial_holder;
        Rawtrace_trial_holder = RawTrace_PostSmooth(:,(inputValue.timePoints(ii)-(inputValue.frate * inputValue.trialTrace_Pre)-(inputValue.frate*inputValue.postTrial)):(inputValue.timePoints(ii) + ((inputValue.frate * inputValue.trialTrace_Post))-1-(inputValue.frate*inputValue.postTrial)));
        Pre_Rawtrace_trial{ii} = Rawtrace_trial_holder;     
        
        % second group is calculating values of interest around timepoints;
        % includes pre/post means, max's, responders, etc.
        timepoints_adjusted = inputValue.timePoints(ii) - (inputValue.preValue_shift * inputValue.frate);
        timepoints_adjustedBEH = inputValue.timePoints_BEH(ii) - (inputValue.preValue_shift * inputValue.frate_BEH);
        Pre__stdD(:,ii) = std(RawTrace_PostSmooth(:,((timepoints_adjusted-(inputValue.preTrial * inputValue.frate)-(inputValue.frate*inputValue.postTrial))):(timepoints_adjusted-1-(inputValue.frate*inputValue.postTrial))), 0, 2);
        Pre_Mean(:,ii) = mean(RawTrace_PostSmooth(:,((timepoints_adjusted-(inputValue.preTrial * inputValue.frate)-(inputValue.frate*inputValue.postTrial))):(timepoints_adjusted-1-(inputValue.frate*inputValue.postTrial))), 2);
        Pre_preMean_Z(:,ii) = mean(Raw_Z(:,((timepoints_adjusted-(inputValue.preTrial * inputValue.frate)-(inputValue.frate*inputValue.postTrial))):(timepoints_adjusted-1-(inputValue.frate*inputValue.postTrial))), 2);
        Pre_postMean(:,ii) = mean(RawTrace_PostSmooth(:,(timepoints_adjusted-(inputValue.frate*inputValue.postTrial)):((timepoints_adjusted-1)+(inputValue.postTrial*inputValue.frate)-(inputValue.frate*inputValue.postTrial))), 2);
        [postMaxHolder,postMaxIndex] = max(RawTrace_PostSmooth(:,(timepoints_adjusted-(inputValue.frate*inputValue.postTrial)):((timepoints_adjusted-1)+(inputValue.postTrial*inputValue.frate)-(inputValue.frate*inputValue.postTrial))), [], 2);
        Pre_postMaxV(:,ii) = postMaxHolder;   
        [postMaxZHolder,postMaxZIndex] = max(Raw_Z(:,(timepoints_adjusted-(inputValue.frate*inputValue.postTrial)):((timepoints_adjusted-1)+(inputValue.postTrial*inputValue.frate)-(inputValue.frate*inputValue.postTrial))), [], 2);
        Pre_postMaxV_Z(:,ii) = postMaxZHolder; 
        postMinHolder = min(RawTrace_PostSmooth(:,(timepoints_adjusted-(inputValue.frate*inputValue.postTrial)):((timepoints_adjusted-1)+(inputValue.postTrial*inputValue.frate)-(inputValue.frate*inputValue.postTrial))), [], 2);
        Pre_postMinV(:,ii) = postMinHolder;  
        zMaxHolder = max(Decon_Z(:,(timepoints_adjusted-(inputValue.frate*inputValue.postTrial)):((timepoints_adjusted-1)+(inputValue.postTrial*inputValue.frate)-(inputValue.frate*inputValue.postTrial))), [], 2);
        Pre_Responders_Zthreshold(:,ii) = zMaxHolder; 
        Pre_ZPeaksN_timepoints(:,ii) = sum(allZPeaks_logical(:,(timepoints_adjusted-(inputValue.frate*inputValue.postTrial)):((timepoints_adjusted-1)+(inputValue.postTrial*inputValue.frate)-(inputValue.frate*inputValue.postTrial))),2);
        %DLC behavior things; nose displacement is an average +/- 2 frames
        %on either side of the displacment peak in the post trial window
        Pre_preMotion(:,ii) = repmat(mean(average_euclid((timepoints_adjustedBEH-(inputValue.preTrial * inputValue.frate_BEH)-(inputValue.frate_BEH*inputValue.postTrial)):(timepoints_adjustedBEH-1-(inputValue.frate_BEH*inputValue.postTrial)))),size(Decon_Z,1),1);
        Pre_postMotion(:,ii) = repmat(mean(average_euclid((timepoints_adjustedBEH-(inputValue.frate_BEH*inputValue.postTrial)):((timepoints_adjustedBEH-1)+(inputValue.postTrial*inputValue.frate_BEH)-(inputValue.frate_BEH*inputValue.postTrial)))),size(Decon_Z,1),1);
        [postNose_max,postNose_max_idx] = max(displacement_final((timepoints_adjustedBEH-(inputValue.frate_BEH*inputValue.postTrial)):((timepoints_adjustedBEH-1)+(inputValue.postTrial*inputValue.frate_BEH)-(inputValue.frate_BEH*inputValue.postTrial))));
        Pre_postNose(:,ii) = mean(displacement_final((timepoints_adjustedBEH+postNose_max_idx-3-(inputValue.frate_BEH*inputValue.postTrial)):(timepoints_adjustedBEH+postNose_max_idx+1-(inputValue.frate_BEH*inputValue.postTrial))),'omitNaN');
        end
    end

% calculate stuff you want as an output
    Pre_deltaV_mean = Pre_postMean - Pre_Mean;
    Pre_deltaV_max_Z = (Pre_postMaxV_Z - Pre_preMean_Z);
    Pre_deltaV_max = ((Pre_postMaxV - Pre_Mean));
    Pre_deltaV_min = ((Pre_Mean - Pre_postMinV));
    Pre_delta_detect_EX = ((Pre_postMaxV - Pre_Mean) ./ (Pre__stdD) > inputValue.SDcutoff);
    Pre_delta_detect_IN = ((Pre_Mean - Pre_postMinV) ./ (Pre__stdD) > inputValue.SDcutoff);
    Pre_combined_detectEX = (Pre_delta_detect_EX .* (Pre_Responders_Zthreshold > inputValue.Zcutoff_combinedDetect));
    Pre_post_motion_corr = repmat((corr(Pre_postMotion(1,:).',Pre_postMaxV.','rows','complete')).',1,size(inputValue.timePoints,2));

 %delta shifter code; shifting along the response window x2 and calculate new deltas
 %based on the shift across all possible points, generates a larger cell
 %matrix encompassing all possible points
 postMaxV_shifter = cell(1,size(inputValue.timePoints,2));
 preMean_shifter = cell(1,size(inputValue.timePoints,2));
 postMaxV_Delta_shifter = cell(1,size(inputValue.timePoints,2));    
 postMaxV_CombinedResponders_shifter = cell(1,size(inputValue.timePoints,2));
 deltaZ_shifter = cell(1,size(inputValue.timePoints,2));
 Pre_postMaxV_shifter = cell(1,size(inputValue.timePoints,2));
 Pre_postMaxV_CombinedResponders_shifter = cell(1,size(inputValue.timePoints,2));
 Pre_deltaZ_shifter = cell(1,size(inputValue.timePoints,2));
 wPre = inputValue.shifter_pre * inputValue.frate;
 wPost = inputValue.shifter_post * inputValue.frate;    
    for ii = 1:size(inputValue.timePoints,2)
        if inputValue.timePoints(ii) == 0
             dummy = NaN(size(Decon_Z,1),inputValue.shifter_maxFrames);
             postMaxV_shifter{1,ii} = dummy;
             preMean_shifter{1,ii} = dummy;
             postMaxV_Delta_shifter{1,ii} = dummy; 
             postMaxV_CombinedResponders_shifter{1,ii} = dummy;
             deltaZ_shifter{1,ii} = dummy;
             Pre_postMaxV_shifter{1,ii} = dummy;
             Pre_postMaxV_CombinedResponders_shifter{1,ii} = dummy;
             Pre_deltaZ_shifter{1,ii} = dummy;
        else
            postMaxV_shifter_now = zeros(size(Decon_Z,1),inputValue.shifter_maxFrames);
            preMean_shifter_now = zeros(size(Decon_Z,1),inputValue.shifter_maxFrames);
            preStd_shifter_now = zeros(size(Decon_Z,1),inputValue.shifter_maxFrames);
            Zmax_shifter_holder = zeros(size(Decon_Z,1),inputValue.shifter_maxFrames);
            ZpreMean_shifter_holder = zeros(size(Decon_Z,1),inputValue.shifter_maxFrames);
            Pre_std_shifter_holder = zeros(size(Decon_Z,1),inputValue.shifter_maxFrames);
            Pre_Mean_shifter_holder = zeros(size(Decon_Z,1),inputValue.shifter_maxFrames);
            Pre_Max_shifter_holder = zeros(size(Decon_Z,1),inputValue.shifter_maxFrames);
            Pre_Zmax_shifter_holder = zeros(size(Decon_Z,1),inputValue.shifter_maxFrames);
            Pre_ZpreMean_shifter_holder = zeros(size(Decon_Z,1),inputValue.shifter_maxFrames);
            for q = (1:inputValue.shifter_maxFrames)-1
                postMaxV_shifter_now(:,(q+1)) = max(RawTrace_PostSmooth(:,(inputValue.timePoints(ii)+q):(inputValue.timePoints(ii)+q-1+wPost)), [], 2);
                preMean_shifter_now(:,(q+1)) = mean(RawTrace_PostSmooth(:,(inputValue.timePoints(ii)+q-wPre):(inputValue.timePoints(ii)+q-1)), 2);
                preStd_shifter_now(:,(q+1)) = std(RawTrace_PostSmooth(:,(inputValue.timePoints(ii)+q-wPre):(inputValue.timePoints(ii)+q-1)), 0, 2);
                Zmax_shifter_holder(:,(q+1)) = max(Decon_Z(:,(inputValue.timePoints(ii)+q):(inputValue.timePoints(ii)+q-1+wPost)), [], 2);
                ZpreMean_shifter_holder(:,(q+1)) = mean(Decon_Z(:,(inputValue.timePoints(ii)+q-wPost-wPre):(inputValue.timePoints(ii)+q-wPost-1)), 2);
                timepoints_adjusted = inputValue.timePoints(ii) - (inputValue.preValue_shift * inputValue.frate);
                Pre_std_shifter_holder(:,(q+1)) = std(RawTrace_PostSmooth(:,(timepoints_adjusted+q-wPost-wPre-inputValue.shifter_maxFrames):(timepoints_adjusted+q-wPost-inputValue.shifter_maxFrames-1)), 0, 2);
                Pre_Mean_shifter_holder(:,(q+1)) = mean(RawTrace_PostSmooth(:,(timepoints_adjusted+q-wPost-wPre-inputValue.shifter_maxFrames):(timepoints_adjusted+q-wPost-inputValue.shifter_maxFrames-1)), 2);
                Pre_Max_shifter_holder(:,(q+1)) = max(RawTrace_PostSmooth(:,(timepoints_adjusted+q-wPost-inputValue.shifter_maxFrames):(timepoints_adjusted+q-1-inputValue.shifter_maxFrames)), [], 2);
                Pre_Zmax_shifter_holder(:,(q+1)) = max(Decon_Z(:,(timepoints_adjusted+q-wPost-inputValue.shifter_maxFrames):(timepoints_adjusted+q-1-inputValue.shifter_maxFrames)), [], 2);
                Pre_ZpreMean_shifter_holder(:,(q+1)) = mean(Decon_Z(:,(timepoints_adjusted+q-wPost-wPre-inputValue.shifter_maxFrames):(timepoints_adjusted+q-wPost-inputValue.shifter_maxFrames-1)), 2);
            end
            postMaxV_CombinedResponders_shifter{1,ii} = (((postMaxV_shifter_now - preMean_shifter_now) ./ preStd_shifter_now) >...
                inputValue.SDcutoff) & (Zmax_shifter_holder > inputValue.Zcutoff_combinedDetect);    
            postMaxV_Delta_shifter{1,ii} = (postMaxV_shifter_now - preMean_shifter_now);
            postMaxV_shifter{1,ii} = postMaxV_shifter_now;
            preMean_shifter{1,ii} = preMean_shifter_now;
            deltaZ_shifter{1,ii} = (Zmax_shifter_holder - ZpreMean_shifter_holder);
            Pre_postMaxV_shifter{1,ii} = (Pre_Max_shifter_holder - Pre_Mean_shifter_holder);
            Pre_postMaxV_CombinedResponders_shifter{1,ii} = (((Pre_Max_shifter_holder - Pre_Mean_shifter_holder) ./ Pre_std_shifter_holder) >...
                inputValue.SDcutoff) & (Pre_Zmax_shifter_holder > inputValue.Zcutoff_combinedDetect);
            Pre_deltaZ_shifter{1,ii} = (Pre_Zmax_shifter_holder - Pre_ZpreMean_shifter_holder);
        end
    end

 % pull things that go into table for absolute cell #, day, behavior group, etc.
 Animal = cellstr(repmat(char(table2array(inputValue.KeyTable(k,'AnimalNumber'))),size(deltaV_max,1),1));  
 Day = repmat(table2array(inputValue.KeyTable(k,'Day')),size(deltaV_max,1),1);
 Abs_CellNumber = transpose(1:size(deltaV_max,1));
 BehaviorGroup = cellstr(repmat(char(table2array(inputValue.KeyTable(k,'BehaviorGroup'))),size(deltaV_max,1),1));
 State = cellstr(repmat(char(table2array(inputValue.KeyTable(k,'State'))),size(deltaV_max,1),1)); 
 Footprint = num2cell(inputValue.Footprints.spatial_footprints,[2 3]);
 
 % cell reg sometimes leaves out cells that
 % were included in the initial spatial footprints from the final index
 % added this line in to resort the cell-index for the
 % final table and to then include a zero value for any cell that was in
 % the original footprints for a day but wasn't included in the final
 % output 
 CellReg_Index = zeros(size(inputValue.deconvolvedTrace,1),1);
 for i = 1:size(inputValue.deconvolvedTrace,1)    
     if find(inputValue.Index == i) > 0 % if the index exists, put the right number in
     CellReg_Index(i,:) = find(inputValue.Index == i);
     else % otherwise, drop a zero in to indicate it wasn't included 
     CellReg_Index(i,:) = 0; 
     end
 end
 
 % pull output values and odors for each trial, add to table with above
 % indentifiers for each cell
for i = 1:size(deltaV_max,2)
    
    Odor = cellstr(repmat(char(table2array(inputValue.notes(i,2))),size(deltaV_max,1),1));
    Abs_TrialN = repmat(i,size(deltaV_max,1),1);
    
    % get absolute trial number; truncate to current
    % trial being looked at, then count string appearence of that odor
    counter_trunc = table2array(inputValue.notes(1:i,2));
    Stim_TrialN = repmat(sum(count(counter_trunc,table2array(inputValue.notes(i,2)))),size(deltaV_max,1),1);
    
    % add numbers into the table; fill gaps with NaN; uses
    % zeros for trace delta values (as those are always a number that isn't
    % zero. For logical indices, not converting to NaN. Max trial length
    % input globally at the start of the script determines the number of
    % columns for each table, so make sure thats right. To_add number
    % pulled solely from the delta frame as it should match the others. 
    
    DeltaValue_MaxShifter = postMaxV_Delta_shifter{1,i};
    DeltaValue_MaxZShifter = deltaZ_shifter{1,i};
    Responders_CombinedEX_Shifter = postMaxV_CombinedResponders_shifter{1,i};
    DeltaValue_Mean = deltaV_mean(:,i);
    DeltaValue_Max_Z = deltaV_max_Z(:,i);
    DeltaValue_Max = deltaV_max(:,i);
    DeltaValue_Min = deltaV_min(:,i);
    Responders_CombinedEX = combined_detectEX(:,i);    
    Responders_EX = delta_detect_EX(:,i);  
    Responders_IN = delta_detect_IN(:,i);
    ZPeaksN_byTrial = ZPeaksN_timepoints(:,i);
    MotionPost = postMotion(:,i);
    MotionPre = preMotion(:,i);
    NoseDisp = postNose(:,i);
    MotionCorr = post_motion_corr(:,i);
    DeltaValue_Max_adjustNose = deltaV_max_adjustNose(:,i);
    Responders_EX_adjustNose = delta_detect_EX_adjustNose(:,i);
    Responders_CombinedEX_adjustNose = combined_detect_EX_adjustNose(:,i);


    Pre_DeltaValue_MaxShifter = Pre_postMaxV_shifter{1,i};
    Pre_DeltaValue_MaxZShifter = Pre_deltaZ_shifter{1,i};
    Pre_Responders_CombinedEX_Shifter = Pre_postMaxV_CombinedResponders_shifter{1,i};
    Pre_DeltaValue_Mean = Pre_deltaV_mean(:,i);
    Pre_DeltaValue_Max_Z = Pre_deltaV_max_Z(:,i);
    Pre_DeltaValue_Max = Pre_deltaV_max(:,i);
    Pre_DeltaValue_Min = Pre_deltaV_min(:,i);
    Pre_Responders_CombinedEX = Pre_combined_detectEX(:,i);    
    Pre_Responders_EX = Pre_delta_detect_EX(:,i);  
    Pre_Responders_IN = Pre_delta_detect_IN(:,i);
    Pre_ZPeaksN_byTrial = Pre_ZPeaksN_timepoints(:,i);
    Pre_MotionPost = Pre_postMotion(:,i);
    Pre_MotionPre = Pre_preMotion(:,i);
    Pre_NoseDisp = Pre_postNose(:,i);
    Pre_MotionCorr = Pre_post_motion_corr(:,i);

    
    %combine outputs, then append to final table/arrays
    newTableInput = table(Animal,BehaviorGroup,State,Day,Odor,Abs_CellNumber,CellReg_Index,Abs_TrialN,Stim_TrialN,...
        DeltaValue_Max,DeltaValue_Mean,DeltaValue_Max_Z,DeltaValue_Min,Responders_EX,Responders_IN,Responders_CombinedEX,...
        ZPeaksN_byTrial,MotionPost,MotionPre,NoseDisp,MotionCorr,Pre_DeltaValue_Mean,Pre_DeltaValue_Max_Z,Pre_DeltaValue_Max,...
        Pre_DeltaValue_Min,Pre_Responders_CombinedEX,Pre_Responders_EX,Pre_Responders_IN,Pre_ZPeaksN_byTrial,Pre_MotionPost,...
        Pre_MotionPre,Pre_NoseDisp,Pre_MotionCorr,DeltaValue_Max_adjustNose,Responders_EX_adjustNose,Responders_CombinedEX_adjustNose,...
        DeltaValue_MaxShifter,DeltaValue_MaxZShifter,Responders_CombinedEX_Shifter,Pre_DeltaValue_MaxShifter,Pre_DeltaValue_MaxZShifter,...
        Pre_Responders_CombinedEX_Shifter);
    OutputTable = [OutputTable;newTableInput];
    
    Ztrace_trial_final = num2cell(Ztrace_trial{i},2);
    Rawtrace_trial_final = num2cell(Rawtrace_trial{i},2);
    Pre_Ztrace_trial_final = num2cell(Pre_Ztrace_trial{i},2);
    Pre_Rawtrace_trial_final = num2cell(Pre_Rawtrace_trial{i},2);    
    
    % output for trial traces
    new_trialTable_input = table(Animal,BehaviorGroup,State,Day,Odor,Abs_CellNumber,...
        CellReg_Index,Abs_TrialN,Stim_TrialN,Ztrace_trial_final,Rawtrace_trial_final);
    TrialTrace_Table = [TrialTrace_Table;new_trialTable_input];

    Pre_new_trialTable_input = table(Animal,BehaviorGroup,State,Day,Odor,Abs_CellNumber,...
    CellReg_Index,Abs_TrialN,Stim_TrialN,Pre_Ztrace_trial_final,Pre_Rawtrace_trial_final);
    Pre_TrialTrace_Table = [Pre_TrialTrace_Table;Pre_new_trialTable_input];
    
    % wipe cell arrays from each loop, will otherwise keep adding on to
    % prior entries
    clear ZTrace_trial_final Rawtrace_trial_final Pre_Ztrace_trial_final...
        Pre_Rawtrace_trial_final 
end

totalPeak_Bins = floor(size(allZPeaks,2) / (inputValue.totalZ_Bins * inputValue.frate));

for i = 1:totalPeak_Bins
   
    peaks_now = allZPeaks_logical(:,(i*inputValue.totalZ_Bins*inputValue.frate-...
        inputValue.totalZ_Bins*inputValue.frate + 1):...
        (i*inputValue.totalZ_Bins*inputValue.frate));
    sum_peaks_now = sum(peaks_now,2);
    Peaks_Bins{i} = sum_peaks_now;
end

% output of info relevant to the total traces
Peaks_Bins = cell2mat(Peaks_Bins);
Peaks_Bins(:,end+1:inputValue.totalZ_Bins_max) = NaN; % add to backfill for differing recording lengths
RecordingLength = repmat(length(Decon_Z),size(allrawPeaks,1),1);
Sum_All_PeaksN = sum(allZPeaks_logical,2);
new_WholeTableInput = table(Animal,BehaviorGroup,State,Day,Abs_CellNumber,CellReg_Index,RecordingLength,Sum_All_PeaksN,Peaks_Bins);
WholeTrace_Table = [WholeTrace_Table;new_WholeTableInput];

% ouput of info relevant to footprints
new_FootprintsInput = table(Animal,BehaviorGroup,State,Day,Abs_CellNumber,CellReg_Index,Footprint);
Footprints_MasterTable = [Footprints_MasterTable;new_FootprintsInput];

% behavior table input; after above loop for trial info so i can re-use
% table info; don't put before any of the other ones as lable structure is
% different for this table 
Motion_trial_final = Motion_trial.';
NoseDisp_trial_final = NoseDisp_trial.';
Animal = repmat(Animal(1),size(inputValue.timePoints,2),1);    
BehaviorGroup = repmat(BehaviorGroup(1),size(inputValue.timePoints,2),1);
State = repmat(State(1),size(inputValue.timePoints,2),1);  
Odor = table2cell(inputValue.notes(:,2));  
Day = repmat(Day(1),size(inputValue.timePoints,2),1);
Abs_TrialN = (1:size(inputValue.timePoints,2)).';
Stim_TrialN = zeros(size(inputValue.timePoints,2),1);
for i = 1:size(deltaV_max,2)
    counter_trunc = table2array(inputValue.notes(1:i,2));
    Stim_TrialN(i) = sum(count(counter_trunc,table2array(inputValue.notes(i,2))));
end
new_BEHinput = table(Animal,BehaviorGroup,State,Day,Odor,Abs_TrialN,Stim_TrialN,...
    Motion_trial_final,NoseDisp_trial_final);
BEHTrace_Table = [BEHTrace_Table;new_BEHinput];

clear Motion_trial_final NoseDisp_trial_final

% wipe cell arrays from each loop
clear Ztrace_Behavior Ztrace_trial Rawtrace_trial Rawtrace_Behavior Peaks_Bins Pre_Ztrace_trial_final Pre_Rawtrace_trial_final
% wipe timepoints input to avoid leftovers from long files
inputValue.timePoints = [];
inputValue.timePoints_BEH = [];
inputValue.timePoints_BEH_New = [];
inputValue.timePoints_BEH_adjustedNose = [];
inputValue.times_BEH_new = [];

% output for behavior

MotionIdx = average_euclid;
NoseDisp = displacement_final;
new_behavior_input = {MotionIdx,NoseDisp;};
Behavior_Array = [Behavior_Array;new_behavior_input];

% ZTrace Table; saved in order of trial appearance in list 
Trace = Decon_Z;
new_ZTrace = {Trace};
ZTraces = [ZTraces;new_ZTrace];

Peaks = allZPeaks; 
new_Peaks = {allZPeaks};
Peaks_Array = [Peaks_Array;new_Peaks];

end

%% any manual trimming post-running

% remove animal that doesn't actual have behavioral data from those arrays
BEHTrace_Table(strcmp(BEHTrace_Table.Animal,'NEC273332')==true,:) = [];
Behavior_Array(1:6,:) = [];


%% save final output tables/arrays
save('InputParameters.mat', 'inputValue');
save('OutputTable.mat','OutputTable');
save('TrialTraces.mat', 'TrialTrace_Table');
save('Pre_TrialTraces.mat','Pre_TrialTrace_Table');
save('WholeTrace_Table.mat','WholeTrace_Table');
save('ZTraces.mat','ZTraces');
save('Peaks_All.mat','Peaks_Array');
save('Footprints_MasterTable.mat','Footprints_MasterTable','-v7.3');
save('Behavior_MasterTable.mat','Behavior_Array');
save('Behavior_TraceTable.mat','BEHTrace_Table');

% use '-v7.3' flag in saves after file names if they too big 


