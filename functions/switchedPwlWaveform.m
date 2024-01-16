function [timestamp, switchedTrace]  = switchedPwlWaveform(trace,time,states)

    % Double switching events
    traceDoubled = [trace, trace(1); trace trace(1)];
    traceDoubled = traceDoubled(:)';

    timeDoubled = [time, 1; time, 1];   
    timestamp = timeDoubled(:)';
    
    statesDoubled = [states, states(1); states, states(1)];
    statesDoubled = statesDoubled(:)';
    statesDoubled = circshift(statesDoubled,1);
    
    switchedTrace = statesDoubled.*traceDoubled;
    

end