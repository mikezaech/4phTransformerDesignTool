%%% Find Switching Events & Voltage across leakage inductance 
% Input: Output Current, Output Voltage, Nr. of phases, Duty Cycle, Phase
% Shift
function Vlk_secOP = leakageVoltage(Io,Vo,D,phi,Vclamp,C,T)
% Unpack  Converter Parameters
Vi = C.Vi;
ph = C.ph;
% Unpack Transformer
N = T.N;


    priStart = [0:1/ph:(ph-1)/ph];  % Primary Switches turn on with 360/ph phase shift    
    for Vo_cnt = 1:length(Vo)    
        for Io_cnt = 1:length(Io)        
            
    
            secSwitch = D(Vo_cnt) + phi(Vo_cnt,Io_cnt);            % Switching Event of Secondary Switching (Phase-Shift)
            priEnd = priStart + D(Vo_cnt);
            secStart = priStart + phi(Vo_cnt,Io_cnt);      % Secondary Switches turn on with phi phase shift after primary
            secEnd = secStart + D(Vo_cnt);
    
            switching = [priStart;priEnd;secStart;secEnd];

            % Find when states change during period of interest
            changeIdx = 1;
            for ph_cnt = 1:ph
               for state_cnt = 1:4 
                    if switching(state_cnt,ph_cnt) > priEnd(1) && switching(state_cnt,ph_cnt) <= secEnd(1)
                        stateChange(changeIdx) = switching(state_cnt,ph_cnt);
                        stateChange = sort(stateChange);
                        changeIdx = changeIdx +1;
                    end
               end
            end     
           
            % Determine States of Switches:
            secState = zeros(length(stateChange),ph);         % Initialize States on Secondary
            priState = zeros(length(stateChange),ph);         % Initialize States on Primary

            for change_cnt = 1:length(stateChange)
                for ph_cnt = 1:ph
                    % States at end of switching
                    if secStart(ph_cnt) < stateChange(change_cnt) && stateChange(change_cnt) <= secEnd(ph_cnt)
                        secState(change_cnt,ph_cnt) = 1;
                    end
                    if priStart(ph_cnt) < stateChange(change_cnt) && stateChange(change_cnt) <= priStart(ph_cnt) + D(Vo_cnt)
                        priState(change_cnt,ph_cnt) = 1;
                    end
                end
                % Voltage across Lk connected to high:
                % Primary
                
                Vp_high(change_cnt,:) = ((ph-sum(priState(change_cnt,:)))/ph)*Vi;
                % Secondary
                Vs_high(change_cnt,:) = ((ph-sum(secState(change_cnt,:)))/ph)*Vclamp;
                % Voltage across leakage inductance is dependent on state of both primary
                % and secondary:             
                Vlk_sec(change_cnt,:) = Vs_high(change_cnt) - (1-secState(change_cnt,:))*Vclamp - (1/N)*(Vp_high(change_cnt) - (1-priState(change_cnt,:))*Vi);
                % Same But Reflected:
                %Vlk_pri(change_cnt,:) = Vp_high(change_cnt) - (1-priState(change_cnt,:))*Vi - N*(Vs_high(change_cnt) - (1-secState(change_cnt,:))*Vclamp);           
            end
            
            % Find average value of voltage across leakage inductance:
            d_tot = secEnd(1) - priEnd(1); % Total Period of Analysis
            d(1) = stateChange(1)-priEnd(1);
            V(1) = Vlk_sec(1,1);
            
            for cnt = 2:length(stateChange)
                d(cnt) = stateChange(cnt)-stateChange(cnt-1);
                V(cnt) = Vlk_sec(cnt,1);   
            end
            % Average Voltage Across Leakage Inductance       
            Vlk_secOP(Vo_cnt,Io_cnt) = 1/d_tot*sum(d.*V);  % At Operating point (Vo,Io)
            %Vlk_priOP(Vo_cnt,Io_cnt) = Vlk_secOP(Vo_cnt,Io_cnt).*N;  % At Operating point (Vo,Io)
            % Reset Temporary variables
            stateChange = []; Vp_high =  []; Vs_high =  []; Vlk_sec =  []; Vlk_pri =  []; d =  []; V =  [];               
        end
    end
end
