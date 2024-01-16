function [P_on, Vrem] = switchingLosses(side,Vds_vec, Eoss_Vds, Qoss_Vds, n_par, iL0, L, Vn, deltaT,fsw)
% SWITCHINGLOSSES [P_on, Vrem] = switchingLosses(Vds_vec, Eoss_Vds, Qoss_Vds, n_par, isw, L, Vn)
% Calculates the switching losses, aw well as remaining voltage across a partially hard
% switched transistor in a half bridge leg. 
%
% INPUTS:
%
% side: Defines whether high or low side transistor is turned on. string:
% high/hi/top for high-side transistor, low/lo/bot/bottom for low side
% transistor. Boolean: 1 for high, 0 for low
%
% Vds_vec: includes a vector with the different Vds voltages for which Qoss and Eoss are
% evaluated, from 0V to Vds.
%
% Eoss_Vds: includes the energy stored in the output capacitance as a
% function of voltage (from 0V to Vds)
%
% Qoss_Vds: includes the charge stored in the output capacitance as a
% function of voltage (from 0V to Vds)
%
% n_par: should be a vector that contains the number of parallel devices:
% [n_par(device turning on), n_par(device turning off)] 
%
% iL0: is the inductor current at the begining of the switching transition.
%
% L: is the leakage inductance at the respective side of the transformer.
%
% Vn: is the voltage reflected by the transformer
%
% deltaT: is the switching transition period

%% Define some variables:
Td = deltaT;
 
n_on = n_par(1); 
n_off = n_par(2);


% Vds as constant
Vds = Vds_vec(end);

%% Input Parse: initial conditions
if isstring(side) == 1 || ischar(side) == 1
    % Adjust switching current depending on high or low-side turn on, to
    % keep isw definition constant (out of HB)
    if (side == "low") || (side == "lo") || (side == "bottom") || (side == "bot")
        % with isw defined as going out of HB, the sign of isw has to be
        % changed for low-side transistor turn on:
        i0 = -iL0;
        v0 = Vds;

    elseif (side == "high") || (side == "hi") || (side == "top")
        i0 = iL0;
        v0 = 0;
        
    else
        error(append("The string used for 'side' is invalid. Assign a proper string: ",newline,"high/hi/top for high-side transistor, low/lo/bot/bottom for low side transistor"))
    end

elseif side == 0 % Low-Side
    i0 = -iL0;
     v0 = Vds;
elseif side == 1 % High-side
    i0 = iL0;
    v0 = 0;
else
    error(append("The value used for 'side' is invalid. Assign  a proper value: ",newline," 1 for high-side transistor, 0 for low-side transistor"))
end

%% LC Resonance

% Create time vector
t = linspace(0,Td,numel(Vds_vec));
% % function y = linspace(a, b, n)
% % y = (b-a)/(n-1)*(0:n-1) + a;
% nVds = numel(Vds_vec);
% t = (Td)/(nVds-1)*(0:nVds-1);
% Charge equivalent capacitance (Cq = Qoss(V)/V)
Cq_eq = Qoss_Vds(1,end)/Vds;


% Governing equations Half Bridge (linear)

% Resonance frequency
w0 = sqrt(1/(L*sum(n_par)*Cq_eq));
% Function for current in inductor:
% i_eqHb = -i0*cos(w0*t) + K*sin(w0*t);
% % v_eqHb = -(v0-Vn)*sin(w0*t - pi/2) + i0*sqrt(L/(2*Cq_eq))*sin(w0*t) + Vn;
% % Current at the end of Td, to debug
% ifinal = i_eqHb(end);

% Which provides a charge QL during the dead time:
QL = 0; % Pre-define
K = (v0-Vn)/(sqrt(L/(sum(n_par)*Cq_eq)));
% If i(t) crosses 0 before Td, use as integration time
t0 = (atan(-i0/K) + pi)/w0;
if t0 < Td
    tInt = t0;
else
    tInt = Td;
end
QL = -(i0/w0)*sin(w0*tInt) - K/w0*(cos(w0*tInt) - 1);
% i_eqHb = -i0*cos(w0*t) + K*sin(w0*t);

% Now we want to find, where the voltage will end up if QL is provided:
% charge required to change voltage by increment
dQ = diff(Qoss_Vds(1,:));
Qtrans = cumsum(dQ*n_off + flip(dQ)*n_on); % charge required to charge/discharge Coss per voltage increment (add parallel devices)
% Find intersect

%     figure
%     plot((Vds_vec(2:end)),Qtrans)
%     hold on
%     yline(QL) % Where line crosses, Vrem
%     hold off

% When QL provided by the inductor is equal to the cummultative charge
% in Qtrans, the voltage is changed across the transistor accordingly.
% 
% Find intersection (first element, where QL is smaller)
Vrem_idx = numel(Vds_vec) - find(QL < Qtrans,1);
% In case QL is lower than the minimum charge to change the voltage by dV,
% the remaining voltage will be Vds (-1dV to make sense of indices later).

% If no element is found where QL is smaller than Qtrans, QL is big enough
% to discharge the capacitors completely, and Vrem will be 0V.
if isempty(Vrem_idx) == 1
    Vrem_idx = 1;
end
Vrem = Vds_vec(Vrem_idx);

    %% Incomplete Soft Switching - Dissipated Energy in Coss
    %Vrem_idx = 1:length(Vds_vec)-1;
    % Energy Before Turn on:
%     E0_iZVS = n_off*Eoss_Vds(1,end-Vrem_idx) +  n_on*Eoss_Vds(1,Vrem_idx);
%     
%     % Energy After Turn on:
%     Efin_iZVS = n_off*Eoss_Vds(1,end);
%     
%     % Remaining Charge to charge Coss from Vrem to Vds:
%     Qrem = n_off*(Qoss_Vds(1,end) - Qoss_Vds(1,end-Vrem_idx));
%     
%     % Which is delivered from source:
%     Edel_iZVS = Qrem*Vds;
%     
%     % Dissipated Energy of incomplete ZVS
%      Ediss_iZVS = E0_iZVS + Edel_iZVS - Efin_iZVS;
%     % Hard Switching (To be revised)
%     if Vrem_idx >= numel(Vds_vec)-1
%         Ediss_iZVS = Ediss_iZVS + Vds*isw*19e-9; % 19ns from data sheet somewhere
%     end
%     P_on = Ediss_iZVS*fsw;
   


 %% Energy Approach
    measuredFallTime = 10e-9;
    fallSteps = measuredFallTime*1e9;
    tFall = t(end) + linspace(0,measuredFallTime,13);
    vdsHard = linspace(Vrem,0,length(tFall));
    idsHard = -i0*sin(w0*tFall - pi/2) - (v0-Vn)/sqrt(L/(2*Cq_eq))*sin(w0*tFall);
    Ion = idsHard(1);
    if Vrem == 0
        EonHard = 0;
        Vrem = 1e-19;
    else
        %EonHard = 1e-9*trapz(abs(vdsHard).*abs(idsHard));
        EonHard = 0.5*abs(Vrem *  Ion)*measuredFallTime; % 13 ns
    end

    EonInductor = 0.5*measuredFallTime*(Ion)^2;
    
    Cer = 2/Vrem^2*Eoss_Vds(Vrem_idx)*n_on;
    
    
    EonCap = 1/2*Cer*Vrem^2;
    
    EonTot = EonHard - EonInductor + EonCap;
    P_on = EonTot*(EonTot>0)*fsw;


end