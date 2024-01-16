function Vn = transformerNeutralVoltage(leakageVoltageMatrix,switchingInstances,C,T)
% TRANSFORMERNEUTRALVOLTAGE
% Calculates the voltage at the neutral point of the multiphase
% transformer before the switching transition on both primary & secondary side. 
%
% OUTPUT is a 2x2 matrix, with the format:
% [Primary-Side High-Level , Secondary-Side High-Level Transistor;
%  Primary-Side Low-Level , Secondary-Side Low-Level Transistor]
%
% INPUT are the LEAKAGE VOLTAGE MATRIX (as seen from secondary side -
% legacy) , with switching times in the first row and the
% corresponding voltage across the leakage inductance on the secondary
% side, and SWITCHING INSTANCES with turn on time stamps of the switches in
% the first row, and turn off in the second row. 

% Define variables
% Unpack Converter Parameters
Vi = C.Vi;
ph = C.ph;

% Unpack Transformer
N = T.N;

Vlk = leakageVoltageMatrix;
switching = switchingInstances;

% Determine when Q1 (Primary, high level transistor) is on
Q1on = (Vlk(1,:) >= switching(1,1) & Vlk(1,:) < switching(2,1) )|(Vlk(1,:) >= switching(1,1)+1 & Vlk(1,:) < switching(2,1)+1 );
% Vn:
Vn_vec = Q1on*Vi + Vlk(2,:)*N;  % Multiplied by N, because Vlk is referred to the secondary side.

% Turn on instances
Q1TurnOn = find(switching(1,1)+1 == Vlk(1,:))-1;
Q2TurnOn = find(switching(2,1)+1 == Vlk(1,:))-1;

% 9 & 10 because it is written for 4 phase
Q9TurnOn = find(switching(1,1+ph)+1 == Vlk(1,:))-1;
Q10TurnOn = find(switching(2,1+ph)+1 == Vlk(1,:))-1;

VnQ1TurnOn = Vn_vec(Q1TurnOn);
VnQ2TurnOn = Vn_vec(Q2TurnOn);

VnQ9TurnOn = Vn_vec(Q9TurnOn)/N;
VnQ10TurnOn = Vn_vec(Q10TurnOn)/N;

% Output:
Vn = [VnQ1TurnOn, VnQ9TurnOn;...
    VnQ2TurnOn, VnQ10TurnOn];