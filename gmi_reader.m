function sat_data = gmi_reader(file_input)
%
% Reading in GMI HDF5 file
%
tb1 = double(h5read(file_input, '/S1/Tb'));
yr = double(h5read(file_input, '/S1/ScanTime/Year'));
mo = double(h5read(file_input, '/S1/ScanTime/Month'));
da = double(h5read(file_input, '/S1/ScanTime/DayOfMonth'));
hr = double(h5read(file_input, '/S1/ScanTime/Hour'));
mn = double(h5read(file_input, '/S1/ScanTime/Minute'));
sc = double(h5read(file_input, '/S1/ScanTime/Second'));
%
sat_data.lon = double(h5read(file_input, '/S1/Longitude'));
sat_data.lat = double(h5read(file_input, '/S1/Latitude'));
sat_data.bt19v = squeeze(tb1(3, :, :));
sat_data.bt19h = squeeze(tb1(4, :, :));
sat_data.bt37v = squeeze(tb1(5, :, :));
sat_data.bt37h = squeeze(tb1(6, :, :));
sat_data.lon85 = double(h5read(file_input, '/S1/Longitude'));
sat_data.lat85 = double(h5read(file_input, '/S1/Latitude'));
sat_data.bt85v = squeeze(tb1(8, :, :));
sat_data.bt85h = squeeze(tb1(9, :, :));
sat_data.time_lo = datenum([yr,mo,da,hr,mn,sc]);
sat_data.time_hi = datenum([yr,mo,da,hr,mn,sc]);
%
return
end