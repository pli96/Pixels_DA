function [sel_S1,sel_S2]=ExtractTrial(in,opt)
arguments
    in double
    opt.task (1,:) char    
    opt.trials (1,:) char    
end

switch(opt.task)
    case 'AIOPTO'
        if strcmp(opt.trials,'laseroff-correct')
            sel_S1=find(in(:,5)==4 & in(:,9)== -1 & in(:,11)== 1);
            sel_S2=find(in(:,5)==8 & in(:,9)== -1 & in(:,11)== 1);
        elseif strcmp(opt.trials,'laseroff-error')
            sel_S1=find(in(:,5)==4 & in(:,9)== -1 & in(:,11)== 0);
            sel_S2=find(in(:,5)==8 & in(:,9)== -1 & in(:,11)== 0);
        elseif strcmp(opt.trials,'laseron-correct')
            sel_S1=find(in(:,5)==4 & in(:,9)== 2 & in(:,11)== 1);
            sel_S2=find(in(:,5)==8 & in(:,9)== 2 & in(:,11)== 1);
        elseif strcmp(opt.trials,'laseron-error')
            sel_S1=find(in(:,5)==4 & in(:,9)== 2 & in(:,11)== 0);
            sel_S2=find(in(:,5)==8 & in(:,9)== 2 & in(:,11)== 0);
        elseif strcmp(opt.trials,'laseron')
            sel_S1=find(in(:,5)==4 & in(:,9)== 2 );
            sel_S2=find(in(:,5)==8 & in(:,9)== 2 );
        elseif strcmp(opt.trials,'laseroff')
            sel_S1=find(in(:,5)==4 & in(:,9)== -1 );
            sel_S2=find(in(:,5)==8 & in(:,9)== -1 );
        elseif strcmp(opt.trials,'correct')
            sel_S1=find(in(:,5)==4 & in(:,11)== 1);
            sel_S2=find(in(:,5)==8 & in(:,11)== 1);
        elseif strcmp(opt.trials,'error')
            sel_S1=find(in(:,5)==4 & in(:,11)== 0);
            sel_S2=find(in(:,5)==8 & in(:,11)== 0);
        else
            sel_S1=find(in(:,5)==4);
            sel_S2=find(in(:,5)==8);
        end
    
    case 'dual_task'
        if strcmp(opt.trials,'distractorGo-correct')
            sel_S1=find(in(:,5)==4 & in(:,9)== 2 & in(:,14)== 1 & in(:,15)== 1);
            sel_S2=find(in(:,5)==8 & in(:,9)== 2 & in(:,14)== 1 & in(:,15)== 1);
        elseif strcmp(opt.trials,'distractorNoGo-correct')
            sel_S1=find(in(:,5)==4 & in(:,9)== 16 & in(:,14)== 1 & in(:,15)== 1);
            sel_S2=find(in(:,5)==8 & in(:,9)== 16 & in(:,14)== 1 & in(:,15)== 1);
        elseif strcmp(opt.trials,'distractorNo-correct')
            sel_S1=find(in(:,5)==4 & in(:,9)== -1 & in(:,14)== 1 & in(:,15)== 1);
            sel_S2=find(in(:,5)==8 & in(:,9)== -1 & in(:,14)== 1 & in(:,15)== 1);
        elseif strcmp(opt.trials,'distractorGo-error')
            sel_S1=find(in(:,5)==4 & in(:,9)== 2 & in(:,14)== 0);
            sel_S2=find(in(:,5)==8 & in(:,9)== 2 & in(:,14)== 0);
        elseif strcmp(opt.trials,'distractorNoGo-error')
            sel_S1=find(in(:,5)==4 & in(:,9)== 16 & in(:,14)== 0);
            sel_S2=find(in(:,5)==8 & in(:,9)== 16 & in(:,14)== 0);
        elseif strcmp(opt.trials,'distractorNo-error')
            sel_S1=find(in(:,5)==4 & in(:,9)== -1 & in(:,14)== 0);
            sel_S2=find(in(:,5)==8 & in(:,9)== -1 & in(:,14)== 0);     
         elseif strcmp(opt.trials,'correct')
            sel_S1=find(in(:,5)==4 & in(:,14)== 1);
            sel_S2=find(in(:,5)==8 & in(:,14)== 1);
        elseif strcmp(opt.trials,'error')
            sel_S1=find(in(:,5)==4 & in(:,14)== 0);
            sel_S2=find(in(:,5)==8 & in(:,14)== 0);
        else
            sel_S1=find(in(:,5)==4);
            sel_S2=find(in(:,5)==8);
        end
    
    case 'neupix'
        if strcmp(opt.trials,'correct')
            sel_S1=in(:,5)==4 & in(:,8)==6 & all(in(:,9:10),2);
            sel_S2=in(:,5)==8 & in(:,8)==6 & all(in(:,9:10),2);
        else % error trial
            sel_S1=in(:,5)==4 & in(:,8)==6 & in(:,10)==0;
            sel_S2=in(:,5)==8 & in(:,8)==6 & in(:,10)==0;
        end
end
end
