function [areaHot_tot, nTransistors, IrmsMax, figureCount] = pushPullSoaAnalysis(converter,lossStruc,Io,Vo,Pmax,figureCount)
%OPRANGEANALYSIS plots the ZVS area for each side/level of the current-fed
% push pull converter, plots the junction temperature, and the combined safe
% operating area (SOA).
% It returns the the percentage of the defined operating are, which exceeds
% the predifend temperature limits, the nr. of transistors used, the
% maximum RMS currents. 
%
% Will be used for optimization & design evaluation

%% Unpack Data
fn_vars = fieldnames(lossStruc(1,1));
fn_side = fieldnames(lossStruc(1,1).Irms);
fn_level = fieldnames(lossStruc(1,1).Irms.grid);

% arrayfun to unpack
%A = arrayfun(@(x) x.grid.hi,Tj); Example

% Loops for var, side (grid/bat) and level (hi,lo)
%VAR
for fvar_cnt = 1:numel(fn_vars)
    varName = fn_vars{fvar_cnt};

% SIDE
    for fside_cnt = 1:numel(fn_side)
        side = fn_side{fside_cnt};

%LEVEL
        for flvl_cnt = 1:numel(fn_level)
            lvl = fn_level{flvl_cnt};
            out.(varName).(side).(lvl) = arrayfun(@(x) x.(varName).(side).(lvl),lossStruc);
        end
    end 
end

%% ZVS BORDER
% Loop for side (grid/bat) and level (hi,lo), and version
        for fside_cnt = 1:numel(fn_side)
                for same = 1:numel(fn_level)
                % To distinguish between turning on/off
                if fn_level{same} == "hi"
                    opposite = "lo";
                else
                    opposite = "hi";
                end
                side = fn_side{fside_cnt};
                lvl = fn_level{same};
                % Turn on Power & Vrem:
                [IZVS.(side).(lvl), ZVS_border.(side).(lvl)] = zvsBorder(out.Isw.(side).(lvl),out.Vrem.(side).(lvl),Io,Vo);
            end
        end 
% The Required switching current for ZVS at a given output voltage:
Izvs_condHi = min(IZVS.grid.hi,[],2);
Izvs_condLo = min(IZVS.grid.lo,[],2);
Izvs_condCombined = min(Izvs_condHi,Izvs_condLo);
% Combine switching currents for high-side & low-side
Isw.grid.comb = min(out.Isw.grid.lo,out.Isw.grid.lo);
Isw.bat.comb = min(out.Isw.bat.lo,out.Isw.bat.lo);

%% Plots
%close all
% Plot Turn On Losses For all sides  (surface)

% [t_Pon, figureCount]  =  tiledSurf(Io,Vo,Out.Pon.grid.hi,Out.Pon.bat.hi,Out.Pon.grid.lo,Out.Pon.bat.lo,"Turn On Losses","Test",figureCount);

% Plot Percentage of Hard Switching as Contour
Vclamp = converter.Vclamp;
[fig, figureCount] = ZVS_LimitPlot(converter,Io,Vo,out.Isw, out.Vrem,Vclamp,nan,figureCount);
%
% Plot Junction Temperature/SOA
[iLim, vLim] = outputOpRange([Io(1), Io(end)],[Vo(1), Vo(end)],Pmax);
[contourOG, figureCount] =  TjContour(Io,Vo,out.Tj,converter.TjLimit,out.Isw,out.Vrem,iLim,vLim,nan,"Safe Operating Area (ZVS & Tj < " + num2str(converter.TjLimit) +"°C)",figureCount);


%% Post Process
[areaHot_tot, SOA] = evalSOA(Io,Vo,Pmax,out.Tj,converter.TjLimit,nan);

% Maximum RMS Current [gridHi, batHi; gridLo, batLo]
pointsRange = Io.*Vo <= Pmax;

% Find maximum RMS
IrmsMax = [max(out.Irms.grid.hi.*pointsRange,[],'all'), max(out.Irms.bat.hi.*pointsRange,[],'all');...
            max(out.Irms.grid.lo.*pointsRange,[],'all'), max(out.Irms.bat.lo.*pointsRange,[],'all')];

% Number of transistors:
nTransistors = converter.ph*(sum(converter.n_parGrid) + sum(converter.n_parBat));

end