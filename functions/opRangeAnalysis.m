function [areaHot_tot, nTransistors, IrmsMax, figureCount] = opRangeAnalysis(converter,IoRange,VoRange,Pmax)
%OPRANGEANALYSIS
%TODO: WRITE DESCRIPTION

%% Unpack:
C = converter.C;
if isfield(converter,'figureCount') == 1
    figureCount = converter.figureCount;
else
    figureCount = 1;
end
%% Grid Side Transistor

Qgrid = converter.Qgrid;
n_parGrid = converter.n_parGrid;

%% Transformer Data
T = converter.T;
%% Battery Side Transistor
Qbat = converter.Qbat;
n_parBat = converter.n_parBat;

%% Circuit Parameters


RthCA = converter.RthCA;
Ta = converter.Ta;
TjLimit = converter.TjLimit;
dV = converter.dV;
Lau = converter.Lau;

% Sweep  Range
nIo = 25;
IoStep = (IoRange(2) - IoRange(1))/(nIo - 1);
nVo = 75;
VoStep = (VoRange(2) - VoRange(1))/(nVo - 1);

Io = [IoRange(1):IoStep:IoRange(2)];
Vo = [VoRange(1):VoStep:VoRange(2)]';

% Analysis
for v_cnt = 1:numel(Vo)
    for i_cnt = 1:numel(Io)
        S(v_cnt,i_cnt) = currentFedPushPull(C,Qgrid,n_parGrid,T,Qbat,n_parBat,Vo(v_cnt),Io(i_cnt),RthCA, Ta, dV, Lau);
    end
end

%% Unpack Data
fn_vars = fieldnames(S(1,1));
fn_side = fieldnames(S(1,1).Irms);
fn_level = fieldnames(S(1,1).Irms.grid);

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
            out.(varName).(side).(lvl) = arrayfun(@(x) x.(varName).(side).(lvl),S);
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
Vclamp = (C.Vi - dV)/T.N;
[fig, figureCount] = ZVS_LimitPlot(C,Io,Vo,out.Isw, out.Vrem,Vclamp,nan,figureCount);
%
% Plot Junction Temperature/SOA
[iLim, vLim] = outputOpRange([Io(1), Io(end)],[Vo(1), Vo(end)],Pmax);
[contourOG, figureCount] =  TjContour(Io,Vo,out.Tj,TjLimit,out.Isw,out.Vrem,iLim,vLim,nan,"Safe Operating Area (ZVS & Tj < " + num2str(TjLimit) +"°C)",figureCount);

%% Post Process
[areaHot_tot, SOA] = evalSOA(Io,Vo,Pmax,out.Tj,TjLimit,nan);

% Maximum RMS Current [gridHi, batHi; gridLo, batLo]
pointsRange = Io.*Vo <= Pmax;

% Find maximum RMS
IrmsMax = [max(out.Irms.grid.hi.*pointsRange,[],'all'), max(out.Irms.bat.hi.*pointsRange,[],'all');...
            max(out.Irms.grid.lo.*pointsRange,[],'all'), max(out.Irms.bat.lo.*pointsRange,[],'all')];

% Number of transistors:
nTransistors = C.ph*(sum(n_parGrid) + sum(n_parBat));
end