clear
%% graphing of response delays to show distribution
load('ProcessedData\PreProcessed_50window.mat');
Pre_delays_pull = cell2mat(horzcat(Pre_Delay_byDay{1,:}));
delays_pull = cell2mat(horzcat(Delay_byDay{1,:}));
% drop blanks
delays_pull(delays_pull == 0) = [];
Pre_delays_pull(Pre_delays_pull == 0) = [];
% get counts for graphing in prism
[GC_pre,GR_pre] = groupcounts(Pre_delays_pull(:));
[GC,GR] = groupcounts(delays_pull(:));
% Drop the ends; pretty noteable edge effect otherwise; for prism, I'm
% currently not dropping the ends, but instead excluding them after
% copying them over. 
delays_pull(delays_pull==1) = NaN;
delays_pull(delays_pull==50) = NaN;
Pre_delays_pull(Pre_delays_pull==1) = NaN;
Pre_delays_pull(Pre_delays_pull==50) = NaN;
figure,
h = histogram(delays_pull);
figure, 
h2 = histogram(Pre_delays_pull);

% test for distribution similarity (kolmogorov-smirnov)
[h,p,ks2stat] = kstest2(delays_pull,Pre_delays_pull);
