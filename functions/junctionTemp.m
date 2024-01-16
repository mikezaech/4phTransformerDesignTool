    function [Tj, Ploss] = junctionTemp(I,RthJA,Psw,Rdson,Ta)
    %global Ta 
    % To calculate steady state temperature for the transistor at a given RMS
    % current
    T0 = Ta;                    % degC, initial temperature
    Tmax = 175;                 % degC, maximum temperature
    dT_min = 0.1;               % degC, minimum temperature increase before algorithm is terminated
    [n_vol, n_cur] = size(I);    % How many Operating Points to  analyze    
    Tj = T0*ones(n_vol,n_cur);
    
    % Iterate through all voltages
    for m = 1:n_vol
        % Iterate through all currents
        for n = 1:n_cur    
            Tk = T0;                % Initialize current temperature
            dT = 1000;              % Initialize temperature increase
            % Convergence criteria
            while Tk < Tmax && dT > dT_min
                Tk_0 = Tk;          % Set temperature from previous iteration
                % Calculate current junction temperature
                P = (Rdson(Tk_0)*I(m,n)^2 + Psw(m,n));
                Tk = P * (RthJA) + Ta;
                dT = Tk - Tk_0;
            end
            Ploss = P(m,n);
            Tj(m,n) = Tk;
            deltaTemperature(m,n) = dT;
        
            % Stop if Tj exceeds limit
%             if Tj(m,n) > Tmax
%                 %Tj(m,n:end) = inf;
%                 %break
%             end        
        end
    end
end