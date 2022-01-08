addpath('/OceanStor100D/home/lichengyu_lab/lipy/neuropixel/code/jpsth')

opt.type='ODR2AFC';
opt.criteria='any';
opt.prefix='1201';
opt.delay=5;
opt.starts=-5;
opt.ends=13;

homedir=ephys.util.getHomedir('dtype',opt.type);
ephys.util.dependency('buz',false);

% sig=bz.load_sig_pair('type',opt.type,'prefix',opt.prefix,'criteria','any');
load(fullfile(homedir,'sig.mat'),'sig');
sess=unique(sig.sess);
for si=1:numel(sess)
    onesess=sess(si);
    sesssel=sig.sess==onesess;
    if isfile(fullfile(homedir,'fcdata',sprintf('fc_coding_%d.mat',onesess)))
        disp(['skip',num2str(onesess)]);
    else
        bz.fccoding.fc_coding_one_sess(onesess,sig.suid(sesssel,:),'type',opt.type,'criteria',opt.criteria,'delay',opt.delay,'starts',opt.starts,'ends',opt.ends);
    end
end
