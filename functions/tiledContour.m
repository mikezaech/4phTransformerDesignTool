%%% 4 Surface -  tiled Layout
function [t, figureCount] = tiledSurf(x,y,z1,z2,z3,z4,zLabelString,titleString,figureCount)

    figure(figureCount)
    figureCount = figureCount +1;

    set(gcf,'color','w');
    t = tiledlayout(2,2,'TileSpacing','Compact');
    
    % Grid High
    ax(1) = nexttile
      contourf(x,y,z1);          
          title("Grid, High-Side")
          xlabel("Output Current [A]")
          ylabel("Output Voltage [V]")
          zlabel(zLabelString)
          z_boundary(1,:) =  [min(z1,[],'all'), max(z1,[],'all')];
          grid on
    % Battery High
    ax(2) = nexttile
      contourf(x,y,z2);
          grid on
          title("Battery, High-Side")
    
          xlabel("Output Current [A]")
          ylabel("Output Voltage [V]")
          zlabel(zLabelString)
          z_boundary(2,:) = [min(z2,[],'all'), max(z2,[],'all')];
    % Grid Low
    ax(3) = nexttile
       contourf(x,y,z3);
         
          title("Grid, Low-Side")
            grid on
          xlabel("Output Current [A]")
          ylabel("Output Voltage [V]")
          zlabel(zLabelString)
          z_boundary(3,:) = [min(z3,[],'all'), max(z3,[],'all')];
    % Battery Low
    ax(4) = nexttile
      contourf(x,y,z4);          
          title("Battery, Low-Side")
            grid on
          xlabel("Output Current [A]")
          ylabel("Output Voltage [V]")
          zlabel(zLabelString)          
          z_boundary(4,:) = [min(z4,[],'all'), max(z4,[],'all')];
    % General
           
          title(t,titleString)         
          % Make Z limits equal
          intSpacer = 1; % Round up to nearest value (e.g. 420 -> 450)
          z_max = ceil(max(z_boundary,[],'all')/intSpacer)*intSpacer;
          zlim(ax(1),[0, z_max]);
          zlim(ax(2),[0, z_max]);
          zlim(ax(3),[0, z_max]);
          zlim(ax(4),[0, z_max]);

          % Add colorbar
    cb = colorbar(ax(end));
    ylabel(cb,zLabelString,'FontSize',12);
    set(ax, 'Colormap', brighten(hot(1000),0.8), 'CLim',[0, z_max + z_max*0.1]);
    cb.Layout.Tile = 'east'; 
    hold off
    
end