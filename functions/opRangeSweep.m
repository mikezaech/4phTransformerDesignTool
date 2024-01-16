function [OPsol, transformerAnalysis, lossStruc, Io, Vo] = opRangeSweep(converter,IoRange,VoRange,Pmax,nIo,nVo)
% OPRANGEANALYSIS
% Solve current fed push pull converter at defined operating range.
% Generates a NxM matrix of points defined in the output voltage range
% Calculates current & voltages in circuit & calculates conduction and
% switching losses.
%    
    % Sweep  Range    
    IoStep = (IoRange(2) - IoRange(1))/(nIo - 1);    
    VoStep = (VoRange(2) - VoRange(1))/(nVo - 1);
    
    Io = [IoRange(1):IoStep:IoRange(2)];
    Vo = [VoRange(1):VoStep:VoRange(2)]';
    
    % Analysis
    for v_cnt = 1:numel(Vo)
        for i_cnt = 1:numel(Io)
            Vo_op = Vo(v_cnt);
            Io_op = Io(i_cnt);
            % Ignore P > Pmax
            if Vo(v_cnt)*Io(i_cnt) > Pmax
                Vo_op = 1;
                Io_op = 1;
            end
            % Check transformer configuration
            if contains(converter.T.config,'4ph')
                OPsol(v_cnt,i_cnt) = cfpp_4phSolve(converter,Vo_op,Io_op);
            elseif contains(converter.T.config,'2x2')
                OPsol(v_cnt,i_cnt) = cfpp_2x2phSolve(converter,Vo_op,Io_op);
            elseif contains(converter.T.config,'2ph')
                 OPsol(v_cnt,i_cnt) = cfpp_2phSolve(converter,Vo_op,Io_op);
            else 
                error('Transformer configuration not defined correctly in main file.')
            end
            transformerAnalysis(v_cnt,i_cnt) = transformerAnalyzer(converter,OPsol(v_cnt,i_cnt));
            lossStruc(v_cnt,i_cnt) = pushPullTransistorLossAnalysis(converter,OPsol(v_cnt,i_cnt));
        end
    end

end