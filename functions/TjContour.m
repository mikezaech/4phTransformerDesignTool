%%% Plot SOA Contours
function [t, figureCount] = TjContour(Io,Vo,Tj,Tj_limit,Isw,Vrem,Ilim,Vlim,version,titleString,figureCount)


if isstring(version) == 0
    Tj_gridHi = Tj.grid.hi;
    Tj_gridLo = Tj.grid.lo;
    Tj_batHi = Tj.bat.hi;
    Tj_batLo = Tj.bat.lo;
    
    Isw_gridHi = Isw.grid.hi;
    Isw_gridLo = Isw.grid.lo;
    Isw_batHi = Isw.bat.hi;
    Isw_batLo = Isw.bat.lo;
    
     Vrem_gridHi = Vrem.grid.hi > 1e-3;
     Vrem_gridLo = Vrem.grid.lo > 1e-3;
     Vrem_batHi = Vrem.bat.hi > 1e-3;
     Vrem_batLo = Vrem.bat.lo > 1e-3;
else
    Tj_gridHi = Tj.grid.hi.(version);
    Tj_gridLo = Tj.grid.lo.(version);
    Tj_batHi = Tj.bat.hi.(version);
    Tj_batLo = Tj.bat.lo.(version);
    
    Isw_gridHi = Isw.grid.hi.(version);
    Isw_gridLo = Isw.grid.lo.(version);
    Isw_batHi = Isw.bat.hi.(version);
    Isw_batLo = Isw.bat.lo.(version);
    
     Vrem_gridHi = Vrem.grid.hi.(version) > 1e-3;
     Vrem_gridLo = Vrem.grid.lo.(version) > 1e-3;
     Vrem_batHi = Vrem.bat.hi.(version) > 1e-3;
     Vrem_batLo = Vrem.bat.lo.(version) > 1e-3;
end
figure(figureCount);
figureCount = figureCount +1;
    set(gcf,'color','w');
    t(1) = tiledlayout(2,2,'TileSpacing','Compact','Padding','Compact');

% Options
    labelFont = 12;
    % Transparency of fill:
    transparency = 0.2;
    shadeColor = [0.8 0.8 0.8];
    % Custom Colormap:
    constantGrey = ones(10,1)*shadeColor;
    % Contour Lines
    lvl = [40:5:150];
    % X ticks
    xtickVar = [0:5:max(Io)];
    zvsLvl = [1 10];
% Grid High
ax(1) = nexttile;
% Contour            
    % Add ZVS Limit      
    contourf(Io,Vo,Vrem_gridHi,zvsLvl);    
    hold on
    % Contour Line Switching Current
    contour(Io,Vo,Tj_gridHi,lvl,'ShowText','off');
        title("Grid, High-Side");
        xticks(xtickVar);
    hold on
    % Add 100 degC limit
    contour(Io,Vo,Tj_gridHi,[Tj_limit,Tj_limit],'Color','k','LineStyle','-.','LineWidth',1.5);
    % HPC350 line:
    plot(Ilim,Vlim,'Color',	'#77AC30','LineStyle','-','LineWidth',1.5);
    grid on
    hold off
    xticklabels("");

% Battery High
ax(2) = nexttile;
% Contour            
    % Add ZVS Limit      
    contourf(Io,Vo,Vrem_batHi,zvsLvl); 
        hold on
    % Contour Line Switching Current
    contour(Io,Vo,Tj_batHi,lvl,'ShowText','off');
        title("Battery, High-Side");
        xticks(xtickVar);
    hold on
    % Add 100 degC limit
    contour(Io,Vo,Tj_batHi,[Tj_limit, Tj_limit],'Color','k','LineStyle','-.','LineWidth',1.5);
    % HPC350 line:
    plot(Ilim,Vlim,'Color',	'#77AC30','LineStyle','-','LineWidth',1.5);
    
    grid on
    hold off
    xticklabels("");
    yticklabels("");

% Grid Low
ax(3) = nexttile;
% Contour            
    % Add ZVS Limit      
    contourf(Io,Vo,Vrem_gridLo,zvsLvl);         
        
        hold on
    % Contour Line Switching Current
    contour(Io,Vo,Tj_gridLo,lvl,'ShowText','off');
        title("Grid, Low-Side");
        xticks(xtickVar);
    hold on
    % Add 100 degC limit
    contour(Io,Vo,Tj_gridLo,[Tj_limit, Tj_limit],'Color','k','LineStyle','-.','LineWidth',1.5);
    % HPC350 line:
    plot(Ilim,Vlim,'Color',	'#77AC30','LineStyle','-','LineWidth',1.5);
    grid on
    hold off

% Battery Low
ax(4) = nexttile;
% Contour            
    % Add ZVS Limit      
    contourf(Io,Vo,Vrem_batLo,zvsLvl);    
                  
        hold on
    % Contour Line Switching Current
    contour(Io,Vo,Tj_batLo,lvl,'ShowText','off');
        title("Battery, Low-Side");
        xticks(xtickVar);
    hold on
    % Add 100 degC limit
    contour(Io,Vo,Tj_batLo,[Tj_limit, Tj_limit],'Color','k','LineStyle','-.','LineWidth',1.5);
    % HPC350 line:
    plot(Ilim,Vlim,'Color',	'#77AC30','LineStyle','-','LineWidth',1.5);
    grid on
    yticklabels("");
% General           
    title(t,titleString)
    xlabel(t,"Output Current [A]",'FontSize',labelFont);
    ylabel(t,"Output Voltage [V]",'FontSize',labelFont);
    linkaxes(ax,'xy');
    xlim([min(Io),max(Io)]);

% Add colorbar
cb = colorbar(ax(end));
    ylabel(cb,'Junction Temperature [°C]','FontSize',labelFont);
    set(ax, 'Colormap', [constantGrey; hot(1000)], 'CLim',[0, 175]);
    cb.Layout.Tile = 'east'; 
    hold off
%% Overlay of all four plots

% Maximum Values of any bridge
maxTjGrid = max(Tj_gridHi,Tj_gridLo);
maxTjGridBatHi = max(maxTjGrid,Tj_batHi);
maxTj = max(maxTjGridBatHi,Tj_batLo);
maxZVSGrid = max(Vrem_gridHi,Vrem_gridLo);
maxZVSGridBatHi = max(maxZVSGrid,Vrem_batHi);
maxZVS = max(maxZVSGridBatHi,Vrem_batLo);
%
t(2) = figure(figureCount);
figureCount = figureCount +1;
    set(gcf,'color','w');
    
% Options
    labelFont = 12;
    % Transparency of fill:
    transparency = 0.2;
    % Contour Lines
    lvl = [40:5:150];



% Actual Figure
    % Dummy line for Legend: 
        line([0,0],[0,0],'Color','k','LineStyle','-.','LineWidth',1.5);

       hold on  
        fill([0,0.01],[0,0.01],shadeColor);       
      line([0,0],[0,0],'Color',	'#77AC30','LineStyle','-','LineWidth',1.5);
    % Shade Non ZVS area     
        contourf(Io,Vo,maxZVS,zvsLvl); 
    % HPC350 line:
        plot(Ilim,Vlim,'Color',	'#77AC30','LineStyle','-','LineWidth',1.5)   ;            
    % Junction Temperature Contours
        contour(Io,Vo,maxTj,lvl,'ShowText','off');
    % Tj Limit Line
        contour(Io,Vo,maxTj,[Tj_limit,Tj_limit],'Color','k','LineStyle','-.','LineWidth',1.5);         
        
        
% General           
    title(titleString);
    xlabel("Output Current [A]",'FontSize',labelFont);
    ylabel("Output Voltage [V]",'FontSize',labelFont);    
    xlim([min(Io),max(Io)]);
    xticks(xtickVar);
    grid on
% Add colorbar
cb = colorbar;
    ylabel(cb,'Junction Temperature [°C]','FontSize',labelFont);
    colormap([constantGrey; hot(1000)]);
% Legend
[~,lgd] = legend( num2str(Tj_limit) + " \circC Limit","No ZVS","HPC350");
% PatchInLegend = findobj(lgd, 'type', 'patch');
% set(PatchInLegend(2),'FaceColor',shadeColor);
hold off
    
end