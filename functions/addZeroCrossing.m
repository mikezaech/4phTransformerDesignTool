function [zeroCrossing_time,zeroCrossing_trace] = addZeroCrossing(time,trace)

    % Detect Sign Change
    signChangeIdx = find(abs(diff(sign(trace))) == 2); % The next value will have a different sign
    if isempty(signChangeIdx) == 0
        % Add zero crossing
        for n = 1:length(signChangeIdx)
            traceIdx = signChangeIdx(n);
            t0(n) = -trace(traceIdx)/((trace(traceIdx+1) - trace(traceIdx))/(time(traceIdx+1) - time(traceIdx)));
        end
        % add 0 to trace
        zeroCrossing_trace = [trace,zeros(1,length(t0))];
        % sort timestamps with zero crossings
        [zeroCrossing_time, sortIdx] = sort([time,t0]);
        % sort traces:
        zeroCrossing_trace = zeroCrossing_trace(sortIdx);
    else 
        zeroCrossing_time = time;
        zeroCrossing_trace = trace;
    end

end