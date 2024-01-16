function [switchingInstances, leakageVoltageMatrix] = switchingMatrix(Vclamp,D,phi,C,T)
% SWITCHINGMATRIX  calculates parameters relating to switching
%   Returns normalised switching instances for alltransistors
%   and voltages on the leakage inductor between the switching instances

% Unpack Control Parameters
Vi = C.Vi;
ph = C.ph;

% Unpack Transformer
N = T.N;


    % Switching Instances High Side Transistors (On in first row, Off in second
    % row)
    switchingInstances = [(0:1/ph:(ph-1)/ph),(0:1/ph:(ph-1)/ph)+phi;(0:1/ph:(ph-1)/ph)+D,(0:1/ph:(ph-1)/ph)+phi+D];
    
    for n = 1:length(switchingInstances)
    % Find on-states at the beginning of each turn-on event
        % Phases which are on before switching event
        onBeforeOn(:,n) = (switchingInstances(1,n) >= switchingInstances(1,:)) | ((switchingInstances(1,n) + 1) <= (switchingInstances(2,:)));
        % Phases which turned off before switching event
        offBeforeOn(:,n) = switchingInstances(1,n) >= switchingInstances(2,:);
    
    % Find on-states at the end of each switching event (turn off)
        % Phases which are on before switching event
        onBeforeOff(:,n) = (switchingInstances(2,n) >= switchingInstances(1,:));
        % Phases which turned off before switching event    
        offBeforeOff(:,n) = switchingInstances(2,n) >= switchingInstances(2,:) & switchingInstances(2,n) < switchingInstances(1,:) + 1;
    end
    % When phase is turned on before, and has not turned off yet, it is on at
    % switching event
    
    turnOnStates = (onBeforeOn & ~offBeforeOn); % Array structure: columns - switching event for phases 1-8, rows - state of high side switch of respective phase
    priOnState = turnOnStates(1:ph,:);
    secOnState = turnOnStates(ph+1:end,:);
    
    turnOffStates = (onBeforeOff & ~offBeforeOff); % Array structure: columns - switching event for phases 1-8, rows - state of high side switch of respective phase
    priOffState = turnOffStates(1:ph,:);
    secOffState = turnOffStates(ph+1:end,:);
    
    %% Voltage across leakage inductance :
    
    for sw_cnt = 1:length(switchingInstances)
    % When phases turn on
        % Find nr. of on states on primary:
        NrOn(1,sw_cnt) = sum(priOnState(:,sw_cnt));
        % Find nr. of on states on secondary;
        NrOn(2,sw_cnt) = sum(secOnState(:,sw_cnt));
        % Find state of first & fifth phase:
        firstStateOn(sw_cnt) = priOnState(1,sw_cnt);
        fifthStateOn(sw_cnt) = secOnState(1,sw_cnt);
    
    % When phases turn off
        % Find nr. of on states on primary:
        NrOff(1,sw_cnt) = sum(priOffState(:,sw_cnt));
        % Find nr. of on states on secondary;
        NrOff(2,sw_cnt) = sum(secOffState(:,sw_cnt));
        % Find state of first & fifth phase:
        firstStateOff(sw_cnt) = priOffState(1,sw_cnt);
        fifthStateOff(sw_cnt) = secOffState(1,sw_cnt);    
    end
    
    % Voltage on one side of leakage inductance from primary and secondary side
    VpriOn = Vi*(ph-NrOn(1,:))/ph;
    VsecOn = Vclamp*(ph-NrOn(2,:))/ph;
    VpriOff = Vi*(ph-NrOff(1,:))/ph;
    VsecOff = Vclamp*(ph-NrOff(2,:))/ph;
    
    % Voltage across leakage during turn on:
    Vlk_on = VsecOn - (1 - fifthStateOn)*Vclamp - (1/N)*(VpriOn - (1 - firstStateOn)*Vi);
    % Voltage across leakage during turn off:
    Vlk_off = VsecOff - (1 - fifthStateOff)*Vclamp - (1/N)*(VpriOff - (1 - firstStateOff)*Vi);
    
    Vlk = [Vlk_on; Vlk_off];
    
    %% Arrange in Order
    % Modulate "switching" so that all values lie between 0 and 1
    mod = switchingInstances > 1;
    switchingMod = switchingInstances - mod;
    % Make arrays with time in first row and voltage in second row
    Vlk_arrayOn = [switchingMod(1,:); Vlk(1,:)];
    Vlk_arrayOff = [switchingMod(2,:); Vlk(2,:)];
    % Combine the two arrays
    Vlk_arrayComb = [Vlk_arrayOn, Vlk_arrayOff];
    
    % Sort according to time
    Vlk_arraySort = sortrows(Vlk_arrayComb')';
    
    Vlk_arrayTwo = [Vlk_arraySort(1,:) + 1; Vlk_arraySort(2,:)];
    % Extend to two periods
    leakageVoltageMatrix = [Vlk_arraySort Vlk_arrayTwo];

        % If duty cycle becomes too large
    if switchingInstances(2,5) > 1
       leakageVoltageMatrix2(:,:) = [leakageVoltageMatrix(1,:), leakageVoltageMatrix(1,end/2:end)+1;...
                                    leakageVoltageMatrix(2,:), leakageVoltageMatrix(2,end/2:end)];
       leakageVoltageMatrix = leakageVoltageMatrix2;
    end
end