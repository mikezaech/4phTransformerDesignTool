function saveOptimization(optRun,xOpt,filename)
    %% generate save file name
    dateStr = date;
    % Check directory:
    if ~exist(append('optimization/',dateStr), 'dir')
       mkdir(append('optimization/',dateStr))
    end
    figSavename = append('optimization/',dateStr,'/',dateStr,'_',filename,'.pdf');
    dataSavename = append('optimization/',dateStr,'/',dateStr,'_',filename,'.mat');
    %% Save figures
    nGridHi = num2str(optRun(1).converter.n_parGrid(1));
    nGridLo = num2str(optRun(1).converter.n_parGrid(2));
    nBatHi = num2str(optRun(1).converter.n_parBat(1));
    nBatLo = num2str(optRun(1).converter.n_parBat(2));
    

    figure(4)
    structOpt = optRun(find([optRun.xVal]*1  == xOpt));
    titleString = append('Optimisation for ', structOpt.optVar,' in ', structOpt.converter.T.config, ' configuration' ,...
                        newline, 'Optimal ',  structOpt.optVar,': ',num2str(xOpt),...
                        newline, 'SOA (%): ',num2str(structOpt.soa*100),... 
                        newline, 'Nr. transistors:',newline,...
                        nGridHi,'|',nBatHi,newline,'---',newline,nGridLo,'|',nBatLo);
    text(0.1, 0.5,titleString,'FontSize',16); axis off
    
    ax = figure(4);
    exportgraphics(ax,figSavename,'ContentType','vector')
    close
    ax = figure(1);
    exportgraphics(ax,figSavename,'ContentType','vector',"Append",true)
    ax = figure(2);
    exportgraphics(ax,figSavename,'ContentType','vector',"Append",true)
    ax = figure(3);
    exportgraphics(ax,figSavename,'ContentType','vector',"Append",true)

    %% Save variables
    save(dataSavename,"optRun","xOpt")
end