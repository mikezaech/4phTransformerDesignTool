function lossStruc = pushPullTransistorLossAnalysis(converter,OPsol)
% PUSHPULLLOSSANALYSYS calculates RMS currents, ZVS border, switching
% losses, conduction losses, and junction temperature at the output
% operating point at which OPsol is calculated
    
    % Unpack 
    switchingInstances = OPsol.switchingInstances;
    D = OPsol.D;
    phi = OPsol.phi;
    Igrid = OPsol.Ipri;
    Ibat = OPsol.Isec;
    Vclamp = OPsol.Vclamp;
    % figure(1)
    %     subplot(2,1,1)
    %     plot(OPsol.t,OPsol.IsecMatrix)
    %     grid on
    %     
    %     subplot(2,1,2)
    %     plot(OPsol.tIL,OPsol.IL)
    %     grid on
    %     hold off
    
    %% Find Switching Currents (Current before Transistor turn on)
    
    % Switching indices:
    gridLoOnIdx = find(switchingInstances == D,1);
    batHiOnIdx = find(switchingInstances == phi,1);
    batLoOnIdx = find(switchingInstances == mod(phi + D,1),1);
    
    Isw.grid.hi = Igrid(1);
    Isw.grid.lo = Igrid(gridLoOnIdx);
    
    Isw.bat.hi = Ibat(batHiOnIdx);
    Isw.bat.lo = Ibat(batLoOnIdx);
    
    %% Auxiliary Inductor
    Lau = converter.Lau;
    Ts = 1/converter.fsw;
    if Lau > 0
        % Find actual ZVS current contribution 
        for n = 1:length(D)
            if D(n) <= 0.25
                dI_Lau(n) = 3/4 * Vclamp/Lau * D(n)*Ts;    
            elseif D(n) > 0.25 && D(n) <= 0.5
                    dI_Lau(n) = 2*Vclamp/(8*Lau)*(D(n) + 0.5)*Ts;
            elseif D(n) > 0.5 && D(n) <= 0.75
                    dI_Lau(n) = 2*Vclamp/(8*Lau)*(1.5-D(n))*Ts;
            else 
                dI_Lau(n) = 3/4*Vclamp/Lau*(1-D(n))*Ts;
            end
        end
        % Calculating value of iLau at switching instance:
        topOn1 = (switchingInstances <= D);
        topOff1 = (switchingInstances > D) .* (switchingInstances <= 1);
    
        ILau = (0.5* dI_Lau - dI_Lau/D * switchingInstances).*topOn1...
               + (-0.5* dI_Lau + dI_Lau/(1-D) * (switchingInstances-D)).*topOff1;
    
        Ibat(1,:) = Ibat(1,:) + ILau;
        
        % Update switching current
        Isw.bat.hi = Isw.bat.hi - 0.5*dI_Lau';
        Isw.bat.lo = Isw.bat.lo + 0.5*dI_Lau';
    end
    
    %% Calculate RMS Currents
    
    % Get Transistor Traces
    [qGridHiTime, IqGridHi] = switchedPwlWaveform(Igrid,OPsol.switchingInstances,OPsol.priStates(1,:));
    [qGridLoTime, IqGridLo] = switchedPwlWaveform(Igrid,OPsol.switchingInstances,~OPsol.priStates(1,:));
    [qBatHiTime, IqBatHi] = switchedPwlWaveform(Ibat,OPsol.switchingInstances,OPsol.secStates(1,:));
    [qBatLoTime, IqBatLo] = switchedPwlWaveform(Ibat,OPsol.switchingInstances,~OPsol.secStates(1,:));

   
    Irms.grid.hi = sqrt(1/Ts * trapz(qGridHiTime*Ts,IqGridHi.^2));
    Irms.grid.lo = sqrt(1/Ts * trapz(qGridLoTime*Ts,IqGridLo.^2));
    Irms.bat.hi = sqrt(1/Ts * trapz(qBatHiTime*Ts,IqBatHi.^2));
    Irms.bat.lo = sqrt(1/Ts * trapz(qBatLoTime*Ts,IqBatLo.^2));
    
    % Adjust Transistor Currents according to nr. of parallel devices
    Irms.grid.hi = Irms.grid.hi/converter.n_parGrid(1);
    Irms.grid.lo = Irms.grid.lo/converter.n_parGrid(2);
    Irms.bat.hi = Irms.bat.hi/converter.n_parBat(1);
    Irms.bat.lo = Irms.bat.lo/converter.n_parBat(2);
    
    
    %% Minimum current to assure ZVS under the effect on dead time
    % ZVS Surface Current:    
    phi_cri = converter.Td/Ts;             % If PS is smaller than phi_cri, it becomes a limiting factor for ZVS
    
    if phi < phi_cri
        deltaT = phi*Ts;
    else 
        deltaT = converter.Td;
    end       
    
    %% ZVS Conditions: Calculating Vrem
    % Field Names:
    fn_side = fieldnames(Irms);
    fn_level = fieldnames(Irms.grid);
    % Defining useful variables
    n_par.grid.hi = converter.n_parGrid(1);
    n_par.grid.lo = converter.n_parGrid(2);
    n_par.bat.hi = converter.n_parBat(1);
    n_par.bat.lo = converter.n_parBat(2);
    %
    L.bat = converter.T.Lk;
    L.grid = converter.T.Lk*converter.T.N^2;
    %
    Vds.grid = converter.Vi;
    Vds.bat = Vclamp;
    
    
    % Junction to Ambient Thermal Resistance
    RthJA.grid = converter.Qgrid.RthJC + converter.RthCA;
    RthJA.bat = converter.Qbat.RthJC + converter.RthCA;
    % Unpack Qoss(Vds)
    qossFunc.grid = converter.Qgrid.Qoss;
    qossFunc.bat = converter.Qbat.Qoss;
    % Unpack Rdson(Tj)
    Rdson.grid = converter.Qgrid.Rdson;
    Rdson.bat = converter.Qbat.Rdson;
    % Unpack Vn at switching instances
    Vn.grid.hi = OPsol.Vn(1)*converter.T.N;
    Vn.grid.lo = OPsol.Vn(gridLoOnIdx)*converter.T.N;
    Vn.bat.hi =  OPsol.Vn(batHiOnIdx);
    Vn.bat.lo =  OPsol.Vn(batLoOnIdx);
    %%
    % Loop for side (grid/bat) and level (hi,lo), and version
    for fside_cnt = 1:numel(fn_side)
        side = fn_side{fside_cnt};
        [Eoss.(side), Qoss.(side), Vds_vec.(side)] = eossQossVds(Vds.(side),qossFunc.(side));
            for same = 1:numel(fn_level)
            % To distinguish between turning on/off
                if fn_level{same} == "hi"
                    opposite = "lo";
                else
                    opposite = "hi";
                end
                
                lvl = fn_level{same};
                % Turn on Power & Vrem:
                [Pon.(side).(lvl), Vrem.(side).(lvl)] = switchingLosses(fn_level{same},Vds_vec.(side), Eoss.(side),Qoss.(side),[n_par.(side).(lvl), n_par.(side).(opposite)],Isw.(side).(lvl),L.(side),Vn.(side).(lvl), deltaT,converter.fsw);
                % Thermal Part
                [Tj.(side).(lvl), Ploss.(side).(lvl)] = junctionTemp(Irms.(side).(lvl),RthJA.(side),Pon.(side).(lvl),Rdson.(side),converter.Ta);
                % Efficiency
                efficiency.(side).(lvl) = 1 - Ploss.(side).(lvl)/(OPsol.Io *OPsol.Vo);
            end
    end 
    efficiency.tot =  efficiency.grid.hi +   efficiency.grid.lo +  efficiency.bat.hi +  efficiency.bat.lo - 3; %  sum(effMatrix) - (length(effMatrix) - 1)
    %
    %% Output
    lossStruc.Tj = Tj;
    lossStruc.Isw = Isw;
    lossStruc.Irms = Irms;
    lossStruc.Vrem = Vrem;
    lossStruc.Pon = Pon;
    lossStruc.Ploss = Ploss;
    lossStruc.Vn = Vn;
    lossStruc.efficiency = efficiency;

%       [Ponbatlo, Vrembatlo] = switchingLosses('lo',Vds_vec.bat, Eoss.bat,Qoss.bat,[n_par.bat.lo, n_par.bat.hi],Isw.bat.lo,L.bat,Vn.bat.lo, deltaT,converter.fsw);
end