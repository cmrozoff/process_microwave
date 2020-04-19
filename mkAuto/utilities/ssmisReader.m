function ssmisData = ssmisReader(fileName)
%
% Read SSMI/S file
%
% Input date / time
%
secsAfter1987 = ncread(fileName,'scan_time_since87_environ');
escanTimeArr = datenum(1987,1,1,0,0,secsAfter1987);
secsAfter1987 = ncread(fileName, 'scan_time_since87_imager');
escanTimeArr85 = datenum(1987,1, 1, 0,0, secsAfter1987);
%
% input lat / lon
%
lon = ncread(fileName,'environmental_lon');
lat = ncread(fileName,'environmental_lat');
%
% input environmental brightnes
%
bt = ncread(fileName,'environmental_temperatures');
bt19h = squeeze(bt(1, :, :));
bt19v = squeeze(bt(2, :, :));
bt37h = squeeze(bt(4, :, :));
bt37v = squeeze(bt(5, :, :));
%
% lat / lon for imager channels
%
lon85 = ncread(fileName,'imager_lon');
lat85 = ncread(fileName,'imager_lat');
%
bt = ncread(fileName,'imager_temperatures');
bt85h = squeeze(bt(6, :, :));
bt85v = squeeze(bt(5, :, :));
%
ssmisData.lon = lon;
ssmisData.lat = lat;
ssmisData.bt19V = bt19v;
ssmisData.bt19H = bt19h;
ssmisData.bt37V = bt37v;
ssmisData.bt37H = bt37h;
ssmisData.scanTime = escanTimeArr;
ssmisData.bt85H = bt85h;
ssmisData.bt85V = bt85v;
ssmisData.scanTime85 = escanTimeArr85;
ssmisData.lon85 = lon85;
ssmisData.lat85 = lat85;
%
return
end

