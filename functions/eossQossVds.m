function [E, Q, Vds_vec] = eossQossVds(Vds,qossFunc)
% Returns vector of Eoss(Vds) & Qoss from 0V to Vds, with Eoss in first and Vds in
% second row
    % Steps in Vds
    Vstep = Vds/10000;
    Vds_vec = 0:Vstep:Vds;
    for n = 1:length(Vds_vec)
        Qoss_Vds(n) = qossFunc(Vds_vec(n));
    end

    % Integrate Qoss dq to find Eoss
    Eoss_Vds = cumtrapz(Qoss_Vds,Vds_vec);
    E = [Eoss_Vds];
    Q = [Qoss_Vds];
end