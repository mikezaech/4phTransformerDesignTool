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
converter.T = defineTransformer(trDesign, '4ph'); % High Power, 4ph optimized

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

% Losses 4ph
nrPh_4ph = 4;
Psw1_4ph = arrayfun(@(x) x.Pon.grid.hi,lossStruc);
Psw2_4ph = arrayfun(@(x) x.Pon.bat.hi,lossStruc);
Psw3_4ph = arrayfun(@(x) x.Pon.grid.lo,lossStruc);
Psw4_4ph = arrayfun(@(x) x.Pon.bat.lo,lossStruc);
Psw_4ph = (Psw1_4ph + Psw2_4ph + Psw3_4ph + Psw4_4ph)*nrPh_4ph;

Ploss1_4ph = arrayfun(@(x) x.Ploss.grid.hi,lossStruc);
Ploss2_4ph = arrayfun(@(x) x.Ploss.bat.hi,lossStruc);
Ploss3_4ph = arrayfun(@(x) x.Ploss.grid.lo,lossStruc);
Ploss4_4ph = arrayfun(@(x) x.Ploss.bat.lo,lossStruc);
Ploss_4ph = (Ploss1_4ph + Ploss2_4ph + Ploss3_4ph + Ploss4_4ph)*nrPh_4ph;

Pcond1_4ph = Ploss1_4ph - Psw1_4ph;
Pcond2_4ph = Ploss2_4ph - Psw2_4ph;
Pcond3_4ph = Ploss3_4ph - Psw3_4ph;
Pcond4_4ph = Ploss4_4ph - Psw4_4ph;
Pcond_4ph = (Pcond1_4ph + Pcond2_4ph + Pcond3_4ph + Pcond4_4ph)*nrPh_4ph;

% Transformer Losses 4phph
Pcore_4ph =  arrayfun(@(x) x.Pcore,transformerAnalysis)*4;
Pw_4ph = arrayfun(@(x) x.Pw,transformerAnalysis)*nrPh_4ph;

% Total losses 4ph:
Ptot_4ph = Ploss_4ph + Pcore_4ph + Pw_4ph;

% IRMS 4ph
Irms1_4ph = arrayfun(@(x) x.Irms.grid.hi,lossStruc);
Irms2_4ph = arrayfun(@(x) x.Irms.bat.hi,lossStruc);
Irms3_4ph = arrayfun(@(x) x.Irms.grid.lo,lossStruc);
Irms4_4ph = arrayfun(@(x) x.Irms.bat.lo,lossStruc);
Irms_4ph = (Irms1_4ph + Irms2_4ph + Irms3_4ph + Irms4_4ph)*nrPh_4ph;


Irms_pri_4ph = arrayfun(@(x) x.IpriRms,transformerAnalysis);
Irms_sec_4ph = arrayfun(@(x) x.IsecRms,transformerAnalysis);


% Bmax
Bmax = arrayfun(@(x) x.Bmax,transformerAnalysis);



%% Plot

figure(1)
tile = tiledlayout(2,2)



nexttile    
surf(Io,Vo, Pw_4ph,"FaceAlpha",0.8)
    hold on
    surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
    hold off
    xlabel("Output Current [A]")
    ylabel("Output Voltage [V]")
    zlabel("Winding Losses [W]")
    title("Transformer Winding Losses")

nexttile    
surf(Io,Vo,Pcore_4ph,"FaceAlpha",0.8)
    hold on
    surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
    hold off
    xlabel("Output Current [A]")
    ylabel("Output Voltage [V]")
    zlabel("Core Losses [W]")
    title("Transformer Core Losses")

nexttile    
surf(Io,Vo,Ploss_4ph,"FaceAlpha",0.8)
    hold off
    xlabel("Output Current [A]")
    ylabel("Total Transistor Losses[W]")
    title("Total Transistor Losses")

nexttile    
surf(Io,Vo,Ptot_4ph,"FaceAlpha",0.8)
    hold on
    surf(Io,Vo,zeros(length(Io)),"FaceAlpha",0.8,"FaceColor","#000000")
    hold off
    xlabel("Output Current [A]")
    ylabel("Output Voltage [V]")
    zlabel("Total losses 4ph [W]")
    title("Total  Losses")
% title(tile," Compare  two-phase vs 4ph-phase")
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
% plot(Vo/converter.Vclamp,Irms_pri_4ph(:,IoIdx))
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
% plot(Vo/converter.Vclamp,Irms_sec_4ph(:,IoIdx))
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

[areaHot_tot_4ph, nTransistors_4ph, IrmsMax_4ph, figureCount] = pushPullSoaAnalysis(converter,lossStruc,Io,Vo,Pmax,2);

out.Vmax_pri = converter.Vi;
out.Vmax_sec = converter.Vclamp;
out.IrmsMax_tr_pri = max(Irms_pri_4ph,[],'all');
out.IrmsMax_tr_sec = max(Irms_sec_4ph,[],'all');
out.PcoreMax = max(Pcore_4ph,[],'all');
[out.Bmax, BmaxIdx] = max(Bmax,[],'all');
out.Vpri_Bmax = transformerAnalysis(BmaxIdx).Vpri;
out.tpri_Bmax = transformerAnalysis(BmaxIdx).time;
out.Vsec_Bmax = transformerAnalysis(BmaxIdx).Vsec;
out.tsec_Bmax = transformerAnalysis(BmaxIdx).time;

end
% [areaHot_tot_2ph, nTransistors_2ph, IrmsMax_2ph, figureCount] = pushPullSoaAnalysis(converter_2ph,lossStruc_2ph,Io,Vo,Pmax,figureCount);