function [interpLat,interpLon,interpSpd,translationSpeed_knots,...
    translationSpeedX_knots,translationSpeedY_knots]=trackInterpolatorTrans(tcName, tcTime)

[yyyy mm dd hh mn ss lat lon spd]=textread(['cyclones/' tcName '/track/latestTrack.txt'],'%d %d %d %d %d %d %f %f %d','delimiter',' ');
tcDates=datenum(yyyy,mm,dd,hh,mn,ss);

if tcTime>=tcDates(1) & tcTime<=tcDates(end)
    interpLat=interp1(tcDates,lat,tcTime,'cubic');
    interpLon=interp1(tcDates,lon,tcTime,'cubic');
    interpSpd=interp1(tcDates,spd,tcTime,'cubic');
elseif tcTime<tcDates(1);
    interpLat=interp1(tcDates,lat,tcTime,'linear','extrap');
    interpLon=interp1(tcDates,lon,tcTime,'linear','extrap');
    interpSpd=spd(1);
elseif tcTime>tcDates(end)
    interpLat=interp1(tcDates,lat,tcTime,'linear','extrap');
    interpLon=interp1(tcDates,lon,tcTime,'linear','extrap');
    interpSpd=spd(end); 
end

% Compute the translation speed (speed of the center of rotation)
delLat=lat(2:end)-lat(1:end-1);
delLon=lon(2:end)-lon(1:end-1);
delTime=tcDates(2:end)-tcDates(1:end-1);
midTime=0.5*(tcDates(2:end)+tcDates(1:end-1));

interpDelLat=interp1(midTime,delLat,tcTime,'nearest','extrap');
interpDelLon=interp1(midTime,delLon,tcTime,'nearest','extrap');
interpDelTime=interp1(midTime,delTime,tcTime,'nearest','extrap');

interpDelLat_nm=interpDelLat*60;
interpDelLon_nm=interpDelLon*60*cos(interpLat/180*pi);
interpDisplacement_nm=(interpDelLat_nm^2+interpDelLon_nm^2)^0.5;
interpDelTime_hrs=interpDelTime*24;
translationSpeed_knots=interpDisplacement_nm/interpDelTime_hrs;

translationSpeedX_knots=interpDelLon_nm/interpDelTime_hrs;
translationSpeedY_knots=interpDelLat_nm/interpDelTime_hrs;



