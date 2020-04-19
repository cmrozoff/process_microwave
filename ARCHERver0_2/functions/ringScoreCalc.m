function [ringScoreGrid, ringSizeGrid]=...
    ringScoreCalc(latGrid, lonGrid, hurrImg, ...
    sensorType, swarmInds, minRadiusDeg, maxRadiusDeg)
%
% Inputs:
% latGrid, lonGrid - lat, lon grids. Should be equally spaced in real distance, not degrees
% hurrImg - Image of hurricane 
% sensorType - '85-92GHz', '37GHz' or 'IR'. '37GHz' uses different 
%  rules
% swarmInds - Indeces of the points to search around
% minRadiusDeg - Minimum ring radius (~0.06)
% maxRadiusDeg - Maximum ring radius (~0.40)
%
% Outputs:
% ringScoreGrid: Grid of scores that rank the "fit" of a ring
% ringSizeGrid: Optimum ring size for every valid point on the grid
% eyewallArrays: First two dimensions: grid; last dimension: Brightness
%                temperatures of the optimum eyewall for that point
% maxEyeBTgrid: Grid of maximum pixel BT inside the optimum ring

% History:
% Was ringFitScoresOverhaulOpt3: Changed from Opt2 to use a cloud 
% of points instead of a single point with a radius
% 5/2009: Renamed ringScoreCalc

% Add step for 37GHz:
if strcmp(sensorType,'37GHz')
    hurrImg=450-hurrImg; % Keeps the signs consistent with the other sensors
end

% Calculate gradient field:
% ROZOFF Hack
%hurrImg = smooth(hurrImg,50);
[gx,gy]=gradient((hurrImg).^.333,1,-1); % The sqrt function de-emphasizes big gradients
%[gx, gy] = gradient((hurrImg).^.6,1,-1);

% Translate degrees to pixels:
degPerPix=abs(latGrid(1,1)-latGrid(2,1));
maxRadiusPix=round(maxRadiusDeg/degPerPix);

% Initialize variables related to the score grids:
[nRows,nCols]=size(hurrImg);
nRingPts=length(0:5:359);
scoreMatrix=zeros(nRows,nCols,maxRadiusPix);
ringScoreGrid=-inf*zeros(nRows,nCols);
ringSizeGrid=zeros(nRows,nCols);
maxEyeBTgrid=NaN*zeros(nRows,nCols);
maxEyewallBTgrid=NaN*zeros(nRows,nCols);
eyeWallRadiusDeg=NaN*zeros(nRows,nCols);
eyewallArrays=NaN*zeros(nRows,nCols,nRingPts);

% Build the score grids. Iterate by radius, and within that, iterate by location
fprintf(1,'Radius (deg) = ');
radArray=minRadiusDeg:.05:maxRadiusDeg;
for radi=length(radArray):-1:1
    radiusDeg=radArray(radi); 
    
    fprintf(1,'%4.2f ',radiusDeg); 
    
    ringLonOffset=  ...
        radiusDeg*cos(pi/180*(0:5:359))/cos(pi/180* ...
         mean(latGrid(swarmInds)));
    ringLatOffset=radiusDeg*sin(pi/180*(0:5:359));
    lengthOfRing=length(ringLatOffset);
    
    % For 37 GHz (H)
    ringUnitVectorX = -cos(pi/180*(0:5:359)); % Unit vectors pointed radially inward
    ringUnitVectorY = -sin(pi/180*(0:5:359));
    % For 37 GHz (PCT)
%    ringUnitVectorX = cos(pi/180*(0:5:359));
%    ringUnitVectorY = sin(pi/180*(0:5:359));

    scoreMatrix(:,:,radi)=NaN; % Takes the points not in the disk out of the running
    
    % (Iterate by location)
    for matInd=swarmInds
        
        [i,j]=ind2sub(size(hurrImg),matInd);

        ringLats=ringLatOffset+latGrid(matInd);
        ringLons=ringLonOffset+lonGrid(matInd);
        
        ringGradientX=interp2(lonGrid,latGrid,gx,ringLons,ringLats,'*nearest');
        ringGradientY=interp2(lonGrid,latGrid,gy,ringLons,ringLats,'*nearest');
        
        dotProductArr = ringUnitVectorX.*ringGradientX + ringUnitVectorY.*ringGradientY;
        %dotScoreArr = sign(dotProductArr).*log(1+abs(dotProductArr)); % de-intensifies the highs and lows
        dotScoreArr = dotProductArr;
        
        % Put the score in the score matrix if it is drawn from enough valid points:
        nNonNans=sum(~isnan(dotScoreArr)); % Number of non-Nans
        if nNonNans<=0.425*lengthOfRing
            scoreMatrix(i,j,:)=NaN; % If it doesn't qualify for the smallest, then none of
            % the other diameters get to count either
        else
            scoreMatrix(i,j,radi) = (radiusDeg^0.1)*mean(dotScoreArr(~isnan(dotScoreArr)));
        end
        
        % If the high score was beaten, then set the score grids:
        if radi==length(radArray) || scoreMatrix(i,j,radi)>ringScoreGrid(i,j)
            ringScoreGrid(i,j)=scoreMatrix(i,j,radi);
            ringSizeGrid(i,j)=radiusDeg;
        end
        
    end
        
end
fprintf(1,'\n')

% Move this somewhere else soon:
if 0
disp('Assigning warmest pixel in each ring')
for matInd=swarmInds
    
    % Ring of points
    [i,j]=ind2sub(size(hurrImg),matInd);
    radiusDeg=ringSizeGrid(i,j);

    % Warmest pixel
    inEye=(latGrid-latGrid(i,j)).^2 + ...
        ((lonGrid-lonGrid(i,j))/cos(pi/180*latGrid(i,j))).^2 <= radiusDeg^2;
    ptsInEye=find(inEye)';
    eyeBTs=hurrImg(ptsInEye);
    maxEyeBTpt=max(eyeBTs(~isnan(eyeBTs(:))));
    if ~isempty(maxEyeBTpt)
        maxEyeBTgrid(i,j)=maxEyeBTpt;
    else
        maxEyeBTgrid(i,j)=NaN;
    end
    
end
end
    
% Delete this soon:
% Identify the associated eye*wall*, which is the ring with the lowest
% maximum brightness temperature (kind of like the "least broken ring")
if 0
    disp('Finding the best eye*wall*')
    for matInd=swarmInds

        [i,j]=ind2sub(size(hurrImg),matInd);
        radiusDeg=ringSizeGrid(i,j);

        for radOut=radiusDeg:.025:(radiusDeg+.25)

            ringLatOffset=radOut*sin(pi/180*(0:5:359));
            ringLonOffset=radOut*cos(pi/180*(0:5:359))/cos(pi/180*latGrid(i,j));

            ringLats=ringLatOffset+latGrid(matInd);
            ringLons=ringLonOffset+lonGrid(matInd);

            ringOutBTarr=interp2(lonGrid,latGrid,hurrImg,ringLons,ringLats);

            if radOut==radiusDeg || max(ringOutBTarr)<maxEyewallBTgrid(i,j)
                %maxEyewallBTgrid(i,j)=max(ringOutBTarr);
                eyewallArrays(i,j,:)=ringOutBTarr;
                eyeWallRadiusDeg(i,j)=radOut;
            end

        end
    end
else % If the eyewall calculation is not needed
    %maxEyewallBTgrid=ones(size(hurrImg));
    eyewallArrays=ones([size(hurrImg) length(0:5:359)]);
    eyeWallRadiusDeg=ones(size(hurrImg));
end

disp('(done)');
