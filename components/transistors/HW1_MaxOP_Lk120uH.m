%%% Define Possible OPs

clear all
%% Load Circuit Parameters
% 
% build = "HW1";      % Specify build
% buildName = append("Parameters/",build,"_Parameters.m");
% run(buildName)

N = 12/18;
Lk1 = 5e-6;
Lk = Lk1/N^2;

%% 

% Circuit Parameters
Vi = [200:100:800];
Vclamp = Vi.*1/N;
Ts = 1/40e3;

% Control Parameters
phi = 1/4;  % Maximum phaseshift
D_max = 0.85; % Arbitrarily chosen maximum duty cycle

% Output Parameters:
Vo_max = D_max.*Vclamp' % Maximum possible output voltage

for n = 1:length(Vi)
    Vo(n,:) = 100:(Vo_max(n)-100)/150:Vo_max(n);
end

%%
hold on
 for n = 1:length(Vi)
    Io_max(n,:) = (-4*(abs(Vo_max(n)./Vclamp(n)-0.5))+4).*Vi(n).^2./(Lk*N^2)*(1/4-0.5*phi)*((phi)*Ts)./Vo(n,:);

    % Plot
    plot(Vo(n,:),Io_max(n,:));
    ViLgd(n) = "V_{in} =  " + num2str(Vi(n)) + " V";
 end
grid on
ylabel("Maximum Output Current [A]")
ylim([0,15])
yticks([0:1:15])

xlabel("Output Voltage [V]")
xlim([100, 920])
legend(ViLgd,'Location','southeast')

title("Maximum Operating point with Lk = " + num2str(Lk1*1e6) + "\muH")
hold off
