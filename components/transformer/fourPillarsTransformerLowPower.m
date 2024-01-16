%%% Parameters of Four Pilars Transformer (1x4ph, Low Power Prototype)

% Turns Ratio
N = 12/18;
% Leakage Inductance (From Primary Side):
Lk1 = 5e-6;
Lk = Lk1/N^2; % Reflected, used for calculations
% Magnetizing Inductance:
Lm1 = 100e-6; % From Primary Side
Lm = Lm1/N^2; % Refelcted, used for calcualtions
%% save
save('components/transformer/fourPillarsLowPower.mat')