function [timeS, lonS, latS, btS] = gmiReader(fileName)
%
% Read in GMI data
% 
% -----------------------------------------------------------------
%
% To find out information about what is in file, type the command
%  h5disp(fileName) at the command line. More info on mathworks.com
%
% Swath S1 has channels 1-9: 10V, 10H, 19V, 19H, 23V, 
%  37V, 37H, 89V, 89H
%
tb1 = double(h5read(fileName, '/S1/Tb'));
btS = squeeze(tb1(9, :, :));
latS = double(h5read(fileName, '/S1/Latitude'));
lonS = double(h5read(fileName, '/S1/Longitude'));
yr = double(h5read(fileName, '/S1/ScanTime/Year'));
mo = double(h5read(fileName, '/S1/ScanTime/Month'));
da = double(h5read(fileName, '/S1/ScanTime/DayOfMonth'));
hr = double(h5read(fileName, '/S1/ScanTime/Hour'));
mn = double(h5read(fileName, '/S1/ScanTime/Minute'));
sc = double(h5read(fileName, '/S1/ScanTime/Second'));
timeS = datenum([yr,mo,da,hr,mn,sc]);
%
return
end