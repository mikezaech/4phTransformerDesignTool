clear 
close all
% 1200V 80mOhm MOSFET - Wolfspeed cree
% https://assets.wolfspeed.com/uploads/2020/12/C2M0080120D.pdf

model = "C2M0080120D";
datasheetURL ="https://assets.wolfspeed.com/uploads/2020/12/C2M0080120D.pdf";
%% Rdson(Tj)

p1 =   2.844e-06;
p2 =   8.898e-05;
p3 =     0.0778 ;

Rdson = @(Tj) (p1.*Tj.^2 + p2.*Tj + p3);

%% Coss(Vds)
% From Extraction:     
%    a =  1.602e-09;
%    b =    -0.3578;
%    c =   -6.432e-11;
% From datasheet
    a = 1.9130e-09;
    b = -0.5140;
    c = 2.1010e-11;
   Coss = @(x) a.*x.^b+c;

% % Alternative Form: a/((1 + x/b)^(1/2)) + c*x
%     a =  3.945e-09;
%     b = 0.3187;
%     c = 1.839e-14;
% Coss = @(x) a./((1 + x./b).^(1/2)) + c.*x;

% SiC Function:
       aSiC =   3.945e-09;
       bSiC =      0.3187;
       cSiC =   1.839e-14;
CossSiC = @(x)  aSiC./(1 + x./bSiC).^0.5 + cSiC.*x


%% Qoss(Vds) 
Qoss  = @(Vds)a./(b+1).*Vds.^(b+1)+c.*Vds;

 QossSiC = @(x) 2.*aSiC.*bSiC.*sqrt((bSiC + x)/bSiC) + cSiC.*x.^2./2;
%% RthJC
RthJC = 0.6;      % [K/W] Thermal Resistance Junction to Case


%% save
save('components/transistors/creeMOSFET_C2M0080120D.mat')