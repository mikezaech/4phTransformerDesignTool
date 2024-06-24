%%% 4ph Current fed push pull converter optimizer
function [optRun, xOpt] = fourPhaseOptimizer(converter,optVar,xMin,xMax)
% FOURPHASEOPTIMIZER finds a value for the converter parameter defined
% in "optVar" with the bounds defined in xMin and xMax using the golden
% section method.
% converter includes the converter parameters as struct (see example in
% other scripts).

%% Optimization body (Golden Section)

    % Golden ratio:
    tau = 0.618;
    % Max Iterations
    maxIter = 50;
    % Min Increase of SOA
    lossMinIncrease = 50;
    % Find Upper & Lower Bounds
                                % Magnetizing Inductance: xMin = 50e-6;
                                % xMax = 1e-3;
    
    xLower = xMin;
    xUpper = xMax;
    % store x values
    xValues(1,:) = [xLower, xUpper];
    
    % Evaluate Boundaries
    optMinVal = calcLoss(converter,xLower,optVar);
    funcEval = 1;
    optRun(funcEval) = optMinVal; % store
    xRun(funcEval) = optRun(funcEval).xVal;
    
    optMaxVal = calcLoss(converter,xUpper,optVar);
    funcEval = funcEval + 1;
    optRun(funcEval) = optMaxVal; % store
    xRun(funcEval) = optRun(funcEval).xVal;
    
    lossValues(1,:) = [optMinVal.loss, optMaxVal.loss];
    
    dx = xUpper - xLower;
    dxMin = dx/100;  % 1% deviation from optimum
    itNr = 1;
    
    while itNr <= maxIter
       
        % Find x_left  (at (1-tau*(dx)) & x_right
        xLeft = xLower + (1-tau)*dx;
        xRight = xLower +  (tau)*dx;
        x = [xLeft,xRight];
        % Evaluate
        if sum(xValues == xLeft,'all') == 1 % Don't evaluate same value twice
            optIdx = find(xRun == xLeft);
            optLeft  = optRun(optIdx);
        else
            optLeft  = calcLoss(converter,xLeft,optVar);
            funcEval = funcEval + 1;
            optRun(funcEval) = optLeft; % store
            xRun(funcEval) = optRun(funcEval).xVal;
        end
    
        if sum(xValues == xRight,'all') == 1 % Don't evaluate same value twice
            optIdx = find(xRun == xRight);
            optRight  = optRun(optIdx);
        else
            optRight  = calcLoss(converter,xRight,optVar);
            funcEval = funcEval + 1;
            optRun(funcEval) = optRight; % store
            xRun(funcEval) = optRun(funcEval).xVal;
        end
    %     optRight = calcLoss(xRight);
        
        lossLeft = optLeft.loss;
        lossRight = optRight.loss;
    
        % Compare and set new boundaries
        if lossLeft < lossRight
            xUpper = xRight;
        elseif lossLeft > lossRight
            xLower = xLeft;
        else 
            
            [lossOpt, xIdx] = min([lossLeft,lossRight]);
            xOpt = x(xIdx);
            break
        end
        dx = xUpper - xLower;
    
        % store x values
        xValues(itNr + 1,:) = [xLeft xRight];
        lossValues(itNr + 1,:) = [lossLeft, lossRight];
        % Convergence Criteria
        if dx <= dxMin || abs(min(lossValues(itNr,:)) - min(lossValues(itNr + 1,:))) < lossMinIncrease
            [lossOpt, xIdx] = min([lossLeft,lossRight]);
            xOpt = x(xIdx);
            break
        end
        itNr = itNr + 1; 
    end
    
    
    %%
    % Check whether found value is better than zero:
    if optMinVal.loss < lossOpt
        lossOpt =  optMinVal.loss ;
        xOpt = xMin;
    end
    
    disp("Optimal " + optVar +": " + num2str(xOpt))
    %% 
    
    % Meta-Function
    function opt = calcLoss(converter,x,optVar)
        disp(newline + "Current " + optVar + " value: " + num2str(x))
        % Update variable
        % If is in transformer:
        if contains(optVar,'Lm') == 1 
            converter.T.design.Lm_primary = x;
            converter.T = defineTransformer(converter.T.design, converter.T.config);       
        else
            converter.(optVar) = x;
            % Clamp Voltage Update:
            if contains(optVar,'dV') == 1
                converter.Vclamp = converter.Vi/(2/3) - converter.dV;
            end
        end
        %% Operating Range
        IoRange = [0.5,125];
        VoRange = [200,920];
        Pmax = 350e3/4;
        
        %% Sweep Operating range
        [OPsol, transformerAnalysis, lossStruc, Io, Vo] = opRangeSweep(converter,IoRange,VoRange,Pmax,25,25);
        
        %% Transistor losses
        PqGridHi = arrayfun(@(x) x.Ploss.grid.hi,lossStruc);
        PqBatHi = arrayfun(@(x) x.Ploss.bat.hi,lossStruc);
        PqGridLo = arrayfun(@(x) x.Ploss.grid.lo,lossStruc);
        PqBatLo = arrayfun(@(x) x.Ploss.bat.lo,lossStruc);
        transistorLossSpread =  max([PqGridHi, PqBatHi,PqGridLo,PqBatLo],[],'all') - min([PqGridHi, PqBatHi,PqGridLo,PqBatLo],[],'all');
        
        % Transformer RMS currents
        IrmsPri = arrayfun(@(x) x.IpriRms,transformerAnalysis);
        IrmsSec = arrayfun(@(x) x.IsecRms,transformerAnalysis);
        % Transformer losses
        Pcore = arrayfun(@(x) x.Pcore,transformerAnalysis);
        Pwinding = arrayfun(@(x) x.Pw,transformerAnalysis);

        Ptransformer = Pcore + Pwinding;
       
        % OPs within defined Output Range
        pointsRange = Io.*Vo <= Pmax;
    
        % Weighting Voltages above 600V more:
        weight = 10; % 20 %
        weightPoints = 1 + (or(Vo >= 800, and(Io >= 100, Vo >= 600)))*weight;
        PlossSum_HPC = sum((PqGridHi + PqBatHi + PqBatLo + PqGridLo + Ptransformer).*pointsRange*weightPoints,'all');
        loss = PlossSum_HPC;
        %% Safe Operating Range Analysis
        [areaHot_tot, nTransistors, IrmsMax, figureCount] = pushPullSoaAnalysis(converter,lossStruc,Io,Vo,Pmax,1);
        tiledContour(Io,Vo,PqGridHi,PqBatHi,PqGridLo,PqBatLo,"Losses [W]","Transistor Losses",figureCount)
        figureCount = figureCount + 1;


   
        figure(figureCount)
        figureCount = figureCount + 1;
         t = tiledlayout(1,2,'TileSpacing','Compact');
         ax(1) = nexttile
          contourf(Io,Vo,Pcore);          
              title("Core Losses")
              xlabel("Output Current [A]")
              ylabel("Output Voltage [V]")
              zlabel("Losses [W]")
                  z_boundary(1,:) =  [min(Pcore,[],'all'), max(Pcore,[],'all')];
              grid on
        
         ax(2) = nexttile
        contourf(Io,Vo,Pwinding);
              grid on
              title("Winding Losses")
        
              xlabel("Output Current [A]")
              ylabel("Output Voltage [V]")
              zlabel("Losses [W]")
                  z_boundary(2,:) = [min(Pwinding,[],'all'), max(Pwinding,[],'all')];
        
        % General
               
              title("Transformer Losses")         
              % Make Z limits equal
                  intSpacer = 1; % Round up to nearest value (e.g. 420 -> 450)
                  z_max = ceil(max(z_boundary,[],'all')/intSpacer)*intSpacer;
                  zlim(ax(1),[0, z_max]);
                  zlim(ax(2),[0, z_max]);
        
              % Add colorbar
        cb = colorbar(ax(end));
        ylabel(cb,"Losses [W]",'FontSize',12);
             set(ax, 'Colormap', brighten(hot(1000),0.8), 'CLim',[0, z_max + z_max*0.1]);
        cb.Layout.Tile = 'east'; 
        hold off

    figure(figureCount)
        figureCount = figureCount + 1;
        t = tiledlayout(1,2,'TileSpacing','Compact');
        ax(1) = nexttile
        contourf(Io,Vo,IrmsPri);          
              title("Primary Side RMS Current")
              xlabel("Output Current [A]")
              ylabel("Output Voltage [V]")
              zlabel("Current [A]")
                  z_boundary(1,:) =  [min(IrmsPri,[],'all'), max(IrmsPri,[],'all')];
              grid on
        
         ax(2) = nexttile
        contourf(Io,Vo,IrmsSec);
              grid on
              title("Secondary Side RMS Current")
        
              xlabel("Output Current [A]")
              ylabel("Output Voltage [V]")
              zlabel("Current [A]")
                  z_boundary(2,:) = [min(IrmsSec,[],'all'), max(IrmsSec,[],'all')];
        
        % General
               
              title("Transformer RMS Currents")         
              % Make Z limits equal
                  intSpacer = 1; % Round up to nearest value (e.g. 420 -> 450)
                  z_max = ceil(max(z_boundary,[],'all')/intSpacer)*intSpacer;
                  zlim(ax(1),[0, z_max]);
                  zlim(ax(2),[0, z_max]);
        
              % Add colorbar
        cb = colorbar(ax(end));
        ylabel(cb,"Current [A]",'FontSize',12);
             set(ax, 'Colormap', brighten(hot(1000),0.8), 'CLim',[0, z_max + z_max*0.1]);
        cb.Layout.Tile = 'east'; 
        hold off
        %%
     
        disp("SOA: " + num2str(1 - areaHot_tot))
        disp("Max Transistor RMS Current: " + num2str(max(IrmsMax)))
        
        opt.lossValues.PqGridHi = PqGridHi;
        opt.lossValues.PqBatHi = PqBatHi;
        opt.lossValues.PqGridLo = PqGridLo;
        opt.lossValues.PqBatLo = PqBatLo;
        opt.lossValues.Pq_tot = PqGridHi + PqBatHi + PqGridLo + PqBatLo;
        opt.lossValues.Pcore = Pcore;
        opt.lossValues.Pwinding = Pwinding;
        opt.lossValues.Ptransformer = Ptransformer;        

        opt.xVal = x;
        opt.loss = loss;
        opt.lossSpread = transistorLossSpread;
        opt.soa = 1 - areaHot_tot;
        opt.rmsMax = IrmsMax;
        opt.nTransistors = nTransistors;
        opt.OPsol = OPsol;
        opt.lossStruc = lossStruc;
        opt.converter = converter;       
        opt.optVar = optVar;
    end
   
end