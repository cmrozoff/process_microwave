function sat_data = amsr2_reader(file_input)
%
% Read in AMSR2 hdf5 data
%
sat_data.bt19h = double(h5read(file_input, ...
    '/Brightness Temperature (18.7GHz,H)')) * 0.01;
sat_data.bt19v = double(h5read(file_input, ...
    '/Brightness Temperature (18.7GHz,V)')) * 0.01;
sat_data.bt37h = double(h5read(file_input, ...
    '/Brightness Temperature (36.5GHz,H)')) * 0.01;
sat_data.bt37v = double(h5read(file_input, ...
    '/Brightness Temperature (36.5GHz,V)')) * 0.01;
sat_data.bt85h = double(h5read(file_input, ...
    '/Brightness Temperature (89.0GHz-A,H)')) * 0.01; % B offers different
                                                      % FOV
sat_data.bt85v = double(h5read(file_input, ...
    '/Brightness Temperature (89.0GHz-A,V)')) * 0.01; 
sat_data.lon85 = ...
    double(h5read(file_input, '/Longitude of Observation Point for 89B'));
sat_data.lat85 = ...
    double(h5read(file_input, '/Latitude of Observation Point for 89B'));
lon = sat_data.lon85;
lat = sat_data.lat85;
sat_data.lon = 0.5 * (lon(1:2:end-1, :) + lon(2:2:end, :));
sat_data.lat = 0.5 * (lat(1:2:end-1, :) + lat(2:2:end, :));

time_start = char(h5readatt(file_input, '/', 'ObservationStartDateTime'));
time_end = char(h5readatt(file_input, '/', 'ObservationEndDateTime'));
yr1 = str2num(time_start(1:4)); yr2 = str2num(time_end(1:4));
mo1 = str2num(time_start(6:7)); mo2 = str2num(time_end(6:7));
da1 = str2num(time_start(9:10)); da2 = str2num(time_end(9:10));
hr1 = str2num(time_start(12:13)); hr2 = str2num(time_end(12:13));
mn1 = str2num(time_start(15:16)); mn2 = str2num(time_end(15:16));
sc1 = str2num(time_start(18:23)); sc2 = str2num(time_end(18:23));
time_start = datenum(yr1, mo1, da1, hr1, mn1, sc1);
time_end = datenum(yr2, mo2, da2, hr2, mn2, sc2);
ntimes = length(squeeze(lon(1,:)));
sat_data.time_lo = ...
    [time_start:((time_end-time_start)/(ntimes-1)):time_end]';
sat_data.time_hi = sat_data.time_lo;
%
return
end