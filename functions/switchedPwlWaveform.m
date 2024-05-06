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
    
    % Detect Sign Change
    signChangeIdx = find(abs(diff(sign(switchedTrace))) == 2); % The next value will have a different sign
    if isempty(signChangeIdx) == 0
        % Add zero crossing
        for n = 1:length(signChangeIdx)
            traceIdx = signChangeIdx(n);
            t0(n) = -switchedTrace(traceIdx)/((switchedTrace(traceIdx+1) - switchedTrace(traceIdx))/(timestamp(traceIdx+1) - timestamp(traceIdx)));
        end
        % add 0 to trace
        switchedTrace = [switchedTrace,zeros(1,length(t0))];
        % sort timestamps with zero crossings
        [timestamp, sortIdx] = sort([timestamp,t0]);
        % sort traces:
        switchedTrace = switchedTrace(sortIdx);
    end
    
    
end