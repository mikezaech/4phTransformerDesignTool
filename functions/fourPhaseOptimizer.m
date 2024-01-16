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
            converter.T = transformer(converter.T.N, x*0.01,x,converter.T.config);       
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
        [OPsol, lossStruc, Io, Vo] = opRangeSweep(converter,IoRange,VoRange,Pmax,25,25);
        
        %%
        PlossGridHi = arrayfun(@(x) x.Ploss.grid.hi,lossStruc);
        PlossBatHi = arrayfun(@(x) x.Ploss.bat.hi,lossStruc);
        PlossGridLo = arrayfun(@(x) x.Ploss.grid.lo,lossStruc);
        PlossBatLo = arrayfun(@(x) x.Ploss.bat.lo,lossStruc);
        
        lossSpread =  max([PlossGridHi, PlossBatHi,PlossGridLo,PlossBatLo],[],'all') - min([PlossGridHi, PlossBatHi,PlossGridLo,PlossBatLo],[],'all');
        % OPs within defined Output Range
        pointsRange = Io.*Vo <= Pmax;
    
        % Weighting Voltages above 600V more:
        weight = 0.5; % 20 %
        weightPoints = 1 + (Vo >= 600)*weight;
        PlossSum_HPC = sum((PlossGridHi + PlossBatHi + PlossBatLo + PlossGridLo).*pointsRange*weightPoints,'all');
        loss = PlossSum_HPC;
        %% Safe Operating Range Analysis
        [areaHot_tot, nTransistors, IrmsMax, figureCount] = pushPullSoaAnalysis(converter,lossStruc,Io,Vo,Pmax,1);
        disp("SOA: " + num2str(1 - areaHot_tot))
        disp("Max RMS Current: " + num2str(max(IrmsMax)))
        
        opt.xVal = x;
        opt.loss = loss;
        opt.lossSpread = lossSpread;
        opt.soa = 1 - areaHot_tot;
        opt.rmsMax = IrmsMax;
        opt.nTransistors = nTransistors;
        opt.OPsol = OPsol;
        opt.lossStruc = lossStruc;
        opt.converter = converter;       
        opt.optVar = optVar;
    end
   
end