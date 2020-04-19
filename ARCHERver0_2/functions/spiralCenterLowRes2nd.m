function [spX,spY,spScore,spGrid]=...
    spiralCenterLowRes(xG,yG,mapG,sensorType,fxLon,fxLat,filterRadiusDeg,searchRadiusDeg,spacingDeg)

% Calculates the "spiral center" using the cross product of
% gradient and 10-degree spiral vector

% Settings:
alpha=5*pi/180; % For a 5-degree log spiral (formerly 10-degree)
outSideFactor=0.62; % Weight to put on the gradients in outer rims (1 for inner rims)
% Input:
% xG, yG - x,y coordinate grids in degrees, normally in great circle degrees,
%   offset from a best-guess center point (0,0)
% mapG - image, mapped to xG and yG
% sensorType - '85-92GHz', '37GHz' or 'IR'. '37GHz' uses different rules
% filterRadiusDeg - radius of relevant information for algorithm
% searchRadiusDeg - radius of candidate points for spiral center
% spacingDeg - increment of candidate point spacing
% Output:
% spX,spY - spiral center coordinates in xG, yG space
% spScore - spiral score at (spX,spY)
% spGrid - grid whose contour shows a bulls-eye at (spX,spY)

warning off MATLAB:divideByZero % saves warning on "spiralXClean=" and "spiralYClean=" lines

% Add step for 37GHz:
if strcmp(sensorType,'37GHz')
    mapG=-mapG;
end

% Cut down to a usable disk, surrounded by NaN's
inFilterDisk=(xG.^2+yG.^2)<=filterRadiusDeg^2;
diskImg=NaN*mapG;
diskImg(inFilterDisk)=mapG(inFilterDisk);

% Make 1-D arrays of just the clean points. "clean" means no nans
cleanInds=find(~isnan(diskImg));
%fractionOfPtsInDiskThatAreNotNans=length(cleanInds)/sum(inFilterDisk(:))
diskImgClean=diskImg(cleanInds);
xGClean=xG(cleanInds);
yGClean=yG(cleanInds);
lonInc=xG(1,2)-xG(1,1); latInc=yG(1,1)-yG(2,1);
[gradE,gradN]=gradient(diskImg,lonInc,latInc);
gradN=-gradN; % Because image is upside-down; % East adjustment is not nec. over 10 degrees
gradNclean=gradN(cleanInds);
gradEclean=gradE(cleanInds);
gradOrigMagClean=sqrt(gradNclean.^2+gradEclean.^2);
gradLogMagClean=log(1+gradOrigMagClean);
gradLogReductionClean=gradLogMagClean./gradOrigMagClean;
gradNLogClean=gradLogReductionClean.*gradNclean; % Scaled down to log(1+magnitude)
gradELogClean=gradLogReductionClean.*gradEclean;

% 1. Iterate the cross product score on a coarse grid
allCenterXs=[]; allCenterYs=[]; allCenterMeanCross=[];
% Search out (searchRadiusDeg) degrees from the center point
for xOff=-searchRadiusDeg:spacingDeg:searchRadiusDeg
    for yOff=-searchRadiusDeg:spacingDeg:searchRadiusDeg
        if (xOff^2+yOff^2)>(searchRadiusDeg+2*spacingDeg/3)^2
            % (...then do nothing. This takes out the corners to save time.)
        else
            proxyXClean=xGClean-xOff;
            proxyYClean=yGClean-yOff;
            
            spiralXClean=(alpha*proxyXClean+sign(fxLat)*proxyYClean)...
                ./sqrt((1+alpha^2)*(proxyXClean.^2+proxyYClean.^2));
            spiralYClean=(alpha*proxyYClean-sign(fxLat)*proxyXClean)...
                ./sqrt((1+alpha^2)*(proxyXClean.^2+proxyYClean.^2)); %Unit vector field in great circle degrees
            
            rawCrossScore=spiralXClean.*gradNLogClean-spiralYClean.*gradELogClean;
            crossScoreClean=max(0, -(rawCrossScore) )+outSideFactor*max(0,rawCrossScore); 
            isNanCross=isnan(rawCrossScore);
            crossScoreClean(isNanCross)=NaN;
            %normMeanCrossScoreClean=nanmean(crossScoreClean); 
            normMeanCrossScoreClean=mean(crossScoreClean(~isnan(crossScoreClean))); %/fractionOfPtsInDiskThatAreNotNans;
            
            allCenterMeanCross=[allCenterMeanCross; normMeanCrossScoreClean];
            allCenterXs=[allCenterXs; xOff];
            allCenterYs=[allCenterYs; yOff];
        end
    end
end

% 2. Search for the best full-resolution gridcell by cubic interpolation:
spGrid=griddata(allCenterXs,allCenterYs,allCenterMeanCross,xG,yG,'cubic');
spScore=max(spGrid(~isnan(spGrid(:))));
spScoreIndex=find(spGrid(:)==spScore);
spX=xG(spScoreIndex(1));
spY=yG(spScoreIndex(1));
