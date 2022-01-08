% ODR2AFC - 1s selection | correct/error trials
% 
opt.type='ODR2AFC';
opt.criteria='any';
opt.delay=5;
opt.partial='full';
opt.laser='any';
opt.correct_error='correct';
sps=30000;
homedir=ephys.util.getHomedir('dtype',opt.type,'type','raw'); % ~/DataSum directory

fl=dir(fullfile(homedir,'**','spike_info.hdf5')); % find reference probe path

for ii=1:size(fl,2)
    trial=h5read(fullfile(fl(ii).folder,'FR_All_1000.hdf5'),'/Trials'); % read in trials per session from FR_All_1000.hdf5
    pc_stem=regexp(fl(ii).folder,'(?<=DataSum/)(.*)(?=/)','match','once');
    if strcmp(pc_stem,'M6_20201106_g0') || strcmp(pc_stem,'M6_20201102_g0') || strcmp(pc_stem,'M11_20201031_g1') % for these three recordings, only delete first 29 trials
        trial=trial(30:size(trial,1),:);
    else
        trial=trial(31:size(trial,1),:);
    end
    
    % delete miss trial
    n=1;
    for i=1:size(trial,1)
        if trial(i,7)~=-1
            trial_new(n,:)=trial(i,:);
            n=n+1;
            %else if trial(i,7)==-1
            % break
        end
    end
    
    % keep sessions with >= 80% performance (连续30个Trial达到80%）
    win=30;
    j=1;
    x=1;
    while j <= size(trial_new,1)-29
        temp=trial_new(j:j+29,:);
        count=0;
        for i=1:30
            if (temp(i,5)==4 & temp(i,7)==1) || (temp(i,5)==8 & temp(i,7)==1) || (temp(i,5)==16 & temp(i,7)==1) ||...
                    (temp(i,5)==12 & temp(i,7)==2) || (temp(i,5)==20 & temp(i,7)==2) || (temp(i,5)==24 & temp(i,7)==2)
                count=count+1; % number of correct trials
            end
        end
        
        if count>=24
            trial_Per80(x:x+29,:)=trial_new(j:j+29,:);
            x=x+30; % When performance > 80% 跳到30个trial后再开始；否则，跳到下个trial开始
            j=j+30;
        else
            j=j+1;
        end
    end
    
    if size(trial_Per80,1)<90
        warning('trial_Per80 is less than 90 !!!');
    end
    
    if strcmp(opt.correct_error,'correct')
        target_trial=trial_Per80((ismember(trial_Per80(:,5), [4 8 16]) & trial_Per80(:,7)==1) | (ismember(trial_Per80(:,5), [12 20 24]) & trial_Per80(:,7)==2),:);
    else
        target_trial=trial_Per80((ismember(trial_Per80(:,5), [4 8 16]) & trial_Per80(:,7)==2) | (ismember(trial_Per80(:,5), [12 20 24]) & trial_Per80(:,7)==1),:);
    end

    responseTS=target_trial(:,2); % response cue TS

    % target time window
    t_window=[];
    for t=1:length(responseTS)
        t_window=cat(1,t_window,[responseTS(t)-0.5*sps,responseTS(t)+0.5*sps]);
    end
    % sig_con ids
    load(fullfile(homedir,'..','sums_conn.mat'),'sums_conn_str');
    sig_con=sums_conn_str(ii).sig_con;

    % suid corresponding ts
    cstr=h5info(fullfile(fl(ii).folder,fl(ii).name));
    spkID=[];spkTS=[];
    for prb=1:size(cstr.Groups,1)
        prbName=cstr.Groups(prb).Name;
        spkID=cat(1,spkID,h5read(fullfile(fl(ii).folder,fl(ii).name),[prbName,'/clusters']));
        spkTS=cat(1,spkTS,h5read(fullfile(fl(ii).folder,fl(ii).name),[prbName,'/times']));
    end
    
    clear trial_new trial_Per80
end
