function [interpLon,interpLat,interpSpd,translationSpeedX_knots,translationSpeedY_knots] = ...
    reconInterp(d,reqTCnum,reqTime)

% Test the right way to interpolate on the tracks. Cubic if it's inside the
% available segments, NaN if it's outside

%d: Data structure of the year of recon'd track parts
%reqTCnum: TC number requested
%reqTime: Time of interpolation requested

dv=datevec(d.tcTime);
yearArr=dv(:,1);
dv=datevec(reqTime);
reqYear=dv(1);
reqRows=find(d.tcNum==reqTCnum & strcmp(d.basinName,'AL') & yearArr==reqYear);

delLat=d.reconLat(reqRows(2:end))-d.reconLat(reqRows(1:end-1));
delLon=d.reconLon(reqRows(2:end))-d.reconLon(reqRows(1:end-1));
delTime=d.tcTime(reqRows(2:end))-d.tcTime(reqRows(1:end-1));
midTime=(d.tcTime(reqRows(2:end))+d.tcTime(reqRows(1:end-1)))/2;

dtHr=reqTime-d.tcTime(reqRows);
dtHrBeforArr=-dtHr(dtHr<=0);
dtHrAfterArr=+dtHr(dtHr>=0);
dtHrBefor=min(dtHrBeforArr);
dtHrAfter=min(dtHrAfterArr);

%biggestDtHr=24*max([dtHrBefor dtHrAfter]);
gapDtHr=24*(dtHrBefor+dtHrAfter);

if gapDtHr<1.01
    interpLon=interp1(d.tcTime(reqRows),d.reconLon(reqRows),reqTime,'cubic',NaN);
    interpLat=interp1(d.tcTime(reqRows),d.reconLat(reqRows),reqTime,'cubic',NaN);
    interpSpd=interp1(d.tcTime(reqRows),d.reconWspdKts(reqRows),reqTime,'cubic',NaN);
    interpDelLat=interp1(midTime,delLat,reqTime,'nearest','extrap');
    interpDelLon=interp1(midTime,delLon,reqTime,'nearest','extrap');
    interpDelTime=interp1(midTime,delTime,reqTime,'nearest','extrap');
    interpDelLat_nm=interpDelLat*60;
    interpDelLon_nm=interpDelLon*60*cos(interpLat/180*pi);
    interpDelTime_hrs=interpDelTime*24;
    translationSpeedX_knots=interpDelLon_nm/interpDelTime_hrs;
    translationSpeedY_knots=interpDelLat_nm/interpDelTime_hrs;
else
    interpLon=NaN;
    interpLat=NaN;
    interpSpd=NaN;
    translationSpeedX_knots=NaN;
    translationSpeedY_knots=NaN;
end

