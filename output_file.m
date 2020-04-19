%
% Create storm-centered polar analyses of Tbs with 5-km radial spacing
%  and 5-degree azimuthal spacing
%
% The domain of these analyses is 600 km in radius
%
% Create name of output file
disp('  - Creating output files:')
%
% Polar grid parameters
nlambda = 72;
rmax = 600.0 / 111.12; % ~km extent of domain
dr = 5 / 111.12; % ~km grid spacing
%
time_file = mean(sat_sub.time_hi);
[yr_file, mo_file, da_file, hr_file, mn_file, sc_file] = ...
    datevec(time_file);
%
mofil = ''; dafil = ''; hrfil = ''; mnfil = '';
if mo_file < 10; mofil = '0'; end
if da_file < 10; dafil = '0'; end
if hr_file < 10; hrfil = '0'; end
if mn_file < 10; mnfil = '0'; end
%
file_mat = [char(stnam_sub(istm)) '_' num2str(yr_file) ...
    mofil num2str(mo_file) dafil num2str(da_file) '_' ...
    hrfil num2str(hr_file) mnfil num2str(mn_file) ...
    '_' img_sensor '.mat'];
file_mat_calib = [char(stnam_sub(istm)) '_' num2str(yr_file) ...
    mofil num2str(mo_file) dafil num2str(da_file) '_' ...
    hrfil num2str(hr_file) mnfil num2str(mn_file) ...
    '_' img_sensor '_calib.mat'];
%
disp(['      ' file_mat ' + ' file_mat_calib])
%
% Create grid in polar coordinates
%
disp('   * Constructing polar grid with a fixed number of')
disp('      radial and azimuthal points')
%
rmin = dr;
dlambda = 360. / nlambda;
lambda = 0:dlambda:(360 - dlambda);
%
xc = out37.finalLon; yc = out37.finalLat;
radius_array = rmin:dr:rmax;
%
lon_disk = zeros(length(radius_array), length(lambda));
lat_disk = zeros(length(radius_array), length(lambda));
%
ri = 0;
for rad_step = radius_array
    ri = ri + 1;
    lon_disk(ri, :) = xc + cosd(lambda) * rad_step / cosd(yc);
    lat_disk(ri, :) = yc + sind(lambda) * rad_step;
end
%
% Interpolate data to disks
%
disp('   * Regridding low-resolution data')
disk.bt19h = griddata(sat_sub.lon, sat_sub.lat, ...
    sat_sub.bt19h, lon_disk, lat_disk, 'linear');
disk.bt19v = griddata(sat_sub.lon, sat_sub.lat, ...
    sat_sub.bt19v, lon_disk, lat_disk, 'linear');
disk.bt37h = griddata(sat_sub.lon, sat_sub.lat, ...
    sat_sub.bt37h, lon_disk, lat_disk, 'linear');
disk.bt37v = griddata(sat_sub.lon, sat_sub.lat, ...
    sat_sub.bt37v, lon_disk, lat_disk, 'linear');
disk.pct37 = griddata(sat_sub.lon, sat_sub.lat, ...
    sat_sub.pct37, lon_disk, lat_disk,'linear');
disk.lon = lon_disk;
disk.lat = lat_disk;
%
disk_calib.bt19h = griddata(sat_sub.lon, sat_sub.lat, ...
    sat_sub_calib.bt19h, lon_disk, lat_disk, 'linear');
disk_calib.bt19v =  griddata(sat_sub.lon, sat_sub.lat, ...
    sat_sub_calib.bt19v, lon_disk, lat_disk, 'linear');
disk_calib.bt37h = griddata(sat_sub.lon, sat_sub.lat, ...
    sat_sub_calib.bt37h, lon_disk, lat_disk, 'linear');
disk_calib.bt37v = griddata(sat_sub.lon, sat_sub.lat, ...
    sat_sub_calib.bt37v, lon_disk, lat_disk, 'linear');
disk_calib.pct37 = griddata(sat_sub.lon, sat_sub.lat, ...
    sat_sub_calib.pct37, lon_disk, lat_disk,'linear');
disk_calib.lon = lon_disk;
disk_calib.lat = lat_disk;
%
nlambda = nlambda * 2;
dr = dr / 2;
rmin = dr;
dlambda = 360. / nlambda;
radius_array = rmin:dr:rmax;
lambda = 0:dlambda:(360 - dlambda);
%
xc = out85.finalLon; yc = out85.finalLat;
lon_disk85 = zeros(length(radius_array), length(lambda));
lat_disk85 = zeros(length(radius_array), length(lambda));
ri = 0;
for rad_step = radius_array
    ri = ri + 1;
    lon_disk85(ri, :) = xc + cosd(lambda) * rad_step / cosd(yc);
    lat_disk85(ri, :) = yc + sind(lambda) * rad_step;
end
%
% Interpolate data to disks
%
disp('   * Regridding high-resolution data')
disk.bt85h = griddata(sat_sub.lon85, sat_sub.lat85, sat_sub.bt85h, ...
    lon_disk85, lat_disk85, 'linear');
disk.bt85v = griddata(sat_sub.lon85, sat_sub.lat85, sat_sub.bt85v, ...
   lon_disk85, lat_disk85, 'linear');
disk.pct85 = griddata(sat_sub.lon85, sat_sub.lat85, sat_sub.pct85, ...
   lon_disk85, lat_disk85, 'linear');
disk.lon85 = lon_disk85;
disk.lat85 = lat_disk85;

%
stnam_out = stnam_sub(istm);
%
file_mat = ['polar_files/' basin '/' file_mat];
save(file_mat, 'sat_sub', 'disk', 'stnam_out', 'time_file', ...
    'out37', 'out85')
%
if ~strcmp(img_sensor, 'AMSRE') && ~strcmp(img_sensor, 'AMSR2') && ...
        ~strcmp(img_sensor, 'GMI')
    file_mat_calib = ['polar_files/' basin '/' file_mat_calib];
    disk_calib.bt85h = griddata(sat_sub.lon85, sat_sub.lat85, ...
        sat_sub_calib.bt85h, lon_disk85, lat_disk85, 'linear');
    disk_calib.bt85v = griddata(sat_sub.lon85, sat_sub.lat85, ...
        sat_sub_calib.bt85v, lon_disk85, lat_disk85, 'linear');
    disk_calib.pct85 = griddata(sat_sub.lon85, sat_sub.lat85, ...
        sat_sub_calib.pct85, lon_disk85, lat_disk85, 'linear');
    disk_calib.lon85 = lon_disk85;
    disk_calib.lat85 = lat_disk85;
    save(file_mat_calib, 'sat_sub_calib', 'disk_calib', 'stnam_out', ...
    'time_file', 'out37', 'out85')
end

%
clear nlambda ri rmin rmax *_file lon_disk* lat_disk* xc yc
clear radius_array dlambda lambda dr out* rad_step file_mat*
clear stnam_out