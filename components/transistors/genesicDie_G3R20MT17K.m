%% Grid Side Transistors
% 1700V 20mOhm MOSFET - GeneSiC

%% Rdson(Tj)

p1 =   5.175e-07;
p2 =   4.475e-05;
p3 =     0.01607;

Rdson = @(Tj) (p1.*Tj.^2 + p2.*Tj + p3);
%% Qoss(Vds) 

a =   2.008e-09;
b =     -0.1845;
c =  -1.147e-10;

Qoss = @(Vds) a/(b+1)*Vds^(b+1)+c*Vds;
%% RthJC
RthJC =  0.20;      % [K/W] Thermal Resistance Junction to Case


%% save
save('components/transistors/genesicDie_G3R20MT17K.mat')