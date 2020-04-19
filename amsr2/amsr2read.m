function [timeS, lonS, latS, btS] = amsr2read(fileName);
%
% Read AMSR2 h5 file
% 
% -------------------------------------------------------------------------
%
btS = double(h5read(fileName, ...
    '/Brightness Temperature (89.0GHz-A,V)')) * 0.01;
lonS = double(h5read(fileName, '/Longitude of Observation Point for 89A'));
latS = double(h5read(fileName, '/Latitude of Observation Point for 89A'));
time_start = char(h5readatt(fileName, '/', 'ObservationStartDateTime'));
time_end = char(h5readatt(fileName, '/', 'ObservationEndDateTime'));
yr1 = str2num(time_start(1:4)); yr2 = str2num(time_end(1:4));
mo1 = str2num(time_start(6:7)); mo2 = str2num(time_end(6:7));
da1 = str2num(time_start(9:10)); da2 = str2num(time_end(9:10));
hr1 = str2num(time_start(12:13)); hr2 = str2num(time_end(12:13));
mn1 = str2num(time_start(15:16)); mn2 = str2num(time_end(15:16));
sc1 = str2num(time_start(18:23)); sc2 = str2num(time_end(18:23));
time_start = datenum(yr1, mo1, da1, hr1, mn1, sc1);
time_end = datenum(yr2, mo2, da2, hr2, mn2, sc2);
ntimes = length(squeeze(lonS(1,:)));
timeS = [time_start:((time_end-time_start)/(ntimes-1)):time_end]';
%
return
end