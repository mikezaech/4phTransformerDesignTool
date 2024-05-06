function transformerAnalysis = transformerAnalyzer(converter,OPsol)
    Vpri = OPsol.Vpri;
    Vsec = OPsol.Vsec;
    %
    Ipri = OPsol.Ipri;
    Isec = OPsol.Isec;
    Ilm = OPsol.IlmSec;
    %
    Npri = converter.T.Npri;
    Nsec = converter.T.Nsec;
    Lm = converter.T.Lm;
    Ac = converter.T.design.Ac;  %Core cross-section
    k = converter.T.design.k;
    a = converter.T.design.a;
    b = converter.T.design.b;
    MWL = converter.T.design.MWL; % [m], Mean Winding Length (approximately A4 perimeter)
    Rwinding_pri =   converter.T.Rwinding_pri;
    Rwinding_sec =  converter.T.Rwinding_pri;
    %
    time = OPsol.t;
    % Volt Second Balance
   
    % find half period
    t_half = 0.5/converter.fsw;
    t_halfIdx = find(time == t_half);

    VoltSecond_pri = sum(diff(time(1:t_halfIdx+1)).*Vpri(1:t_halfIdx));
    VoltSecondsec_sec = sum(diff(time(1:t_halfIdx+1)).*Vsec(1:t_halfIdx));
       
    % Voltage Peak 
    Vpri_pk = max(abs(Vpri));
    Vsec_pk = max(abs(Vsec));
    
    % RMS Current    
    % Add zero crossings
    [Ipri_ZC_time,Ipri_ZC] = addZeroCrossing(time,Ipri);
    [Isec_ZC_time,Isec_ZC] = addZeroCrossing(time,Isec);

    IpriRms = sqrt(converter.fsw * trapz([Ipri_ZC_time, 1/converter.fsw],[Ipri_ZC, Ipri_ZC(1)].^2));
    IsecRms = sqrt(converter.fsw * trapz([Isec_ZC_time, 1/converter.fsw],[Isec_ZC, Isec_ZC(1)].^2));
    
    % Core Losses
    % Bmax

    Bmax = max(Ilm)*Lm/(Npri*Ac);
    % Core parameters from https://www.netl.doe.gov/sites/default/files/netl-file/Core-Loss-Datasheet---MnZn-Ferrite---N87%5B1%5D.pdf

    Pcore = k*Bmax^b*converter.fsw^a;

    % Winding Losses
    Pw = IpriRms^2*Rwinding_pri + IsecRms^2*Rwinding_sec;

    % Struct
    transformerAnalysis.time = time;
    transformerAnalysis.Vpri = Vpri;
    transformerAnalysis.Vsec = Vsec;
    transformerAnalysis.Ipri = Ipri;
    transformerAnalysis.Isec = Isec;
    transformerAnalysis.VoltSecond_pri = VoltSecond_pri;
    transformerAnalysis.VoltSecondsec_sec = VoltSecondsec_sec;
    transformerAnalysis.Vpri_pk = Vpri_pk;
    transformerAnalysis.Vsec_pk = Vsec_pk;
    transformerAnalysis.IpriRms = IpriRms;
    transformerAnalysis.IsecRms = IsecRms;
    transformerAnalysis.Pcore = Pcore;
    transformerAnalysis.Pw = Pw;
    transformerAnalysis.Bmax = Bmax;
%     disp("blub")
end