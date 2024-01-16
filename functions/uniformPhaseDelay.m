function phaseMatrix = uniformPhaseDelay(firstPhase,timeStampsNormalized,nrOfPhases)
    phaseMatrix(1,:) = firstPhase;
    for nPh = 2:nrOfPhases % Shift it by 1/nrOfPhases
           phIdx = find(timeStampsNormalized == (nPh - 1)/nrOfPhases);
           phaseMatrix(nPh,:) = circshift(firstPhase,phIdx-1);    
    end
end