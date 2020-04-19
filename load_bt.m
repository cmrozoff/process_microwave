%
% Script to load best track data
%
addpath ships_developmental_data/
%
disp('Collecting best track data.')
%
if strcmp(basin, 'atl')
    load lsdiaga_1995_2019_sat_ts.mat
elseif strcmp(basin, 'ep')
    load lsdiage_1995_2019_sat_ts.mat
end
%
lat_bt = 0.1 * xx(:, 6, 3); 
lon_bt = -0.1 * xx(:, 7, 3);
date_bt = datenum(yr, mo, da, hr, 0, 0);
dl_bt = xx(:, 12, 3);
vmax_bt = xx(:, 2, 3);
stnam_bt = stnam;
%
clear vmax xx yr mo da hr stnam