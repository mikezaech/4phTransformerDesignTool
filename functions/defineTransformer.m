function T = transformer(design,config)
% TRANSFOMER is used to generate a struct with transformer parameters

% design: [struct] includes parameters for design:
%                   N: Turns ratio
%                   N1: Primary Windings
%                   Lk_primary: Leakage inductance (Primary)
%                   Lm_primary: Magnetizing inductance (Primary)
%                   Ac = 0.06*0.1; % [m2] Core cross-section
%                   % Core parameters from https://www.netl.doe.gov/sites/default/files/netl-file/Core-Loss-Datasheet---MnZn-Ferrite---N87%5B1%5D.pdf
%                   k = 8.138e-6;
%                   a = 1.722;
%                   b = 2.0975;
%                   MWL = 1; % [m], Mean Winding Length (approximately A4 perimeter)
%                   Acu_pri = 55e-6; % [m2] Copper diameter, 6A/mm2, 340Arms max on pri
%                   Acu_sec = 42.5e-6; % 255 Arms max on sec
%                   rho = 1.77e-8; % resistivity of copper
% config: Configuration (4ph or 2x2)
    T.design = design;
    T.Npri = design.Npri;
    N = design.N;
    T.Nsec = T.Npri/N;
    T.N = N;
    T.Lk = design.Lk_primary/N^2; % reflected onto secondary side!
    T.Lm = design.Lm_primary/N^2; % reflected onto secondary side!
    T.config = config;
    T.Lk_primary =  design.Lk_primary;
    T.Lm_primary =  design.Lm_primary;
    T.Rwinding_pri = design.rho*T.Npri*design.MWL/design.Acu_pri;
    T.Rwinding_sec = design.rho*T.Nsec*design.MWL/design.Acu_sec;


end