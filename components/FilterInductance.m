%%% Output Inductor Low Power Prototype
clear all

Ts = 1/40e3;        % Period Time
dT = Ts/8;          % Ripple Time 
Vo = 450;           % Output Voltage (at D = 0.375, when VL is biggest)
Vn = 560;           % Voltage at neutral tap of secondary side
VL = Vn - Vo        % Voltage across inductor

dI_max = 15*0.1;    % Maximum ripple current (10%)

L = VL/(dI_max*2)*dT % Required Output Inductance

%%
I = 4.75;
L = 115e-6;
dT = Ts/4
V = 580;
D = 0.6127
phi = 0.0027

DL05 = 0.5 + 0.125;



dI = (-122)/L*dT*((0.5 - (DL05 - D )*2))


%DL = 3.433e-6/dT

%% Determening  Voltage across inductor

% 1 Switching Period
D = 0.3002;
phi = 0.0117;
Ts = 2.5e-5;
ts_hi = D*Ts

% Period of inductor
TL = Ts/4;
tL_hi = 1.2584777770163758e-06; % time rising (from PLECS)
DL = tL_hi/Ts
tL_lo =  5.207509214733008e-06;
DL_lo = tL_lo/Ts


DL_calc = rem(D,0.25)

%% 

thi = 1.042e-6;
tL = 2.5e-5*0.25;
tlo = tL - thi;

dV = 250;

VL = dV/(1-tlo/thi)
%%

thi = 1.2585552150445878e-06;
tL = 2.5e-5*0.25;
tlo = tL - thi;

dV = 50;

VL = dV/(1-tlo/thi)

rem(1-D,0.25)*4*dV
