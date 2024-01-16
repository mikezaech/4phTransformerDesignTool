function [t, figureCount] = ZVS_LimitPlot(C,Io,Vo,Isw,Vrem,Vcl,version,figureCount)
% Plot ZVS limits. 
%% Input Parse
if nargin < 8
    figureCount = 1;
end
% Variables
if exist('C.build','var') ==1
    build = C.build;
        % X ticks
    if build == "HW1" 
        xtickVar = [0:0.25:max(Io)]; % Low Currents
    else
        xtickVar = [0:5:max(Io)]; %High Currents
    end
end
if exist('C.Lau_set','var') == 1
    Lau_set = C.Lau_set;
end
Vi = C.Vi;
if isstring(version) == 0
    % Switching Currents
    Isw_gridHi = Isw.grid.hi;
    Isw_gridLo = Isw.grid.lo;
    Isw_batHi = Isw.bat.hi;
    Isw_batLo = Isw.bat.lo;
    
    VremGridHi = 100.*Vrem.grid.hi./Vi;
    VremGridLo = 100.*Vrem.grid.lo./Vi;
    VremBatHi = 100.*Vrem.bat.hi./Vcl;
    VremBatLo = 100.*Vrem.bat.lo./Vcl;
else
    % Switching Currents
    Isw_gridHi = Isw.grid.hi.(version);
    Isw_gridLo = Isw.grid.lo.(version);
    Isw_batHi = Isw.bat.hi.(version);
    Isw_batLo = Isw.bat.lo.(version);
    
    VremGridHi = 100.*Vrem.grid.hi.(version)./Vi;
    VremGridLo = 100.*Vrem.grid.lo.(version)./Vi;
    VremBatHi = 100.*Vrem.bat.hi.(version)./Vcl;
    VremBatLo = 100.*Vrem.bat.lo.(version)./Vcl;
end
%% Inital settings:

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
    VremLvl = [1:10:100];
    
    % X ticks
    xtickVar = [0:5:max(Io)];

    % Contours for Grid Side Plot
    cntNr = 10;
    Isw_gridHiMin = floor(min(min(Isw_gridHi))/10)*10;
    Isw_gridLoMin = floor(min(min(Isw_gridLo))/10)*10;
    %Isw_gridMax = ceil(max(max(Isw_grid))/10)*10;
    Isw_gridMax = -1;    
    step_gridHi = round((Isw_gridMax - Isw_gridHiMin)/cntNr);
    step_gridLo = round((Isw_gridMax - Isw_gridLoMin)/cntNr);
    lvl_gridHi = [Isw_gridHiMin:step_gridHi:Isw_gridMax];
    lvl_gridLo = [Isw_gridLoMin:step_gridLo:Isw_gridMax];

    % Contours for Battery Side Plot
    Isw_batHiMin = floor(min(min(Isw_batHi))/10)*10;
    Isw_batLoMin = floor(min(min(Isw_batLo))/10)*10;
    %Isw_batMax = ceil(max(max(Isw_bat))/10)*10;
    Isw_batMax = -1;    
    step_batHi = round((Isw_batMax - Isw_batHiMin)/cntNr);
    step_batLo = round((Isw_batMax - Isw_batLoMin)/cntNr);
    lvl_batHi = [Isw_batHiMin:step_batHi:Isw_batMax];
    lvl_batLo = [Isw_batLoMin:step_batLo:Isw_batMax];


%% Plot Complete ZVS Area:   
% Grid High
ax(1) = nexttile;
% Contour            
    % Add Remaining Voltage      
    contourf(Io,Vo,VremGridHi,VremLvl);                   
        hold on
    % Contour Lines Switching Current
    contour(Io,Vo,Isw_gridHi,lvl_gridHi,'ShowText','on','Color','k');
        title("Grid, High-Side");
        xticks(xtickVar);
    grid on
    hold off
    xticklabels("");

% Battery High
ax(2) = nexttile;
% Contour            
    % Add Remaining Voltage      
    contourf(Io,Vo,VremBatHi,VremLvl);                   
        hold on
    % Contour Lines Switching Current
    contour(Io,Vo,Isw_batHi,lvl_batHi,'ShowText','on','Color','k');
        title("Battery, High-Side");
        xticks(xtickVar);
    grid on
    hold off
    xticklabels("");
    yticklabels("");

% Grid Low
ax(3) = nexttile;
% Contour            
    % Add Remaining Voltage      
    contourf(Io,Vo,VremGridLo,VremLvl);                   
        hold on
    % Contour Lines Switching Current
    contour(Io,Vo,Isw_gridLo,lvl_gridLo,'ShowText','on','Color','k');
        title("Grid, Low-Side");
        xticks(xtickVar);
    grid on
    hold off

% Battery Low
ax(4) = nexttile;
    % Add Remaining Voltage      
    contourf(Io,Vo,VremBatLo,VremLvl);                   
        hold on
    % Contour Lines Switching Current
    contour(Io,Vo,Isw_batLo,lvl_batHi,'ShowText','on','Color','k');
        title("Battery, Low-Side");
        xticks(xtickVar);
    grid on
    yticklabels("");

% General
% Title
titleString = "Analysis of ZVS Area";
if isstring(version) == 1
    switch version
        case "OG"
            titleString = append(titleString," - Original");
        case "dV"
            titleString = append(titleString," - Clamp Control: " + num2str(Vcl) + "V");
        case "Lau"
             titleString = append(titleString," - Clamp Control: " + num2str(Vcl) + "V, L_{aux} = " + num2str(Lau_set*1e6) + " \mu H");
    end
end
title(t,titleString)
    xlabel("Output Current [A]",'FontSize',labelFont);
    ylabel("Output Voltage [V]",'FontSize',labelFont);
    linkaxes(ax,'xy');
    xlim([min(Io),max(Io)]);

% Add colorbar
customMap = flipud(hot(10));
customMap(1,:) = [1, 1, 0.85];
cb = colorbar(ax(end));
    ylabel(cb,'Percentage of Hard Switching','FontSize',labelFont);
    set(ax, 'Colormap', customMap, 'CLim',[1, 100]);
    cb.Layout.Tile = 'east'; 
    
legend([" Hard Switching Percentage", "Switching Current"]);
hold off



end