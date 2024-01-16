%%% 4 Surface -  tiled Layout
function [t, figureCount] = tiledSurf(x,y,z1,z2,z3,z4,zLabelString,titleString,figureCount)

    figure(figureCount)
    figureCount = figureCount +1;

    set(gcf,'color','w');
    t = tiledlayout(2,2,'TileSpacing','Compact');
    
    % Grid High
    ax1 = nexttile
      h(1) = surf(x,y,z1);          
          title("Grid, High-Side")
          xlabel("Output Current [A]")
          ylabel("Output Voltage [V]")
          zlabel(zLabelString)
          z_boundary(1,:) = zlim();
    % Battery High
    ax2 = nexttile
      h(2) = surf(x,y,z2);
          
          title("Battery, High-Side")
    
          xlabel("Output Current [A]")
          ylabel("Output Voltage [V]")
          zlabel(zLabelString)
          z_boundary(2,:) = zlim();
    % Grid Low
    ax3 = nexttile
      h(3) = surf(x,y,z3);
         
          title("Grid, Low-Side")
    
          xlabel("Output Current [A]")
          ylabel("Output Voltage [V]")
          zlabel(zLabelString)
          z_boundary(3,:) = zlim();
    % Battery Low
    ax4 = nexttile
      h(4) = surf(x,y,z4);          
          title("Battery, Low-Side")
    
          xlabel("Output Current [A]")
          ylabel("Output Voltage [V]")
          zlabel(zLabelString)          
          z_boundary(4,:) = zlim();
    % General
           
          title(t,titleString)
          set(h(:), 'EdgeAlpha',0.01)
          % Make Z limits equal
          intSpacer = 50; % Round up to nearest value (e.g. 420 -> 450)
          z_max = ceil(max(z_boundary,[],'all')/intSpacer)*intSpacer;
          zlim(ax1,[0, z_max]);
          zlim(ax2,[0, z_max]);
          zlim(ax3,[0, z_max]);
          zlim(ax4,[0, z_max]);
end