function [vars, Graph, EEG] = PlotDelpAndMovs(EEG, vars, Graph)
 %function to plot delp, movs, and mags value every 10 minutes when LLAMAS is running  
  if ~isfield(vars, 'LastPlotDM') 
    vars.LastPlotDM = 0;
    vars.SpecPeriod = 10*60*EEG.fs; %update every 10 minutes
    
  end
    if (vars.currentPosition - vars.LastPlotDM)> vars.SpecPeriod
        %linkdata(vars.dpfigure, 'on');   
        %create handles to link the updating variables to the plots
        %delpsHandle = findobj(vars.delpsplot, 'type', 'line');
        %set(delpsHandle,'YDataSource', 'vars.alldelps');
        %movsHandle= findobj(vars.movsplot, 'type', 'line');
        %set(movsHandle,'YDataSource', 'vars.allmovs');
        %create figure with subplots of delps and movs
        figure('Name','Plot of Delp, Mags and Movs');
        subplot(3,1,1);
        plot(vars.alldelps,'LineWidth',2)
        xlabel('Number of Delps')
        ylabel('Delp Value')
        title('Delp')
        
        subplot(3,1,2);
        plot(vars.allmovs,'LineWidth',2);
        xlabel('Number of Movs')
        ylabel('Mov Value')
        title('Mov')
        
        
        subplot(3,1,3);
        plot(vars.allMags,'LineWidth',2);
        xlabel('Number of Mags')
        ylabel('Mags Value')
        title('Mags')
        vars.LastPlotDM = vars.currentPosition;        
    end
end
