function out = defAsciiReader(inputDir, yearNum, useDisplay)
%
% defAsciiReader.m: Read output from def_decoderAJW.c into matlab
%
% Anthony Wimmers (CIMSS)
% March, 2012
%
% Input the low res navigation
lat1Mx = load([inputDir '/outputLAT1.dat'])/100-90;
lon1Mx = load([inputDir '/outputLON1.dat'])/100;
% Translate to our coordinate system (lon is from -180 to 180):
lon1Mx(lon1Mx(:)>180) = lon1Mx(lon1Mx(:)>180)-360;

% Calculate the scan times
% (Year number has to be user-defined because it's not in the file's data)
% (During a year-crossing, make sure that the julian day at the end time is
% the number for Dec31+1.)
timeGrid = load([inputDir '/outputTIMES.dat']);
startTime = datenum(yearNum, 1, timeGrid(1,1), ...
    timeGrid(1,2), timeGrid(1,3), timeGrid(1,4));
endingTime = datenum(yearNum, 1, timeGrid(2,1), ...
    timeGrid(2,2), timeGrid(2,3), timeGrid(2,4));

[numRowsLoRes, numColsLoRes] = size(lat1Mx);

% Output the lo res scan time array:
out.scanTimeLoResArr = interp1([1 numRowsLoRes], [startTime endingTime], ...
    1:numRowsLoRes)';

% Output the low res matrices:
out.latMxLoRes = lat1Mx;
out.lonMxLoRes = lon1Mx;

out.t19vMxLoRes = load([inputDir '/outputT19V1.dat'])/100;
out.t19hMxLoRes = load([inputDir '/outputT19H1.dat'])/100;
out.t22vMxLoRes = load([inputDir '/outputT22V1.dat'])/100;
out.t37vMxLoRes = load([inputDir '/outputT37V1.dat'])/100;
out.t37hMxLoRes = load([inputDir '/outputT37H1.dat'])/100;

% Input the low-res form of the 85GHz data:
t85v1Mx = load([inputDir '/outputT85V1.dat'])/100;
t85h1Mx = load([inputDir '/outputT85H1.dat'])/100;

out.t85vMxLoRes = t85v1Mx;
out.t85hMxLoRes = t85h1Mx;

% Input the rest of the hi-res 85GHz data:
lat2Mx = load([inputDir '/outputLAT2.dat'])/100-90;
lon2Mx = load([inputDir '/outputLON2.dat'])/100;
t85v2Mx = load([inputDir '/outputT85V2.dat'])/100;
t85h2Mx = load([inputDir '/outputT85H2.dat'])/100;

lat3Mx = load([inputDir '/outputLAT3.dat'])/100-90;
lon3Mx = load([inputDir '/outputLON3.dat'])/100;
t85v3Mx = load([inputDir '/outputT85V3.dat'])/100;
t85h3Mx = load([inputDir '/outputT85H3.dat'])/100;

lat4Mx = load([inputDir '/outputLAT4.dat'])/100-90;
lon4Mx = load([inputDir '/outputLON4.dat'])/100;
t85v4Mx = load([inputDir '/outputT85V4.dat'])/100;
t85h4Mx = load([inputDir '/outputT85H4.dat'])/100;

% Build the hi-res scan time array:
out.scanTimeHiResArr = interp1([1 2*numRowsLoRes-1], [startTime endingTime], ...
    1:2*numRowsLoRes, 'linear', 'extrap')';

% Build the hi-res matrices

latMx = zeros(numRowsLoRes*2,numColsLoRes*2); % Initialize
lonMx = latMx;
v85Mx = latMx;
h85Mx = latMx;

latMx(1:2:end,1:2:end) = lat1Mx;
lonMx(1:2:end,1:2:end) = lon1Mx;
v85Mx(1:2:end,1:2:end) = t85v1Mx;
h85Mx(1:2:end,1:2:end) = t85h1Mx;

latMx(2:2:end,1:2:end) = lat2Mx;
lonMx(2:2:end,1:2:end) = lon2Mx;
v85Mx(2:2:end,1:2:end) = t85v2Mx;
h85Mx(2:2:end,1:2:end) = t85h2Mx;

latMx(1:2:end,2:2:end) = lat3Mx;
lonMx(1:2:end,2:2:end) = lon3Mx;
v85Mx(1:2:end,2:2:end) = t85v3Mx;
h85Mx(1:2:end,2:2:end) = t85h3Mx;

latMx(2:2:end,2:2:end) = lat4Mx;
lonMx(2:2:end,2:2:end) = lon4Mx;
v85Mx(2:2:end,2:2:end) = t85v4Mx;
h85Mx(2:2:end,2:2:end) = t85h4Mx;

% Translate to our favored coordinate system (lon is from -180 to 180):
lonMx(lonMx(:)>180) = lonMx(lonMx(:)>180)-360;

out.latMxHiRes = latMx;
out.lonMxHiRes = lonMx;
out.t85vMxHiRes = v85Mx;
out.t85hMxHiRes = h85Mx;


if useDisplay
    
    figure(1); clf;
    colormap(flipud(jet))
    pcolorCentered(lon1Mx,lat1Mx,(t85h1Mx)); hold on;
    caxis([100 280])
    axis([-180 180 -90 90])
    title('  Half-res 85GHz(H)  ');
    colorbar
    
    figure(2); clf;
    colormap(flipud(jet))
    pcolorCentered(lonMx,latMx,h85Mx); hold on;
    caxis([100 280])
    axis([-180 180 -90 90])
    title('  Full-res 85GHz(H)  ');
    colorbar
    
end

