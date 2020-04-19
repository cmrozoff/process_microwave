function ssmiData = ssmiReader(fileName)
%
% Read SSM/I (F15) file
%
disp(['Opening file ' fileName])
%
% Input date / time
%
secsAfter1987 = ncread(fileName,'scan_time_since87_lores');
escanTimeArr = datenum(1987,1, 1, 0,0, secsAfter1987);
secsAfter1987 = ncread(fileName,'scan_time_since87_hires');
escanTimeArr85 = datenum(1987,1, 1, 0,0, secsAfter1987);
%
% lat / lon for imager channels
%
lon = ncread(fileName,'longitude_lores');
lat = ncread(fileName,'latitude_lores');
% 
bt = ncread(fileName,'temperatures_lores');
bt19h = squeeze(bt(2, :, :));
bt19v = squeeze(bt(1, :, :));
bt37h = squeeze(bt(5, :, :));
bt37v = squeeze(bt(4, :, :));
%
% lat / lon for imager channels
%
lon85 = ncread(fileName, 'longitude_hires');
lat85 = ncread(fileName, 'latitude_hires');
%
bt = ncread(fileName,'temperatures_hires');
bt85h = squeeze(bt(2, :, :)); 
bt85v = squeeze(bt(1, :, :)); 
%
ssmiData.lon = lon;
ssmiData.lat = lat;
ssmiData.bt19V = bt19v;
ssmiData.bt19H = bt19h; 
ssmiData.bt37V = bt37v;
ssmiData.bt37H = bt37h;
ssmiData.scanTime = escanTimeArr;
ssmiData.bt85H = bt85h;
ssmiData.bt85V = bt85v;
ssmiData.scanTime85 = escanTimeArr85;
ssmiData.lon85 = lon85;
ssmiData.lat85 = lat85;
%
return
end

