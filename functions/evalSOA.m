function [areaHot_tot, SOA_tot] = evalSOA(Io,Vo,Pmax,Tj,TjLimit,version)

%function [areaHardSwitch, areaHot, areaHardSwitch_tot, areaHot_tot, SOA_tot] = evalSOA(Tj,TjLimit,Isw,IZVS_cond,version)
    % Find SOA in regards to ZVS and TJ
    % Define variables
if isstring(version) == 1
    Tj_gridHi = Tj.grid.hi.(version);
    Tj_gridLo = Tj.grid.lo.(version);
    Tj_batHi = Tj.bat.hi.(version);
    Tj_batLo = Tj.bat.lo.(version);
    
else
    Tj_gridHi = Tj.grid.hi;
    Tj_gridLo = Tj.grid.lo;
    Tj_batHi = Tj.bat.hi;
    Tj_batLo = Tj.bat.lo;
end

    
    %% New approach: Count OPs!
    
    % OPs within defined Output Range
    pointsRange = Io.*Vo <= Pmax;
    n_HPC = sum(pointsRange,'all');
    
    
    
    % Junction Temperature area
    % Nr. of hot OPs
    % Grid, Hi
    pointsHot_GridHi = (Tj_gridHi >= TjLimit).*pointsRange;
    n_Hot_GridHi = sum(pointsHot_GridHi,'all');
    % Grid Lo
    pointsHot_GridLo = (Tj_gridLo >= TjLimit).*pointsRange;
    n_Hot_GridLo = sum(pointsHot_GridLo,'all');
    % Bat, Hi
    pointsHot_BatHi = (Tj_batHi >= TjLimit).*pointsRange;
    n_Hot_BatHi = sum(pointsHot_BatHi,'all');
    % Bat Lo
    pointsHot_BatLo = (Tj_batLo >= TjLimit).*pointsRange;
    n_Hot_BatLo = sum(pointsHot_BatLo,'all');
    
    areaHot_GridHi = n_Hot_GridHi/n_HPC;
    areaHot_GridLo = n_Hot_GridLo/n_HPC;
    areaHot_BatHi = n_Hot_BatHi/n_HPC;
    areaHot_BatLo = n_Hot_BatLo/n_HPC;
    
    %% Total: 
    % Maximum Values of any bridge
    maxTjGrid = max(Tj_gridHi,Tj_gridLo);
    maxTjGridBatHi = max(maxTjGrid,Tj_batHi);
    maxTj = max(maxTjGridBatHi,Tj_batLo);
    %
    
    pointsHot_tot = (maxTj >= TjLimit).*pointsRange;
    n_Hot_tot = sum(pointsHot_tot,'all');
    
%     areaHardSwitch_tot = n_HardSwitch_tot/n_HPC;
    areaHot_tot = n_Hot_tot/n_HPC;
    

    %% Combine Hot & Hard Switch to obtain combined SOA:

 SOA_tot =  1 - areaHot_tot;
end