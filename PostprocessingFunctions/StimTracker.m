function [vars, Graph, EEG] = StimTracker(EEG, vars, Graph)
%create a window that shows updated values of stims delivered every three minutes
    if ~isfield(vars, 'stimfig')
        vars.UpdatePeriod= 180*EEG.fs; %update values every three minutes
        vars.LastUpdate=0;
        %create table
        Stimuli = {'Previous (1)';'Previous (2)';'Previous (3)'; 'Total Stims'};
        Times = {'none';'none';'none';'none'};
        t=table(Stimuli,Times);
        vars.stimfig = uifigure('name','Stimulus Tracker');
        vars.stimtable = uitable(vars.stimfig,'Data', t);
        
    end
       
    if (vars.currentPosition-vars.LastUpdate) > vars.UpdatePeriod
    
        %calculate times last three stims were delivered and update stimulus table
        if vars.StimCount >= 2 %put >=2 since vars.StimCount is initialized as 1
        vars.stimtable.Data.Times(1) = {sprintf('%.2f minutes ago',(vars.currentPosition-vars.StimTimes(vars.StimCount-1))/(EEG.fs*60))};
        end 
    
        if vars.StimCount >= 3
        vars.stimtable.Data.Times(2) = {sprintf('%.2f minutes ago',(vars.currentPosition-vars.StimTimes(vars.StimCount-2))/(EEG.fs*60))};
        end
  
        if vars.StimCount >= 4
        vars.stimtable.Data.Times(3) = {sprintf('%.2f minutes ago',(vars.currentPosition-vars.StimTimes(vars.StimCount-3))/(EEG.fs*60))};
        end
        
        vars.stimtable.Data.Times(4) = {sprintf('%d',vars.StimCount-1)};
       
        vars.LastUpdate = vars.currentPosition;
    end
            
end
