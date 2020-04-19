function [newLonMx,newLatMx] = geostatParallaxCorrection(lonMx,latMx,nadirLon,featureHeight)
%
% Creates a new navigation for geostationary images corrected for parallax.
% "featureHeight" is in kilometers
%
% Created by Tony Wimmers (CIMSS) 2005

xre=6370*cos(pi/180*latMx).*cos(pi/180*lonMx);
yre=6370*cos(pi/180*latMx).*sin(pi/180*lonMx);
zre=6370*sin(pi/180*latMx);
xrd=(35788+6370)*cos(nadirLon*pi/180)-xre;
yrd=(35788+6370)*sin(nadirLon*pi/180)-yre;
zrd=-zre;
remag=sqrt((xre.^2)+(yre.^2)+(zre.^2));
rdmag=sqrt((xrd.^2)+(yrd.^2)+(zrd.^2));
cosz=(xre.*xrd+yre.*yrd+zre.*zrd)./(remag.*rdmag);
delX=featureHeight*tan(acos(cosz));

gcAzimuth=azimuth(zeros(size(latMx)),nadirLon*ones(size(latMx)),latMx,lonMx);
[newLatMx,newLonMx]=reckon(latMx, lonMx, -km2deg(delX), gcAzimuth); % Corrected the sign error 12/02/05 2:00p CST