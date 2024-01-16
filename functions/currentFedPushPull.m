function S = currentFedPushPull(C,Qgrid,n_parGrid,T,Qbat,n_parBat,Vo,Io,RthCA, Ta,  dV, Lau)
% CURRENTFEDPUSHPULL
% 4-phase current fed push pull converter analysis
% Inputs:
% C: Converter Parameters (Input Voltage Vi, Nr. of phases ph, Switching Frequency fsw, Dead Time Td)
% Qgrid: Grid-side Transistor Data (Rdson(Tj), Qoss(Vds), RthJC)
% n_parGrid: Number of Parallel Devices Grid Side [hi, lo]
% T: Transformer Data (N, Lk(bat), Lm(bat))
% Qbat: Battery-side Transistor Data (Rdson(Tj), Qoss(Vds), RthJC)
% n_parBat: Number of Parallel Devices Battery Side [hi, lo]
% Vi: Input voltage (Grid side)
% Vo: Output voltage (operating point)
% Io: Output Current
% RthCA: Case to Ambient Thermal Resistance
% Ta: Ambient Temperature
% OPTIONAL
% dV: Clamp control (Reduced by dV)
% Lau: Auxiliary Inductor on battery side HB's

%% Input Parse
% TODO

%% Unpack Input Variables
% Unpack  Converter Parameters
Vi = C.Vi;
ph = C.ph;
fsw = C.fsw;
Td = C.Td;
Ts = 1/fsw;

% Unpack Transformer
N = T.N;
Lk = T.Lk;
Lm = T.Lm;

% Unpack Qgrid:
Rdson.grid = Qgrid.Rdson;
qossFunc.grid = Qgrid.Qoss;
RthJC.grid = Qgrid.RthJC;

% Unpack Qbat:
Rdson.bat = Qbat.Rdson;
qossFunc.bat = Qbat.Qoss;
RthJC.bat = Qbat.RthJC;


%% Parameters

Vclamp = Vi/N - dV;

% Duty Cycle
D = Vo/Vclamp; 
D = D + (1e-6*(rem(D,0.25)==0)); % Small Hack to avoid 25%, 50% and 75% Duty Cycle

%% Solve for phase shift at operating point, get voltages and currents
OPsol = currentFedPushPullSolve(converter,Vo,Io);

%% Current Contribution from Clamp Voltage Control

% Eq (12):
dutyLo = D < 0.5;
dutyHi = D >= 0.5;
dV_dutyFactor2 = (D + 0.5).*dutyLo + (1.5 - D).*dutyHi;  

dIv = (1/8)*dV/Lk*dV_dutyFactor2*Ts;

%%  Switching Currents in Transistors
% % Find Switching Instances (Turn On & Turn Off) & Voltage across
% % leakage Inductance:
% D = 500/1200; % Duty Cycle determine by outbut voltage
% % syms phi % phase shift unknown
% phi = 0.0112;
% [switchingInstances, leakageVoltageMatrix] = switchingMatrix(Vclamp,D,phi,C,T);


% Find Transformer Currents & Switching Currents:
[Igrid, IswGridTemp, Ibat, IswBatTemp] = transformerCurrents(Io, Vo, Vclamp, switchingInstances,leakageVoltageMatrix, C, T);
%

Isw.grid.hi = -IswGridTemp(1);
Isw.grid.lo = IswGridTemp(2);
%
Isw.bat.hi = -IswBatTemp(1);
Isw.bat.lo = IswBatTemp(2);

% Find Neutral Voltage of Transformer:
VnTemp = transformerNeutralVoltage(leakageVoltageMatrix,switchingInstances,C,T);
%
Vn.grid.hi = VnTemp(1,1);
Vn.grid.lo = VnTemp(2,1);
%
Vn.bat.hi = VnTemp(1,2);
Vn.bat.lo = VnTemp(2,2);
        
%% Auxiliary Inductor
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
    sw = leakageVoltageMatrix(1,1:length(Ibat(1,:)))';
    topOn1 = (sw <= D);
    topOff1 = (sw > D) .* (sw <= 1);
    
    topOn2 = (sw > 1).*(sw <= D +1);
    topOff2 = (sw > D +1);

    ILau = (0.5* dI_Lau - dI_Lau/D * sw).*topOn1...
           + (-0.5* dI_Lau + dI_Lau/(1-D) * (sw-D)).*topOff1...
           + (0.5* dI_Lau - dI_Lau/D * (sw-1)).*topOn2...
           + (-0.5* dI_Lau + dI_Lau/(1-D) * (sw-D-1)).*topOff2;


    Ibat(1,:) = Ibat(1,:) + ILau';
    Ibat(2,:) = Ibat(2,:);
    

    % Update switching current
    Isw.bat.hi = Isw.bat.hi - 0.5*dI_Lau';
    Isw.bat.lo = Isw.bat.lo - 0.5*dI_Lau';
end

% Calculate RMS Currents
[Irms.grid.hi, Irms.grid.lo, Irms.bat.hi, Irms.bat.lo] = transistorRmsCurrents(Igrid,Ibat,leakageVoltageMatrix,switchingInstances,C);

% Average Voltage Across leakage inductance
Vlk.bat = leakageVoltage(Io,Vo,D,phi,Vclamp,C,T);

% Average Voltage across leakage inductance grid side:
Vlk.grid = Vlk.bat./N;
% Adjust Transistor Currents according to nr. of parallel devices
Irms.grid.hi = Irms.grid.hi/n_parGrid(1);
Irms.grid.lo = Irms.grid.lo/n_parGrid(2);
Irms.bat.hi = Irms.bat.hi/n_parBat(1);
Irms.bat.lo = Irms.bat.lo/n_parBat(2);



%% Minimum current to assure ZVS under the effect on dead time
% ZVS Surface Current:

phi_cri = Td/Ts;             % If PS is smaller than phi_cri, it becomes a limiting factor for ZVS

if phi < phi_cri
    deltaT = phi*Ts;
else 
    deltaT = Td;
end       

%% ZVS Conditions: Calculating Vrem
% Field Names:
fn_side = fieldnames(Irms);
fn_level = fieldnames(Irms.grid);
% Defining useful variables
n_par.grid.hi = n_parGrid(1);
n_par.grid.lo = n_parGrid(2);
n_par.bat.hi = n_parBat(1);
n_par.bat.lo = n_parBat(2);
%
L.bat = Lk;
L.grid = Lk*N^2;
%
Vds.grid = Vi;
Vds.bat = Vclamp;


% Junction to Ambient Thermal Resistance
RthJA.grid = Qgrid.RthJC + RthCA;
RthJA.bat = Qbat.RthJC + RthCA;

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
            [Pon.(side).(lvl), Vrem.(side).(lvl)] = switchingLosses(fn_level{same},Vds_vec.(side), Eoss.(side),Qoss.(side),[n_par.(side).(lvl), n_par.(side).(opposite)],Isw.(side).(lvl),L.(side),Vn.(side).(lvl), deltaT,fsw);
            % Thermal Part
            [Tj.(side).(lvl), Ploss.(side).(lvl)] = junctionTemp(Irms.(side).(lvl),RthJA.(side),Pon.(side).(lvl),Rdson.(side));
        end
end 



%% Output
S.Tj = Tj;
S.Isw = Isw;
S.Irms = Irms;
S.Vrem = Vrem;
S.Pon = Pon;
S.Ploss = Ploss;
S.Vn = Vn;

%% Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%
 % Phi Adjustment
 function phi_new = phi_adjust(phi,Io,Vo)
 phi_new = zeros(size(phi));
    for n = 1:length(Vo)
        if (Vo(n)) < 300
            x = Vo(n);
            K = Io/15;
        
               a1 =    0.001512;
               b1 =     0.00448;
               c1 =      -2.087;
               a2 =   0.0008051;
               b2 =    0.008146;
               c2 =     -0.9721;
               a3 =   0.0001523;
               b3 =     0.01703;
               c3 =       2.323;
               a4 =   4.554e-05;
               b4 =     0.03571;
               c4 =       2.844;
        
           adjustment = K.*(a1*sin(b1*x+c1) + a2*sin(b2*x+c2) + a3*sin(b3*x+c3) + a4*sin(b4*x+c4));
           phi_new(n,:) = phi(n,:) - adjustment;
        % Goodness of fit:
        %   SSE: 4.822e-07
        %   R-square: 0.9974
        %   Adjusted R-square: 0.9974
        %   RMSE: 2.634e-05
        
        else
            phi_new(n:end,:) = phi(n:end,:);
            break
        end
    end
 end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [Tj, Ploss] = junctionTemp(I,RthJA,Psw,Rdson)
    %global Ta 
    % To calculate steady state temperature for the transistor at a given RMS
    % current
    T0 = Ta;                    % degC, initial temperature
    Tmax = 175;                 % degC, maximum temperature
    dT_min = 0.1;               % degC, minimum temperature increase before algorithm is terminated
    [n_vol, n_cur] = size(I);    % How many Operating Points to  analyze    
    Tj = T0*ones(n_vol,n_cur);
    
    % Iterate through all voltages
    for m = 1:n_vol
        % Iterate through all currents
        for n = 1:n_cur    
            Tk = T0;                % Initialize current temperature
            dT = 1000;              % Initialize temperature increase
            % Convergence criteria
            while Tk < Tmax && dT > dT_min
                Tk_0 = Tk;          % Set temperature from previous iteration
                % Calculate current junction temperature
                P = (Rdson(Tk_0)*I(m,n)^2 + Psw(m,n));
                Tk = P * (RthJA) + Ta;
                dT = Tk - Tk_0;
            end
            Ploss = P(m,n);
            Tj(m,n) = Tk;
            deltaTemperature(m,n) = dT;
        
            % Stop if Tj exceeds limit
%             if Tj(m,n) > Tmax
%                 %Tj(m,n:end) = inf;
%                 %break
%             end        
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Eoss&Qoss Vectors
function [E, Q, Vds_vec] = eossQossVds(Vds,qossFunc)
% Returns vector of Eoss(Vds) & Qoss from 0V to Vds, with Eoss in first and Vds in
% second row
    % Steps in Vds
    Vstep = Vds/10000;
    Vds_vec = 0:Vstep:Vds;
    for n = 1:length(Vds_vec)
        Qoss_Vds(n) = qossFunc(Vds_vec(n));
    end

    % Integrate Qoss dq to find Eoss
    Eoss_Vds = cumtrapz(Qoss_Vds,Vds_vec);
    E = [Eoss_Vds];
    Q = [Qoss_Vds];
end


end