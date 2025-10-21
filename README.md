# Chapman-et-al-CellReports
Processing code written for Chapman, Raymond, and Fletcher submission of "Experience and behavior modulate piriform cortex odor representation in freely moving mice" to Cell Reports (2025). Current repository contains a small amount of sample data and scripts used to create clean response tables to generate the figures in the submission manuscript. All code included here was run using MATLAB 2023a.

"data_sample" folder contains the following:

responseExtraction_Behavior.m - script used to align calcium responses of individual neurons and behavior to odor stimulus times
Key_sample.csv - truncated list of sessions used; only includes the session from this repository
REC276616_D1awake_DeconTrace.csv - Denoised output from the CaImAn pipeline (Neuron x Timesample)
REC276616_D1awake_RawTrace.csv - Un-denoised output from the CaImAn pipeline (Neuron x Timesample)
REC276616_D1awake_index.csv - CellReg alignment results for the session
REC276616_D1awake_notes.csv - Timestamps and identity of delivered odor stimuli
REC276616_D1awake_timeStamps.csv - Miniscope timestamps for each captured frame
REC276616_D1awake_stampsBeh.csv - Behavior camera timestamps for each captured frame
REC276616_D1awake_Behavior.csv - DeepLabCut output from trained model; includes x/y coordinates as well as a likelihood score at each timepoint for each labeled point

"pre_processing_scripts" contains the following:

PreProcessing*.m - Input is the master output tables created by "responseExtraction_Behavior.m" containing all neuron x odor x trial responses as well as behavioral scores. These scripts remove cells not tracked across sessions and apply the various timepoint shifting methods included in the script name.
Generate_*.m - Inputs are the results from the relevant "PreProcessing.m" script. Compiles data from all animals and removes any missing data to compile the first 8 trials from each animal, when possible, into a day-sorted cell array. Labeling within each table depends on the final output (ordering by odor identity, by best response identity, behavior, etc.).
