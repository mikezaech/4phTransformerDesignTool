function out = two_by_two_phase_transformerDesign(input)
setWorkingDir
%% Unpack



%% Initialize
% pathName = setWorkingDir; % Set working directory to current folder and include subfolders


%% Define Converter:
% Converter Parameters:
converter.Vi = 800; % Input voltage
converter.ph = 4; % Nr. of phases
converter.fsw = 40e3; % switching frequency
converter.Td = 100e-9; % dead time

converter.Lo = 118e-6; % Outut filter Inductance
converter.dV = 0; % Clamp Voltage offset
converter.Lau = 0; % Auxiliary inductor

% Grid Side Transistor
converter.Qgrid = load("components\transistors\onsemiHbSicModule_NXH006P120MNF2PTG.mat"); % High Power
converter.n_parGrid = [1 1];

% Transformer Data
N = input.N;
N1 = input.N1;
trDesign.N = 2/3;
trDesign.Npri = 18;
trDesign.Lk_primary =  input.Lk;
trDesign.Lm_primary  = input.Lm;

trDesign.Ac = input.Ac; % [m2] Core cross-section
%                   % Core parameters from https://www.netl.doe.gov/sites/default/files/netl-file/Core-Loss-Datasheet---MnZn-Ferrite---N87%5B1%5D.pdf
trDesign.k = input.k;
trDesign.a = input.a;
trDesign.b = input.b;
trDesign.MWL = input.MWL; % [m], Mean Winding Length (approximately A4 perimeter)
trDesign.Acu_pri = input.Acu_pri; % [m2] Copper diameter, 6A/mm2, 340Arms max on pri
trDesign.Acu_sec = input.Acu_sec; % 255 Arms max on sec
trDesign.rho = 1.77e-8; % resistivity of copper
converter.T = defineTransformer(trDesign, '2x2'); % High Power, 2x2 optimized

% Battery Side Transistor
converter.Qbat = load("components\transistors\genesicDie_G3R20MT17K.mat"); % High Power
converter.n_parBat = [1 2];

% Thermal
converter.RthCA = 1.5;
converter.Ta = 40;
converter.TjLimit = 150;

% Clamp Voltage:
converter.Vclamp = converter.Vi/converter.T.N - converter.dV;

%% Operating Range
IoRange = [0.5,125];
VoRange = [200,920];
Pmax = 350e3/4;

%% Sweep Operating range
[OPsol, transformerAnalysis, lossStruc, Io, Vo] = opRangeSweep(converter,IoRange,VoRange,Pmax,10,10);

%% Analysis

% Losses 2x2ph
nrPh_2x2 = 4;
Psw1_2x2 = arrayfun(@(x) x.Pon.grid.hi,lossStruc);
Psw2_2x2 = arrayfun(@(x) x.Pon.bat.hi,lossStruc);
Psw3_2x2 = arrayfun(@(x) x.Pon.grid.lo,lossStruc);
Psw4_2x2 = arrayfun(@(x) x.Pon.bat.lo,lossStruc);
Psw_2x2 = (Psw1_2x2 + Psw2_2x2 + Psw3_2x2 + Psw4_2x2)*nrPh_2x2;

Ploss1_2x2 = arrayfun(@(x) x.Ploss.grid.hi,lossStruc);
Ploss2_2x2 = arrayfun(@(x) x.Ploss.bat.hi,lossStruc);
Ploss3_2x2 = arrayfun(@(x) x.Ploss.grid.lo,lossStruc);
Ploss4_2x2 = arrayfun(@(x) x.Ploss.bat.lo,lossStruc);
Ploss_2x2 = (Ploss1_2x2 + Ploss2_2x2 + Ploss3_2x2 + Ploss4_2x2)*nrPh_2x2;

Pcond1_2x2 = Ploss1_2x2 - Psw1_2x2;
Pcond2_2x2 = Ploss2_2x2 - Psw2_2x2;
Pcond3_2x2 = Ploss3_2x2 - Psw3_2x2;
Pcond4_2x2 = Ploss4_2x2 - Psw4_2x2;
Pcond_2x2 = (Pcond1_2x2 + Pcond2_2x2 + Pcond3_2x2 + Pcond4_2x2)*nrPh_2x2;

% Transformer Losses 2x2ph
Pcore_2x2 =  arrayfun(@(x) x.Pcore,transformerAnalysis)*4;
Pw_2x2 = arrayfun(@(x) x.Pw,transformerAnalysis)*nrPh_2x2;

% Total losses 2x2:
Ptot_2x2 = Ploss_2x2 + Pcore_2x2 + Pw_2x2;

% IRMS 2x2
Irms1_2x2 = arrayfun(@(x) x.Irms.grid.hi,lossStruc);
Irms2_2x2 = arrayfun(@(x) x.Irms.bat.hi,lossStruc);
Irms3_2x2 = arrayfun(@(x) x.Irms.grid.lo,lossStruc);
Irms4_2x2 = arrayfun(@(x) x.Irms.bat.lo,lossStruc);
Irms_2x2 = (Irms1_2x2 + Irms2_2x2 + Irms3_2x2 + Irms4_2x2)*nrPh_2x2;


Irms_pri_2x2 = arrayfun(@(x) x.IpriRms,transformerAnalysis);
Irms_sec_2x2 = arrayfun(@(x) x.IsecRms,transformerAnalysis);


% Bmax
Bmax = arrayfun(@(x) x.Bmax,transformerAnalysis);



%% Plot

figure(1)
tile = tiledlayout(2,2)



nexttile    
surf(Io,Vo, Pw_2x2,"FaceAlpha",0.8)
    hold on
    surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
    hold off
    xlabel("Output Current [A]")
    ylabel("Output Voltage [V]")
    zlabel("Winding Losses [W]")
    title("Transformer Winding Losses")

nexttile    
surf(Io,Vo,Pcore_2x2,"FaceAlpha",0.8)
    hold on
    surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
    hold off
    xlabel("Output Current [A]")
    ylabel("Output Voltage [V]")
    zlabel("Core Losses [W]")
    title("Transformer Core Losses")

nexttile    
surf(Io,Vo,Ploss_2x2,"FaceAlpha",0.8)
    hold off
    xlabel("Output Current [A]")
    ylabel("Total Transistor Losses[W]")
    title("Total Transistor Losses")

nexttile    
surf(Io,Vo,Ptot_2x2,"FaceAlpha",0.8)
    hold on
    surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
    hold off
    xlabel("Output Current [A]")
    ylabel("Output Voltage [V]")
    zlabel("Total losses 2x2 [W]")
    title("Total  Losses")
% title(tile," Compare  two-phase vs 2x2-phase")
% %% Compare 2ph vs. four phase
% figure(2)
% tile = tiledlayout(3,2);
% nexttile    
% surf(Io,Vo,Irms_2ph - Irms_4ph,"FaceAlpha",0.8)
%     hold on
%     surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
%     hold off
%     xlabel("Output Current [A]")
%     ylabel("Output Voltage [V]")
%     zlabel("\Delta Irms in Transistor (2ph - 4ph) [A]")
%     title("RMS Current In Transistors")
% 
% nexttile
% surf(Io,Vo,Psw_2ph - Psw_4ph,"FaceAlpha",0.8)
%     hold on
%     surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
%     hold off
%     xlabel("Output Current [A]")
%     ylabel("Output Voltage [V]")
%     zlabel("\Delta Psw in Transistor (2ph - 4ph) [W]")
%     title("Switching Losses")
% 
% nexttile
% surf(Io,Vo,Pcond_2ph - Pcond_4ph,"FaceAlpha",0.8)
%     hold on
%     surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
%     hold off
%     xlabel("Output Current [A]")
%     ylabel("Output Voltage [V]")
%     zlabel("\Delta Pcond in Transistor (2ph - 4ph) [W]")
%     title("Conduction Losses")
% 
% nexttile    
% surf(Io,Vo,Ploss_2ph - Ploss_4ph,"FaceAlpha",0.8)
%     hold on
%     surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
%     hold off
%     xlabel("Output Current [A]")
%     ylabel("Output Voltage [V]")
%     zlabel("\Delta Ploss in Transistor (2ph - 4ph) [W]")
%     title("Total Transistor Losses")
% 
% nexttile    
% surf(Io,Vo,Irms_pri_2ph - Irms_pri_4ph,"FaceAlpha",0.8)
%     hold on
%     surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
%     hold off
%     xlabel("Output Current [A]")
%     ylabel("Output Voltage [V]")
%     zlabel("\Delta Irms Primary (2ph - 4ph) [W]")
%     title("Transformer RMS Primary")
% 
% nexttile    
% surf(Io,Vo,Irms_sec_2ph - Irms_sec_4ph,"FaceAlpha",0.8)
%     hold on
%     surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
%     hold off
%     xlabel("Output Current [A]")
%     ylabel("Output Voltage [V]")
%     zlabel("\Delta Irms Secondary (2ph - 4ph) [W]")
%     title("Transformer RMS Secondary")
% title(tile," Compare  two-phase vs four-phase")
% %% Show Duty Cycle range at current
% % Find Operating point at Io = 40A
% IoIdx = find(Io >= 20,1);
% 
% figure(3)
% tile = tiledlayout(1,2);
% 
% iLims = [0, 100];
% dLims = [0,1];
% nexttile
% plot(Vo/converter.Vclamp,Irms_pri_2x2(:,IoIdx))
% hold on
% plot(Vo/converter.Vclamp,Irms_pri_2ph(:,IoIdx))
% plot(Vo/converter.Vclamp,Irms_pri_4ph(:,IoIdx))
% hold off
%     ylabel("RMS Current Primary")
%     xlabel("Duty Cycle")
%     legend("Two-by-two-phase Transformer","1x2-phase Transformer","Four-Phase Transformer")
%     grid on
%     ylim(iLims)
%     xlim(dLims)
% 
% nexttile
% plot(Vo/converter.Vclamp,Irms_sec_2x2(:,IoIdx))
% hold on
% plot(Vo/converter.Vclamp,Irms_sec_2ph(:,IoIdx))
% plot(Vo/converter.Vclamp,Irms_sec_4ph(:,IoIdx))
% legend("Two-by-two-phase Transformer","1x2-phase Transformer","Four-Phase Transformer")
%     ylabel("RMS Current Secondary")
%     xlabel("Duty Cycle")
% %     title("Two-by-two-phase Converter")
%     grid on
%     ylim(iLims)
%     xlim(dLims)
% % nexttile
% % plot(Vo/converter.Vclamp,Irms_pri_2ph(:,IoIdx))
% %     ylabel("RMS Current Primary")
% %     xlabel("Duty Cycle")
% %     title("Two-phase Converter")
% %     grid on
% %     ylim(iLims)
% %     xlim(dLims)
% % nexttile
% % plot(Vo/converter.Vclamp,Irms_sec_2ph(:,IoIdx))
% %     ylabel("RMS Current Secondary")
% %     xlabel("Duty Cycle")
% %     title("Two-phase Converter")
% %     grid on
% %     ylim(iLims)
% %     xlim(dLims)
% % nexttile
% % plot(Vo/converter.Vclamp,Irms_pri_4ph(:,IoIdx))
% %     ylabel("RMS Current Primary")
% %     xlabel("Duty Cycle")
% %     title("4-phase Converter")
% %     grid on
% %     ylim(iLims)
% %     xlim(dLims)
% % nexttile
% % plot(Vo/converter.Vclamp,Irms_sec_4ph(:,IoIdx))
% %     ylabel("RMS Current Secondary")
% %     xlabel("Duty Cycle")
% %     title("4-phase Converter")
% %     grid on
% %     ylim(iLims)
% %     xlim(dLims)
% title(tile,"Comparison of transformer RMS current for different topologies")
 %% 

[areaHot_tot_2x2, nTransistors_2x2, IrmsMax_2x2, figureCount] = pushPullSoaAnalysis(converter,lossStruc,Io,Vo,Pmax,2);

out.Vmax_pri = converter.Vi;
out.Vmax_sec = converter.Vclamp;
out.IrmsMax_tr_pri = max(Irms_pri_2x2,[],'all');
out.IrmsMax_tr_sec = max(Irms_sec_2x2,[],'all');
out.PcoreMax = max(Pcore_2x2,[],'all');
[out.Bmax, BmaxIdx] = max(Bmax,[],'all');
out.Vpri_Bmax = transformerAnalysis(BmaxIdx).Vpri;
out.tpri_Bmax = transformerAnalysis(BmaxIdx).time;
out.Vsec_Bmax = transformerAnalysis(BmaxIdx).Vsec;
out.tsec_Bmax = transformerAnalysis(BmaxIdx).time;

end
% [areaHot_tot_2ph, nTransistors_2ph, IrmsMax_2ph, figureCount] = pushPullSoaAnalysis(converter_2ph,lossStruc_2ph,Io,Vo,Pmax,figureCount);