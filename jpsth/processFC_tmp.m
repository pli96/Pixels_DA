CodePath='/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/';

addpath(fullfile(CodePath,'npy-matlab','npy-matlab'))
addpath(fullfile(CodePath,'xcorr'))
addpath(fullfile(CodePath,'buzcode'))
addpath(fullfile(CodePath,'jpsth'))

opt.type='ODR2AFC';
opt.criteria='any';
opt.delay=5;
prefix='1220';

%% Functional Coupling - Buzsaki Method
bz.x_corr_bz(fidx,prefix,'type',opt.type,'criteria',opt.criteria,'delay',opt.delay);

%% Save sum_conn.mat
bz.sums_conn('poolsize',5,'type','ODR2AFC','criteria','any','prefix','1220');


