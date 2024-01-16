%% Grid Side Transistors
% ONSEMI F2-Half Bridge SiC MOSFET Module NXH006P120MNF2PTG

%% Rdson(Tj)
p1 =   6.187e-10;
p2 =   -2.56e-08;
p3 =   2.253e-06;
p4 =     0.00543;

Rdson = @(Tj) (p1.*Tj.^3 + p2.*Tj^2 + p3*Tj + p4);
%% Qoss(Vds) 

a =   2.522e-08;
b =     -0.2339;
c =  -5.111e-09;

Qoss = @(Vds) a/(b+1)*Vds^(b+1)+c*Vds;
%% RthJC
RthJC = 0.1;      % [K/W] Thermal Resistance Junction to Case


%% save
save('components/transistors/onsemiHbSicModule_NXH006P120MNF2PTG.mat')