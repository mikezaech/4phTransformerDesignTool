%%% Calculate RMS Current through transistors
function [IQ1_rms, IQ2_rms, IQ9_rms, IQ10_rms] = transistorRmsCurrents(IgridIn,IbatIn,leakageVoltageMatrix,switchingInstances,C)

% Unpack  Converter Parameters
ph = C.ph;
fsw = C.fsw;
Ts = 1/fsw;



%% Set up variables
switching_sorted = leakageVoltageMatrix(1,:);
t = switching_sorted*Ts;
Igrid = IgridIn(1,:);
Ibat = IbatIn(1,:);
%% Grid side

% Top: Conducting when top gate is on
    Q1_on = switchingInstances(:,1)';
    Q1_onIdx = [find(switching_sorted == Q1_on(1),1);find(switching_sorted == Q1_on(2),1)];
    
    t_Q1 = t(Q1_onIdx(1):Q1_onIdx(2));
    I_Q1 = Igrid(Q1_onIdx(1):Q1_onIdx(2));
    I_Q1sqr = I_Q1.^2;
    
    % Integrate
    IQ1_integral = trapz(t_Q1,I_Q1sqr);
    IQ1_rms = sqrt(1/Ts*IQ1_integral);


%%
% Bot: conducting when topgate is off
    Q2_on = [switchingInstances(2,1),switchingInstances(1,1)+1];
    Q2_onIdx = [find(switching_sorted == Q2_on(1),1);find(switching_sorted == Q2_on(2),1)];
    
    t_Q2 = t(Q2_onIdx(1):Q2_onIdx(2));    
    I_Q2 = Igrid(Q2_onIdx(1):Q2_onIdx(2));
    I_Q2sqr = I_Q2.^2;
    
    % Integrate
    IQ2_integral = trapz(t_Q2,I_Q2sqr);
    IQ2_rms = sqrt(1/Ts*IQ2_integral);

%% Battery side

% Top: Conducting when top gate is on
    Q9_on = switchingInstances(:,ph+1)';
    Q9_onIdx = [find(switching_sorted == Q9_on(1),1);find(switching_sorted == Q9_on(2),1)];
    
    t_Q9 = t(Q9_onIdx(1):Q9_onIdx(2));    
    I_Q9 = Ibat(Q9_onIdx(1):Q9_onIdx(2));
    I_Q9sqr = I_Q9.^2;
    
    % Integrate
    IQ9_integral = trapz(t_Q9,I_Q9sqr);
    IQ9_rms = sqrt(1/Ts*IQ9_integral);

% Bot: Formula/conducting when topgate is off
    Q10_on =  [switchingInstances(2,ph+1),switchingInstances(1,ph+1)+1];
    Q10_onIdx = [find(switching_sorted == Q10_on(1),1);find(switching_sorted == Q10_on(2),1)];
    
    t_Q10 = t(Q10_onIdx(1):Q10_onIdx(2));    
    I_Q10 = Ibat(Q10_onIdx(1):Q10_onIdx(2));
    I_Q10sqr = I_Q10.^2;
    
    % Integrate
    IQ10_integral = trapz(t_Q10,I_Q10sqr);
    IQ10_rms = sqrt(1/Ts*IQ10_integral);
end