function [lonGrid2,latGrid2,dataGrid2,spiralScoreGrid, ...
    ringScoreGrid,ringSizeMx] = ...
    comboPartsCalc(mi,fxLon,fxLat)

%Functions:
%spiralCenterLowRes.m - Find the spiral center (large range)
%spiralCenterLowRes2nd.m - Hone in on the center and get a good score (short range)
%ringFitScoresOverhaul.m - Assign scores according to the best ring fit
%distanceDeg.m - Find the distance between two points (in g.c.d.)
%
% History
% Ver. 3: (AJW) Instead of using a fixed reference point for ringFit, send
% it a swarm of points determined by the spiral fit maximum areas
%
% 2009/05: Renamed to comboPartsCalc from comboCenterRingOverHaulOpt3
% 2009/07: Cleaned up the code for ARCHER

SPIRAL_WEIGHT=15;
SPIRAL_OFFSET=20;
DISTANCE_PENALTY_WEIGHT_1=2;
DISTANCE_PENALTY_WEIGHT_2=1;

RING_WEIGHT=250;

% Remove any false data
mi.bthMx(mi.bthMx(:)<80)=NaN;

% Resampling parameters
lonInc=0.05; latInc=0.05;
perimDeg=3.2;

% Resample the swath to a regular grid, centered on the fx point, and with
% the correct aspect ratio at the fx point
fprintf(1,'Regridding ... ');
latMxOffset1=mi.latMx-fxLat;
lonMxOffset1=(mi.lonMx-fxLon)*cos(fxLat*pi/180);   
xOffsetArrayGCD=-perimDeg:lonInc:perimDeg; 
yOffsetArrayGCD=(perimDeg:-latInc:-perimDeg)';
lonArray1=(xOffsetArrayGCD/cos(fxLat*pi/180))+fxLon;   
latArray1=yOffsetArrayGCD+fxLat;
[lonGrid1,latGrid1]=meshgrid(lonArray1,latArray1);
[xOffsetGridGCD,yOffsetGridGCD]=meshgrid(xOffsetArrayGCD,yOffsetArrayGCD);
dataGrid1=griddata(lonMxOffset1, latMxOffset1, mi.bthMx, xOffsetGridGCD, yOffsetGridGCD);

% Remove any points that interpolated outside the curved swath edges
[latCenteredPerimeter, lonCenteredPerimeter]=ssmiPerimeterTightLight(latMxOffset1, lonMxOffset1);
inPerimeter=inpolygon(xOffsetGridGCD,yOffsetGridGCD,lonCenteredPerimeter,latCenteredPerimeter);
dataGrid1(~inPerimeter)=NaN;
fprintf(1,'done\n');


% Spiral center (Iteration 1 of 2):

% Parameters
filterRadiusDeg=3.0; % Range of valid image pixels (Very important to optimize!!!)
spiralSearchRadiusDeg=2.0; % Range of "candidate points" (only affects computational time)
spacingDeg=0.25; % Spacing of "candidate points"

fprintf(1,'Calculating spiral center ... ');
[spiralXCenter0,spiralYCenter0,spScore1,spGrid1]=...
    spiralCenterLowRes(xOffsetGridGCD,yOffsetGridGCD,dataGrid1,fxLon,fxLat,...
    filterRadiusDeg,spiralSearchRadiusDeg,spacingDeg);

% Add in the penalty for distance from first guess:
penaltyFunctionGrid=DISTANCE_PENALTY_WEIGHT_1*(distanceDeg(fxLon,fxLat,lonGrid1,latGrid1)).^2; 
spGrid1withPenalty=SPIRAL_WEIGHT*spGrid1-penaltyFunctionGrid-SPIRAL_OFFSET;
indexMax=find(spGrid1withPenalty==max(spGrid1withPenalty(:)));
spiralYCenter=yOffsetGridGCD(indexMax(1));
spiralXCenter=xOffsetGridGCD(indexMax(1));

spiralLatCenter1=spiralYCenter+fxLat;
spiralLonCenter1=spiralXCenter/cos(pi*fxLat/180)+fxLon;
fprintf(1,'done\n');

% Resampling parameters (2)
lonInc=0.05; latInc=0.05;
perimDeg=1.6;

% Resample around the results of the first spiral center (this is a better
% rough guess than the forecast point globally)
fprintf(1,'Regridding (2) ... ');
latMxOffset2=mi.latMx-spiralLatCenter1;
lonMxOffset2=(mi.lonMx-spiralLonCenter1)*cos(spiralLatCenter1*pi/180);
xOffsetArrayGCD=-perimDeg:lonInc:perimDeg;
yOffsetArrayGCD=(perimDeg:-latInc:-perimDeg)';
lonArray2=(xOffsetArrayGCD/cos(spiralLatCenter1*pi/180))+spiralLonCenter1;   
latArray2=yOffsetArrayGCD+spiralLatCenter1;
[lonGrid2,latGrid2]=meshgrid(lonArray2,latArray2);
[xOffsetGridGCD2,yOffsetGridGCD2]=meshgrid(xOffsetArrayGCD,yOffsetArrayGCD);
dataGrid2=griddata(lonMxOffset2, latMxOffset2, mi.bthMx, xOffsetGridGCD2, yOffsetGridGCD2);

% Remove any points that interpolated outside the curved swath edges
[latCenteredPerimeter, lonCenteredPerimeter]=ssmiPerimeterTightLight(latMxOffset2, lonMxOffset2);
inPerimeter=inpolygon(xOffsetGridGCD2,yOffsetGridGCD2,lonCenteredPerimeter,latCenteredPerimeter);
dataGrid2(~inPerimeter)=NaN;

% NEW: Apply 'nearest' where there is no good data
nanScanPoints=isnan(dataGrid2) & inPerimeter;
dataGrid2(nanScanPoints)=griddata(lonMxOffset2, latMxOffset2, mi.bthMx, ...
    xOffsetGridGCD2(nanScanPoints), yOffsetGridGCD2(nanScanPoints),'nearest');

fprintf(1,'done\n');


% Spiral center (Iteration 2 of 2)

% Parameters
filterRadiusDeg2=2.0; %1.5; % Range of valid image pixels (Very important to optimize!!!)
spiralSearchRadiusDeg2=1.25; %1.0; % Range of "candidate points" (only affects computational time)
spacingDeg2=0.05; % Spacing of "candidate points"

fprintf(1,'Calculating spiral center (2) ... ');
[spiralXCenter0,spiralYCenter0,spScore2,spGrid2]=...
    spiralCenterLowRes2nd(xOffsetGridGCD2,yOffsetGridGCD2,dataGrid2,mi.sensorType,fxLon,fxLat,filterRadiusDeg2,spiralSearchRadiusDeg2,spacingDeg2);

% Add in the penalty for distance from first guess:
penaltyFunctionGrid=DISTANCE_PENALTY_WEIGHT_2*(distanceDeg(fxLon,fxLat,lonGrid2,latGrid2)).^2; %%%%%%%%%%%%%%%%%%%% was 2
spScore2withPenalty=SPIRAL_WEIGHT*spGrid2-penaltyFunctionGrid-SPIRAL_OFFSET;
spiralScoreGrid=spScore2withPenalty;

fprintf(1,'done\n');

% Find the swarm of points to test for ringfitting:
spFitBuffer=1.5;
swarmReach=0.25;
insideBuffer=find(spScore2withPenalty > ...
    max(spScore2withPenalty(:)-spFitBuffer))';
inSwarm=false(size(latGrid2));
for buffInd=insideBuffer
    inThisSwarm= ...
        distanceDeg(lonGrid2(buffInd),latGrid2(buffInd),...
        lonGrid2,latGrid2) < swarmReach;
    inSwarm(inThisSwarm)=true;
end
swarmInds=find(inSwarm(:))';


% Ring Fit

% Parameters
minRadiusDeg=0.05; % Minimum ring radius (~0.05)
maxRadiusDeg=1.00; % Maximum ring radius (~0.40-1.00)

% Ring Fit: Calculations
[ringScoreGrid0, ringSizeMx]=...
    ringScoreCalc(yOffsetGridGCD2,xOffsetGridGCD2,...
    dataGrid2,mi.sensorType,swarmInds,minRadiusDeg,maxRadiusDeg);
latGrid2=yOffsetGridGCD2+spiralLatCenter1; % Yes, it's 1, not 2
lonGrid2=xOffsetGridGCD2/cos(pi*spiralLatCenter1/180)+spiralLonCenter1;

% Ring score scaling
ringScoreGrid=RING_WEIGHT*ringScoreGrid0;

end
