%% Grid Side Transistors
% 1700V 160mOhm MOSFET - GeneSiC

%% Rdson(Tj)

p1 =   4.814e-06;
p2 =   0.0002044;
p3 =     0.157;

Rdson = @(Tj) (p1.*Tj.^2 + p2.*Tj + p3);

%% Coss(Vds)
     
   a =   1.624e-09;
   b =     -0.6827;
   c =   2.264e-12;
   Coss = @(x) a.*x.^b+c
%% Qoss(Vds) 

a = 1.6235e-09;
b = -0.6827;
c = 2.2642e-12;
Qoss  = @(Vds)a./(b+1).*Vds.^(b+1)+c.*Vds;

%% RthJC
RthJC = 0.87;      % [K/W] Thermal Resistance Junction to Case


%% save
save('components/transistors/genesicMOSFET_G3R160MT17J.mat')