function T = transformer(n,Lk_primary,Lm_primary,config)
% TRANSFOMER is used to generate a struct with transformer parameters
% n: Number of windings [n1,n2]
% Lk: Leakage inductance (Primary)
% Lm: Magnetizing inductance (reflected onto secondary side!)
% config: Configuration (4ph or 2x2
    T.Npri = n(1);
    T.Nsec = n(2);
    N = n(1)/n(2);
    T.N = N;
    T.Lk = Lk_primary/N^2; % reflected onto secondary side!
    T.Lm = Lm_primary/N^2; % reflected onto secondary side!
    T.config = config;
    T.Lk_primary = Lk_primary;
    T.Lm_primary = Lm_primary;
end