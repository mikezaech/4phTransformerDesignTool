function [Igrid, Isw_grid, Ibat, Isw_bat ] = transformerCurrents(Io,Vo, Vclamp, switchingInstances, leakageVoltageMatrix, C, T)

% Unpack Control Parameters
ph = C.ph;
fsw = C.fsw;
Ts = 1/fsw;

% Unpack Transformer
N = T.N;
Lk = T.Lk;
Lm = T.Lm;

    % Find Q9 & Q10 turn off (first transistors on secondary):
    %     Q9_off = switchingInstances(2,ph+1)+1;
    %     Q9_offIdx = find(leakageVoltageMatrix(1,:) == Q9_off,1);
    Qa2_off = [switchingInstances(1,ph+1)+1 switchingInstances(2,ph+1)+1];
    Qa2_offIdx = [find(leakageVoltageMatrix(1,:) == Qa2_off(1),1), find(leakageVoltageMatrix(1,:) == Qa2_off(2),1)];

    % Find Q1 & Q2 turn off:
    %     Q1_off = switchingInstances(2,1)+1;
    %     Q1_offIdx = find(leakageVoltageMatrix(1,:) == Q1_off,1);
    Qa1_off = [switchingInstances(1,1)+1 switchingInstances(2,1)+1];
    Qa1_offIdx = [find(leakageVoltageMatrix(1,:) == Qa1_off(1),1), find(leakageVoltageMatrix(1,:) == Qa1_off(2),1)];
    Vlk_array = leakageVoltageMatrix(:,1:Qa2_offIdx(2));

    %% Magnetizing Inductance 
    % Battery side voltage across magnetizing inductance:
    % Voltage when Q9 is on:
    VlmQ9on = Vclamp - Vo;
    % Voltage when Q9 is off:
    VlmQ9off = -Vo;
    Q9stateOn = (Vlk_array(1,:) >= switchingInstances(1,5) & Vlk_array(1,:) < switchingInstances(2,5)) + (Vlk_array(1,:) >= switchingInstances(1,5)+1 & Vlk_array(1,:) <= switchingInstances(2,5)+1);
    Q9stateOff = ~Q9stateOn;
    % Substract the leakage Voltage to get the waveform for Vlm:
    Vlm = (VlmQ9on*Q9stateOn + VlmQ9off*Q9stateOff) - Vlk_array(2,:);
    %% Add Time, find current:
    Vlk_time = [Vlk_array(1,:)*Ts; Vlk_array(2,:)];
    
    dT = diff(Vlk_time(1,:));
    VlkPeriod = Vlk_time(2,1:end-1);
    % From Leakage:
    dI = -VlkPeriod/Lk.*dT;

    % Magnetizing:
    dI_Lm = Vlm(1:end-1)/Lm.*dT;
    %% Average without starting point
    t = Vlk_time(1,:);
    % Current:
    i0 = 0;
    Ik = zeros(1,length(t));
    Ik(1) = i0;
    I_Lm = zeros(1,length(t));
    I_Lm(1) = i0;
    for cnt = 1:length(t)-1
        Ik(cnt+1) = Ik(cnt)+dI(cnt);
        I_Lm(cnt+1) = I_Lm(cnt) + dI_Lm(cnt);
    end
    % Find area below current for 1 period (Integral)
    Ik_integral = geoIntegral(Ik,dT,ph);
    ILm_integral = geoIntegral(I_Lm,dT,ph);

    % Mean value:
    I_avg = -Io/4;
    % Find initial value to achieve defined mean value:    
    I_avg_bat = 1/t(4*ph+1)*Ik_integral;
    i_intBat = I_avg - I_avg_bat;
    i_intGrid = -I_avg_bat/N;
    i_intLm = -1/t(4*ph+1)*ILm_integral;
    % Battery Side
    % Current:
    IbatTemp = zeros(1,length(t));
    IgridTemp = IbatTemp;
    ImagnetTemp = IbatTemp;
    IbatTemp(1) = i_intBat;
    IgridTemp(1) = i_intGrid;
    ImagnetTemp(1) = i_intLm;
    for cnt = 1:length(t)-1
        IbatTemp(cnt+1) = IbatTemp(cnt)+dI(cnt);
        IgridTemp(cnt+1) = IgridTemp(cnt)+dI(cnt)/N;
        ImagnetTemp(cnt+1) = ImagnetTemp(cnt) + dI_Lm(cnt);
    end
    Ibat = [IbatTemp-ImagnetTemp;t];
    Igrid = [IgridTemp;t];
    %Imagnet = [ImagnetTemp;t];
    %% Switching Current
    Isw_bat = Ibat(1,Qa2_offIdx);
    Isw_grid = -Igrid(1,Qa1_offIdx);
    
end
function integral = geoIntegral(a,dT,ph)
% Integral of a along dT time steps
    % Find area below current for 1 period (Integral)

    integralMatix = [a; 0, dT];
    x = zeros(1,4*ph+1);
    y = zeros(1,4*ph+1);
    for n = 2:4*ph+1
        y(n-1) = ((integralMatix(1,n) - integralMatix(1,n-1))/2 + integralMatix(1,n-1));
        x(n-1) = integralMatix(2,n);        
    end
    area = x.*y;
    integral = sum(area);
end