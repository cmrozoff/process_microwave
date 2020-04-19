function out = archer(...
    lonMx,latMx,btMx,... % 2-D grids
    sensorType, ... % '85-92GHz', '37GHz', 'IR'
    estLon,estLat,estVmax,... % Ancillary grids (Vmax in knots)
    trueLon,trueLat,... % Display "truth" (best track) if available
    imgTime, imgSensor, estTransVx,... % Values to display
    diagnosticFigureNum) % [] If no figure
%
% ARCHER (Automated Rotational Center Hurricane Eye Retrieval
% To use, you must cite Wimmers and Velden, 2009, [Title]
% 
% 
% History:
% Ver 0_1: Initial version developed in Wimmers and Velden 2009
% Ver 0_2: Configured to work on 85-92 GHz, 37 GHz and longwave IR imagery.
%           The empirical parameters for 37GHz and IR are *not* calibrated.
%
% Notes: 
%

printDiagnosticImage=false;

% Set empirical parameters

switch sensorType
    case '85-92GHz'
        if estVmax<65
            wGFS=14.4;
            comboThresh=268;
        elseif estVmax>=65 && estVmax<84
            wGFS=14.4;
            comboThresh=209;
        elseif estVmax>=84
            wGFS=38.0;
            comboThresh=312;
        else
            disp('Fatal error: estVmax must be a scalar')
        end
    case '37GHz'
        if estVmax<65
            wGFS=14.4;
            comboThresh=268;
        elseif estVmax>=65 && estVmax<84
            wGFS=14.4;
            comboThresh=209;
        elseif estVmax>=84
            wGFS=38.0;
            comboThresh=312;
        else
            disp('Fatal error: estVmax must be a scalar')
        end  
    case 'IR'
        if estVmax<65
            wGFS=14.4;
            comboThresh=250;
        elseif estVmax>=65 && estVmax<84
            wGFS=14.4;
            comboThresh=140;
        elseif estVmax>=84
            wGFS=38.0;
            comboThresh=200;
        else
            disp('Fatal error: estVmax must be a scalar')
        end  
end

% Compute 2-D score fields:

mi.lonMx=lonMx;
mi.latMx=latMx;
mi.bthMx=btMx;
mi.sensorType=sensorType;
fxLon=estLon;
fxLat=estLat;
[lonGrid2,latGrid2,dataGrid2,spiralScoreGrid,ringScoreGrid, ...
 ringRadiusDegGrid] = comboPartsCalc(mi,fxLon,fxLat);

comboGrid=wGFS*spiralScoreGrid + ringScoreGrid;
comboScore=max(comboGrid(:));

out.lonArr=lonGrid2(1,:);
out.latArr=latGrid2(:,1);
out.dataGrid=dataGrid2;
out.comboScore = comboGrid;
out.ringScore = ringScoreGrid;
out.spiralScore = spiralScoreGrid;

% Compute target and final positions:

[indexMaxI,indexMaxJ]=find(comboGrid==comboScore);
if isempty(indexMaxI)
    latOfComboMax=[];
    lonOfComboMax=[];
else
    latOfComboMax=latGrid2(indexMaxI(1),indexMaxJ(1));
    lonOfComboMax=lonGrid2(indexMaxI(1),indexMaxJ(1));
    nanDefault=isnan(dataGrid2(indexMaxI(1),indexMaxJ(1))); % We won't use targets outside swath (or will we?)
end

out.targetLon=lonOfComboMax;
out.targetLat=latOfComboMax;

if comboScore>=comboThresh && ~nanDefault
    out.usesTarget=true;
    out.finalLon=lonOfComboMax;
    out.finalLat=latOfComboMax;
else
    out.usesTarget=false;
    out.finalLon=fxLon;
    out.finalLat=fxLat;
end

% Other outputs
out.ringRadiusDeg=interp2(lonGrid2,latGrid2,ringRadiusDegGrid,out.finalLon,out.finalLat,'nearest');

% Diagnostic Display

if ~isempty(diagnosticFigureNum)
       
    jetMap=jet(256); invertedJet=jetMap(end:-1:1,:); %Colorscale
    figure(diagnosticFigureNum); clf;
    set(gcf,'position',[120 2020 1010 400]);
    set(gcf,'paperposition',get(gcf,'position')/100);

    useLarge=true;
    % Plot 1: Spiral contour
    subplot('Position',[.04 .07 .28 .82])
    if useLarge
        pcolorCentered(lonMx,latMx,btMx); hold on;
        axis([fxLon-2.5/cos(pi/180*fxLat) fxLon+2.5/cos(pi/180*fxLat) fxLat-2.5 fxLat+2.5])
    else
        pcolorCentered(lonGrid2,latGrid2,dataGrid2); hold on;
    end
    caxis([150 270]);
%    colormap(invertedJet)
    ylabel('Latitude (^oN)');
    xlabel('Longitude (^oW)');
    cb=colorbar('horiz');
    axis xy;
    set(get(cb,'XLabel'),'String','Brightness temperature, K');
    set(get(cb,'XLabel'),'VerticalAlignment','Top');

    % Overlay with contours:
    [c,h]=contour(lonGrid2,latGrid2,spiralScoreGrid,'w-'); hold on;
    set(h,'LineWidth',2,'Color',0.5*[1 1 1]);
    
    % Forecast center:
    plot(fxLon, fxLat,'k+','MarkerSize',12,'Linewidth',4); hold on
    plot(fxLon, fxLat,'w+','MarkerSize', 9,'Linewidth',2); hold on

    % True center:
    plot(trueLon,trueLat,'k^','MarkerSize',9,'Linewidth',3); hold on
    plot(trueLon,trueLat,'w^','MarkerSize',7'); hold on

    % Plot top score point
    if ~nanDefault
        spiralScoreMax=max(spiralScoreGrid(:));
        [indexMaxI,indexMaxJ]=find(spiralScoreGrid==spiralScoreMax);
        latOfSpiralScoreMax=latGrid2(indexMaxI(1),indexMaxJ(1));
        lonOfSpiralScoreMax=lonGrid2(indexMaxI(1),indexMaxJ(1));
        sps=plot(lonOfSpiralScoreMax,latOfSpiralScoreMax,'ws','MarkerSize', 6, 'LineWidth', 2); hold on;
        sps=plot(lonOfSpiralScoreMax,latOfSpiralScoreMax,'ks','MarkerSize', 8, 'LineWidth', 2); hold on;
        %set(sps,'Color',0.5*[1 1 1]);
    end

    title(['Weighted Guided Fine Spiral Score = ' num2str(round(wGFS*spiralScoreMax)) '  ']);
    
    % Plot 2: Ring contour
    subplot('Position',[.36 .07 .28 .82])
    pcolorCentered(lonGrid2,latGrid2,dataGrid2); hold on;
    caxis([150 270]);
    cb=colorbar('horiz');
    xlabel('Longitude (^oW)')
    axis xy;
    set(get(cb,'XLabel'),'String','Brightness temperature, K');
    set(get(cb,'XLabel'),'VerticalAlignment','Top');

    % Overlay with contours:
    [c,h]=contour(lonGrid2,latGrid2,ringScoreGrid,'w-'); hold on;
    set(h,'LineWidth',2,'Color',0.5*[1 1 1]);

    % Plot top score point
    if ~nanDefault
        ringScoreMax=max(ringScoreGrid(:));
        [indexMaxI,indexMaxJ]=find(ringScoreGrid==ringScoreMax);
        latOfRingScoreMax=latGrid2(indexMaxI(1),indexMaxJ(1));
        lonOfRingScoreMax=lonGrid2(indexMaxI(1),indexMaxJ(1));
        sps=plot(lonOfRingScoreMax,latOfRingScoreMax,'ws','MarkerSize', 6, 'LineWidth', 2); hold on;
        sps=plot(lonOfRingScoreMax,latOfRingScoreMax,'ks','MarkerSize', 8, 'LineWidth', 2); hold on;
    end

%    title({[imgSensor '  ' datestr(imgTime,30) '    Vmax=' num2str(round(estVmax*10)/10,'%4.1f') ', ' ...
%        'Vx= ' num2str(round(estTransVx*10)/10,'%4.1f') ' kts  '],...
%        ['Ring Score = ' num2str(round(ringScoreMax)) '  ']});
    title({['Ring Score = ' num2str(round(ringScoreMax)) '  ']});
    
    % Plot 3: Combo contour
    subplot('Position',[.68 .07 .28 .82])
    pcolorCentered(lonGrid2,latGrid2,dataGrid2); hold on;
    caxis([150 270]);
    cb=colorbar('horiz');
    xlabel('Longitude (^oW)')
    axis xy;
    set(get(cb,'XLabel'),'String','Brightness temperature, K');
    set(get(cb,'XLabel'),'VerticalAlignment','Top');
    title(['Combined score=' num2str(round(comboScore),'%d') ', '...
        'Threshold=' num2str(round(comboThresh),'%d') '  ']);

    % Overlay with contours:
    [c,h]=contour(lonGrid2,latGrid2,comboGrid,'w-'); hold on;
    set(h,'LineWidth',2,'Color',0.5*[1 1 1]);

    % Plot the ring radius
    rLonArr=out.finalLon+cos((0:5:360)/180*pi)*out.ringRadiusDeg/cos(pi/180*out.finalLat);
    rLatArr=out.finalLat+sin((0:5:360)/180*pi)*out.ringRadiusDeg;
%    plot(rLonArr,rLatArr,'m-','LineWidth',2); hold on;
    
    
    % Forecast center:
    plot(fxLon, fxLat,'k+','MarkerSize',12,'Linewidth',4); hold on
    plot(fxLon, fxLat,'w+','MarkerSize', 9,'Linewidth',2); hold on

    % True center:
    plot(trueLon,trueLat,'k^','MarkerSize',9,'Linewidth',3); hold on
    plot(trueLon,trueLat,'w^','MarkerSize',7'); hold on

    % Plot top score point
    if ~nanDefault
        sps=plot(lonOfComboMax,latOfComboMax,'ws','MarkerSize', 6, 'LineWidth', 2); hold on;
        sps=plot(lonOfComboMax,latOfComboMax,'ks','MarkerSize', 8, 'LineWidth', 2); hold on;
    end
    drawnow
    
    if printDiagnosticImage
        print(gcf,'-dtiff','-r144',['demo' imgSensor datestr(imgTime,30) '.tiff'])
    end
    
    
    exportfig(gcf,'example.eps','fontmode','fixed', ...
         'width',13.5,'height',5,...
         'fontsize',11,'resolution',1200,...
	 'renderer','painters', ...
         'color','cmyk');
     pause
    
%
% % Alternative
% %
%     pcolorCentered(lonGrid2,latGrid2,dataGrid2); hold on;
%     caxis([150 270]);
%     cb=colorbar('horiz');
%     xlabel('Longitude (^oW)')
% 
%     axis square;
%     set(get(cb,'XLabel'),'String','Brightness temperature, K');
%     set(get(cb,'XLabel'),'VerticalAlignment','Top');
%     title(['Combined score=' num2str(round(comboScore),'%d') ', '...
%         'Threshold=' num2str(round(comboThresh),'%d') '  ']);
% 
%     % Overlay with contours:
%     [c,h]=contour(lonGrid2,latGrid2,comboGrid,'w-'); hold on;
%     set(h,'LineWidth',2,'Color',0.5*[1 1 1]);
% 
%     % Plot the ring radius
%     rLonArr=out.finalLon+cos((0:5:360)/180*pi)*out.ringRadiusDeg/cos(pi/180*out.finalLat);
%     rLatArr=out.finalLat+sin((0:5:360)/180*pi)*out.ringRadiusDeg;
% %    plot(rLonArr,rLatArr,'m-','LineWidth',2); hold on;
%     
%     
%     % Forecast center:
%     plot(fxLon, fxLat,'k+','MarkerSize',12,'Linewidth',4); hold on
%     plot(fxLon, fxLat,'w+','MarkerSize', 9,'Linewidth',2); hold on
% 
%     % True center:
%     plot(trueLon,trueLat,'k^','MarkerSize',9,'Linewidth',3); hold on
%     plot(trueLon,trueLat,'w^','MarkerSize',7'); hold on
% 
%     % Plot top score point
%     if ~nanDefault
%         sps=plot(lonOfComboMax,latOfComboMax,'ws','MarkerSize', 6, 'LineWidth', 2); hold on;
%         sps=plot(lonOfComboMax,latOfComboMax,'ks','MarkerSize', 8, 'LineWidth', 2); hold on;
%     end
%     drawnow
%     
%     if printDiagnosticImage
%         print(gcf,'-dtiff','-r144',['demo' imgSensor datestr(imgTime,30) '.tiff'])
%     end
%     
%     
%     exportfig(gcf,'center.eps','fontmode','fixed', ...
%          'width',4.5,'height',5,...
%          'fontsize',11,'resolution',1200,...
% 	 'renderer','painters', ...
%          'color','cmyk');
     pause
 end
