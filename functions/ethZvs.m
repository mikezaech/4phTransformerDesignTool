function [P_on, Vrem, Td_min] = ethZvs(Vds_vec, Eoss_Vds, Qoss_Vds, n_par, isw, L, Vn, deltaT,fsw)

Vds = Vds_vec(end);
% Equivalent Capacitances
Cq_eq = Qoss_Vds./Vds_vec; % Charge Equivalent Capacitance
%     figure
%     semilogy(Vds_vec,Cq_eq)
%     hold on
%     semilogy(Vds_vec,Ce_eq)
%     grid on
%% Energy Balance
% E0 + Edel = Efin + Ediss
% Initial Energy

E0 = Eoss_Vds(end) + 0.5*L*isw^2;

% ZVS boundary (current is 0A at turn on)
Efin = Eoss_Vds(end);

% Energy Recieved by source during transition
Edel = -Qoss_Vds(end)*Vds_vec(end);

% Minimum current for ZVS:
i_zvs = -sqrt(2*Cq_eq(end)*Vds^2/L);

% Minimum dead time for ZVS at OP
Td_min = -2*Cq_eq(end)*Vds/(i_zvs);
%% Incomplete Soft Switching - Find Remaining Voltage
% Efin = Eoss(Vds - dV) + Eoss(dV)
% Edel = -Qoss(Vds) - Qoss(dV))*Vds
% E0 + Edel = Efin + Ediss

% Final Energy
Efin_incomplete = flip(Eoss_Vds(1,1:end)) + Eoss_Vds(1,1:end);
% Delivered Energy
Edel_incomplete = -(Qoss_Vds(end) - Qoss_Vds(1:end)).*Vds;


% Find intersection of Energy Balance
    Vrem_idx = 1;
for n = 1:length(Vds_vec)
    if E0 + Edel_incomplete(n) == Efin_incomplete(n)
        Vrem_idx = n;
        break
    elseif E0 + Edel_incomplete(1) < Efin_incomplete(1) && E0 + Edel_incomplete(n) > Efin_incomplete(n)
        Vrem_idx = n;
        break
    elseif E0 + Edel_incomplete(1) > Efin_incomplete(1) && E0 + Edel_incomplete(n) < Efin_incomplete(n)
        Vrem_idx = n;
        break
    end
end
% Remaining Voltage


if isw >= 0
    Vrem = Vds;
else
    Vrem = Vds_vec(Vrem_idx);
end
%% Incomplete Soft Switching - Dissipated Energy in Coss
%Vrem_idx = 1:length(Vds_vec)-1;
% Energy Before Turn on:
E0_iZVS = Eoss_Vds(end-Vrem_idx+1) +  Eoss_Vds(Vrem_idx);

% Energy After Turn on:
Efin_iZVS = Eoss_Vds(end);

% Remaining Charge to charge Coss from Vrem to Vds:
dQ = Qoss_Vds(end) - Qoss_Vds(end-Vrem_idx+1);

% Which is delivered from source:
Edel_iZVS = dQ*Vds;

% Dissipated Energy of incomplete ZVS
Ediss_iZVS = Efin_iZVS + Edel_iZVS - E0_iZVS;
P_on = Ediss_iZVS*fsw;

end