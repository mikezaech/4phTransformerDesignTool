function smokeOnTheWater 
%%Time specifications:
       Fs = 13000;                   % samples per second
       dt = 1/Fs;                   % seconds per sample
       StopTime = 0.25;             % seconds
       t = (0:dt:StopTime-dt)';     % seconds
    
    E = 2*pi*329.63;
    E5	= 2*pi*659.25;
    G = 2*pi*392;
    C5 = 2*pi*523.25;
    A = 2*pi*440;
    D5 = 2*pi*587.33;
    B = 2*pi*493.88;
    
    
    
    sotw = 1.1*[sin(E*t)+ sin(A*t); sin(G*t)+ sin(C5*t); sin(A*t)+ sin(D5*t); sin(A*t)+ sin(D5*t);...
        sin(E*t)+ sin(A*t); sin(G*t)+ sin(C5*t); sin(B*t(1:end/2))+ sin(E5*t(1:end/2)); sin(A*t)+ sin(D5*t);sin(A*t(1:end/2))+ sin(D5*t(1:end/2));...
        sin(E*t)+ sin(A*t); sin(G*t)+ sin(C5*t); sin(A*t)+ sin(D5*t); sin(A*t)+ sin(D5*t);...
         sin(G*t)+ sin(C5*t);sin(E*t)+ sin(A*t);sin(E*t)+ sin(A*t);sin(E*t)+ sin(A*t);];
    t_tot = (0:dt:16*StopTime-dt)';
    % plot(t_tot,sotw)
    %    xlabel('time (in seconds)');
    %    title('Signal versus Time');
    
    sound(sotw)
end