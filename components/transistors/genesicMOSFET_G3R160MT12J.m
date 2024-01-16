%% Grid Side Transistors
% 1200V 160mOhm MOSFET - GeneSiC

%% Rdson(Tj)


p1 =   2.685e-06;
p2 =   -0.000255;
p3 =      0.1696;
Rdson = @(Tj) (p1.*Tj.^2 + p2.*Tj + p3);

%% Coss(Vds)

a =   5.712e-10;
b =     -0.5382;
c =   2.327e-12;
Coss = @(x)a*x^b+c;
%% Qoss(Vds) 

Qoss = @(Vds) a/(b+1)*Vds^(b+1)+c*Vds;
%% RthJC
RthJC =  1.16;      % [K/W] Thermal Resistance Junction to Case


%% save
save('components/transistors/genesicMOSFET_G3R160MT12J.mat')