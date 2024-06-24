function OPsol = currentFedPushPullSolve(converter,Vo,Io)
% CURRENTFEDPUSHPULLSOLVE calculates current and voltage waveforms of
% n-phased current fed push pull converter at a given output operating
% point.
%
% The phase shift is calculated numerically to fulfil KVL & KCL

    %% Unpack Struct

    % Converter Parameters  
    Vi = converter.Vi; % Input Voltage
    ph = converter.ph; % Nr. of phases
    fsw = converter.fsw; % Switching frequency
    Ts = 1/fsw;

    
    % Transformer Data
    T = converter.T;
    N = T.N;
    Lk = T.Lk; % LeakReferred to secondary side
    Lm = T.Lm; % Referred to secondary
    
    %% Circuit Parameters
    Lo = converter.Lo;
    dV = converter.dV;    
    Vclamp = converter.Vclamp;
    % Duty Cycle
    D = Vo/Vclamp; 
    D = D + (1e-6*(rem(D,0.25)==0)); % Small Hack to avoid 25%, 50% and 75% Duty Cycle
    %% Numerical Solution
    % Max Iterations to find phi 
    itMax = 200;
    itNr = 0; % Initialize
    errMax = 2e-3; % max deviation of clamp current
    
    % Phase shift limits
    phiMax = 1/ph;
    phiMin = 1e-6;
    % Initial guess
    phi = (phiMax + phiMin)/2;
%     phi = 0.0174;
    while itNr < itMax
        itNr = itNr + 1;
        phiIt(itNr) = phi;
        %% switching cycle       
        % Primary Switches:
        Qa1 = [0, D]; % [Qa1_on, Qa1_off]
        primarySwitching = mod(Qa1  + (0:1/ph:(ph-1)/ph)',1); % repeats every 1/ph, max 1
        % Secondary
        secondarySwitching = mod(primarySwitching + phi,1); % Secondary side is delayed by phase shift phi
        % Combine
        combinedSwitching = [primarySwitching;secondarySwitching];
        switchingInstances = sort(reshape(combinedSwitching,[1 numel(combinedSwitching)])); % All the switching instances sorted by occurance
        % For each switching instance in the cycle, determine which transistors are on.
        for n = 1:length(combinedSwitching)
        % turn on first?
            if combinedSwitching(n,1) < combinedSwitching(n,2)
                combinedStates(n,:) = (combinedSwitching(n,1) <= switchingInstances) & (combinedSwitching(n,2) > switchingInstances) ;
            else % On in beginning of cycle 
                combinedStates(n,:) = (combinedSwitching(n,2) > switchingInstances) + (combinedSwitching(n,1) <= switchingInstances);
            end
        end
        
        priStates = combinedStates(1:ph,:);
        secStates = combinedStates(ph+1:end,:);                
        % Number of phases on - primary
        priNrOn = sum(priStates);
        % Number of phases on - secondary
        secNrOn = sum(secStates);
        %% Neutral Point Voltage on secondary    
        % Vn = NrSecondaryTransistorsOn/ph * Vclamp (- sum(Iqsec)/Rdson) <- Ignore resistance for now    
        Vn = secNrOn/ph * Vclamp;            
        %% Output Inductor Current
        % Time stamps
        t = switchingInstances*Ts;
        % Voltage across output inductor
        VL = Vn - Vo;        
%         % Only consider timestamps with unique voltage value
%         VLuniqueIdx = [1, diff(VL)] ~= 0;
%         VLunique = VL(VLuniqueIdx);
%         tUnique = t(VLuniqueIdx);
%         dtUnique =  [tUnique(2:end),Ts] - tUnique;
%         
%         % Inductor Equation
%         dIL = VLunique./Lo.*dtUnique;
%         IL = Io - dIL;

        dt = [t(2:end),Ts] - t;

        % Voltage across inductor
        VL(1,:) = Vn(1,:) - Vo;
        dIL = VL(1,:)./Lo.*dt;
        IL1 = [0, cumsum(dIL(1:end-1))];

        itCnt = 0;
        IL_avg = trapz([switchingInstances, 1],[IL1, IL1(1)]);

        % find initial value
        while abs(IL_avg - Io) > 1e-3
            itCnt = itCnt + 1; 
            IL1 = IL1 + (Io - IL_avg);            
            IL_avg = trapz([switchingInstances, 1],[IL1, IL1(1)]);
        
            if itCnt > 20
                error("did not CONVERGE ")
                break
            end
        end     
        IL = IL1;% + IL2;
        IoAvg =  mean(IL);
        
        %% Leakage voltage
        % Auxiliary voltages
        Vpri = Vi*(ph - priNrOn)/ph;
        Vsec = Vclamp*(ph - secNrOn)/ph;
        % Leakage voltage of 1 phase (referred to secondary)
        Vlk = Vsec - (1 - secStates(1,:))*Vclamp - (1/N)*(Vpri - (1 - priStates(1,:))*Vi);
        
        %% Transformer Currents
        % Time steps 
        dt =  [t(2:end),Ts] - t;    
        %% Magnetizing Inductance
        Vlm = (secStates(1,:)*Vclamp) - Vn;     
        dIlm = Vlm./Lm.*dt;
         Ilm = [0 cumsum(dIlm(1:end-1))]; % Starting from 0
        % Initial value (Numerically solved):
        itCnt = 0;
        Ilm_avg = trapz([switchingInstances, 1],[Ilm, Ilm(1)]);
        
        while abs(Ilm_avg) > 1e-3
            itCnt = itCnt + 1; 
            Ilm = Ilm  - Ilm_avg;            
            Ilm_avg = trapz([switchingInstances, 1],[Ilm, Ilm(1)]);
        
            if itCnt > 20
                break
            end
        end
        %%

        % Delta Current through leakage inductance
        dIlk = -Vlk/Lk.*dt;
        
        % Transformer currents starting from 0
        Ilk_ = [0 cumsum(dIlk(1:end-1))]; % Referred from secondary  
        % Find average current and use as initial value
        IlkAvg = trapz(switchingInstances,Ilk_);    
        Ilk = Ilk_  - IlkAvg ;
    
        % Reflect to primary side
        IlkPri = [0 cumsum(dIlk(1:end-1)/N)] - IlkAvg/N;
    
        % Secondary Current
        Isec = -Ilk + Ilm + Io/ph; 
        IsecMatrix = uniformPhaseDelay(Isec,switchingInstances,ph);
        
        %% Clamp Current: Iclamp = - sum(Isec * secState), mean(Iclamp) == 0
        Iclamp = -sum(IsecMatrix.*secStates);
        IclampAvg = trapz(switchingInstances,Iclamp);
    
        err = IclampAvg;
        if abs(err) >= errMax % Not close enough
            if err > 0 % Too much power transfer, decrease phi
                phiMax = phi;
                phi = (phiMax + phiMin)/2;
            else % Too little power transfer, increase phi
                phiMin = phi;
                phi = (phiMax + phiMin)/2;
            end
        else 
            break
        end
        if itNr == itMax
            warning("solution did not CONVERGE")
            phi = 1;
        end
    end

   
    %% Output
    OPsol.itNr = itNr;
    OPsol.phiIt = phiIt;
    OPsol.phi = phi;
    OPsol.D = D;
    OPsol.switchingInstances = switchingInstances;
    OPsol.priStates = priStates;
    OPsol.secStates = secStates;
    OPsol.t = t;
    OPsol.tIL = t;
    OPsol.IL  = IL;
    OPsol.Vn  = Vn;
    OPsol.VlkSec = Vlk;
    OPsol.VlkPri = Vlk*N;
    OPsol.IlkSec = Ilk;
    OPsol.IlmSec = Ilm;
    OPsol.Ipri = IlkPri;
    OPsol.Isec = Isec;
    OPsol.Vpri = Vlm.*N;
    OPsol.Vsec = Vlm;
    OPsol.IsecMatrix = IsecMatrix;
    OPsol.Vclamp = Vclamp;
    OPsol.Iclamp = Iclamp;
    OPsol.IclampAvg = IclampAvg;
    OPsol.Io = Io;
    OPsol.Vo = Vo;
    
end