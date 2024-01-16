function [iLim, vLim] = outputOpRange(IoRange,VoRange,Pmax)
% OUTPUTOPRANGE

    nStep = 500;
    Vstep = (VoRange(2) - VoRange(1))/(nStep-1);
    V_vals = [VoRange(1):Vstep:VoRange(2)];
    Istep = (IoRange(2) - IoRange(1))/(nStep-1);
    I_vals = [IoRange(1):Istep:IoRange(2)];
    
    %% Lower Edges
    
    V_min = min(V_vals)*ones(1,length(I_vals));
    I_min = min(I_vals)*ones(1,length(V_vals));
    
    %% Power Limit 
    
    v_cnt = 1;
    Icri_idx = find(I_vals > Pmax/V_vals(end),1);
    Icri = I_vals(Icri_idx:end);
    
    for i_cnt = length(I_vals):-1:Icri_idx
    
       Vcri_idx(v_cnt) =  find(V_vals > Pmax/I_vals(i_cnt),1);
       Vcri(v_cnt) = V_vals(Vcri_idx(v_cnt));
       v_cnt = v_cnt + 1;
    
    end
    Vcri = flip(Vcri);
    %% Upper Edges
    
    V_max = V_vals(end)*ones(1,Icri_idx);
    I_max = I_vals(end)*ones(1,Vcri_idx(1));
    
    %% Path along edge
    % Starting at maximum current, increasing to max power, max voltage, min
    % current
    
    iLim = [I_max, flip(Icri),I_vals(Icri_idx:-1:1)];
    vLim = [V_vals(1:Vcri_idx(1)),flip(Vcri),V_max];
end