function OPsol = cfpp_2x2phSolve(converter,Vo,Io)
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
    itMax = 150;
    itNr = 0; % Initialize
    errMax = 1e-3; % max deviation of clamp current

    % Phase shift limits
    phiMax = 1/ph - 1e-6;
    phiMin = 1e-6;
    % Initial guess
    phi = (phiMax + phiMin)/2;
%     phi = 0.0074;
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
        % Usefull indices
        halfcycle = find(switchingInstances == 0.5);
        quartcycle = find(switchingInstances == 0.25);
        %% Neutral Point Voltage on secondary          
        
        if ph == 2
             Vn = secNrOn/ph * Vclamp;
        else
            Vn = [(secStates(1,:) + secStates(3,:));(secStates(2,:) + secStates(4,:)) ]./(ph/2) .* Vclamp;  % [a & c; b & d]
        end
        %% Output Inductor Current
        % Time stamps
        t = switchingInstances*Ts;
        dt = [t(2:end),Ts] - t;

        % Voltage across inductor
        VL(1,:) = Vn(1,:) - Vo;
        dIL = VL(1,:)./Lo.*dt;
        IL1 = [0, cumsum(dIL(1:end-1))];

        itCnt = 0;
        IL_avg = trapz([switchingInstances, 1],[IL1, IL1(1)]);

        % find initial value
        while abs(IL_avg - Io/2) > 1e-3
            itCnt = itCnt + 1; 
            IL1 = IL1 + (Io/2 - IL_avg);            
            IL_avg = trapz([switchingInstances, 1],[IL1, IL1(1)]);
        
            if itCnt > 20
                error("did not CONVERGE ")
                break
            end
        end

        % shift by 90 degrees        
        IL2 = circshift(IL1,quartcycle - 1);       
        ILo = IL1 + IL2;
        IoAvg =  mean(ILo);

        %% Primary Current
        % Auxiliary voltages
        Vpri = Vi*(ph - priNrOn)/ph - (1 - priStates(1,:))*Vi;
        Vsec = (Vclamp*secStates(1,:) - Vn(1,:)); % works for voltage across secondary
        
        a1Gate = priStates(1,:);
        c1Gate = priStates(3,:);
        
        a2Gate = secStates(1,:);
        c2Gate = secStates(3,:);
        % 
        Vlk1 =  Vi/(ph/2).*(a1Gate - a2Gate + c2Gate - c1Gate);
        % Leakage voltage: reflect sec to pri:
%         Vlk1 = Vpri - Vsec*N; %  
        dIpri = Vlk1./(Lk*N^2) .* dt;
        Ipri = [0 cumsum(dIpri(1:end-1))]; % Starting from 0
        
        % Initial value (Numerically solved):
        itCnt = 0;
        Ipri_avg = trapz([switchingInstances, 1],[Ipri, Ipri(1)]);        
        while abs(Ipri_avg) > 1e-3
            itCnt = itCnt + 1; 
            Ipri = Ipri  - Ipri_avg;            
            Ipri_avg = trapz([switchingInstances, 1],[Ipri, Ipri(1)]);
        
            if itCnt > 20
                break
            end
        end

        %% Magnetizing Current
        Vlm = Vsec;
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
        
%% Secondary Current: Ia2 = 1/2 IL1 + Isec + Ilm
        Ipri_c = circshift(2.*Ipri,halfcycle - 1);
        Ilm_c = circshift(Ilm,halfcycle - 1);
        Isec_ = (Ipri_c - 2.*Ipri)*N; 
        Ia2 = 1/ph*(IL1 + Isec_ + (Ilm - Ilm_c));
        % Initial value (Numerically solved):
        itCnt = 0;
        Ia2_avg = trapz([switchingInstances, 1],[Ia2, Ia2(1)]);
        
        while abs(Ia2_avg - Io/ph) > 1e-3
            itCnt = itCnt + 1; 
            Ia2 = Ia2  + Ia2_avg;            
            Ia2_avg = trapz([switchingInstances, 1],[Ia2, Ia2(1)]);
        
            if itCnt > 20
                break
            end
        end

        Ic2 = circshift(Ia2,halfcycle - 1);

        IsecMatrix = uniformPhaseDelay(Ia2,switchingInstances,ph);

        IsecSum = sum(IsecMatrix);
        IsecAvg = trapz([switchingInstances, 1],[IsecSum, IsecSum(1)]);
        %
%         figure;plot(switchingInstances,Ia2);grid on;
        %% Clamp Current: Iclamp = - sum(Isec * secState), mean(Iclamp) == 0
        
        % make jump "instant": detect turn on/off & add 0
        % Dublicate switchingInstances:
        switchingTrans = repelem(switchingInstances,2);
        secStatesTrans = repelem(secStates,1,2); 

        for n = 1:ph
                stateChange = diff(secStatesTrans(n,:));
                offIdx(n) = find(stateChange == -1) + 2  ;
                onIdx(n)= find(stateChange == 1)  + 2;

                secStatesTrans(n,offIdx(n) - 1 ) = 1;
                secStatesTrans(n,onIdx(n) - 1) = 0;
        end

        % Transistor Currents & Clamp Current
        Itrans = secStatesTrans.*repelem(IsecMatrix,1,2);
        Iclamp = -sum([Itrans, Itrans(:,1)]);
        IclampAvg = trapz([switchingTrans, 1],Iclamp);
        err(itNr) = IclampAvg;


        if abs(err(itNr)) >= errMax % Not close enough
            if err(itNr) > 0 % Too much power transfer, decrease phi
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
            error("solution did not CONVERGE")
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
%     OPsol.tIL = tUnique;
    OPsol.IL  = ILo;
    OPsol.Vn  = Vn(1,:);
%     OPsol.VlkSec = Vlk;
%     OPsol.IlkSec = Ilk;
    OPsol.IlmSec = Ilm;
    OPsol.Ipri = Ipri;
    OPsol.Isec = IsecMatrix(1,:);
    OPsol.IsecMatrix = IsecMatrix;
    OPsol.Vclamp = Vclamp;
    OPsol.Iclamp = Iclamp;
    OPsol.IclampAvg = IclampAvg;
    OPsol.Io = Io;
    OPsol.Vo = Vo;
    OPsol.Vpri = Vpri;
    OPsol.Vsec = Vsec;
    OPsol.Itrans = Itrans;
    OPsol.switchingTrans = switchingTrans;
    OPsol.VlkPri = Vlk1;
    
end


% Figures to debug
    % figure(1)
    % subplot(3,1,1)
    %     plot([switchingTrans, 1],Iclamp)
    %     title('Clamp Current')
    %     hold on
    %     yline(IclampAvg)
    %     hold off
    %     grid on
    % subplot(3,1,2)
    %     plot(switchingInstances,IsecMatrix(1,:))
    %     title('Secondary Currents')
    %     grid on
    %     hold off
    % subplot(3,1,3)
    %     plot(switchingTrans,Itrans(1,:))
    %     title('Transistor Currents')
    %     hold on
    %     plot(switchingTrans,Itrans(2,:))
    %     plot(switchingTrans,Itrans(3,:))
    %     plot(switchingTrans,Itrans(4,:))
    %     grid on
    %     hold off
    % 
    %         
    % 
    % figure(2)
    % plot(err)
    % title("Clamp current each iteration")
    % grid on
