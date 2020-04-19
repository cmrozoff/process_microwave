function sat_data = ssmis_reader(file_input)
%
% Determind file type and carry out read depending on file type
%
[pathstr,name,ext] = fileparts(file_input);
if strcmp(ext, '.nc')
    disp([' .nc type file detected.'])
    %
    % Reading in netCDF file containing SSMIS data
    %
    % Input date / time
    %
    secsAfter1987 = ncread(file_input,'scan_time_since87_environ');
    escanTimeArr = datenum(1987,1,1,0,0,secsAfter1987);
    secsAfter1987 = ncread(file_input, 'scan_time_since87_imager');
    escanTimeArr85 = datenum(1987,1, 1, 0,0, secsAfter1987);
    %
    % input lat / lon
    %
    lon = ncread(file_input,'environmental_lon');
    lat = ncread(file_input,'environmental_lat');
    %
    % input environmental brightnes
    %
    bt = ncread(file_input,'environmental_temperatures');
    bt19h = squeeze(bt(1, :, :));
    bt19v = squeeze(bt(2, :, :));
    bt37h = squeeze(bt(4, :, :));
    bt37v = squeeze(bt(5, :, :));
    %
    indkeep = [];
    for ilores = 1:length(bt19v(1, :))
        if (sum(diff(bt19v(:, ilores))) ~= 0)
            indkeep = [indkeep ; ilores];
        end
    end
    %
    % lat / lon for imager channels
    %
    lon85 = ncread(file_input,'imager_lon');
    lat85 = ncread(file_input,'imager_lat');
    %
    bt = ncread(file_input,'imager_temperatures');
    bt85h = squeeze(bt(6, :, :));
    bt85v = squeeze(bt(5, :, :));
    %
    sat_data.lon = lon(:, indkeep);
    sat_data.lat = lat(:, indkeep);
    sat_data.bt19v = bt19v(:, indkeep);
    sat_data.bt19h = bt19h(:, indkeep);
    sat_data.bt37v = bt37v(:, indkeep);
    sat_data.bt37h = bt37h(:, indkeep);
    sat_data.time_lo = escanTimeArr(indkeep);
    sat_data.bt85h = bt85h;
    sat_data.bt85v = bt85v;
    sat_data.time_hi = escanTimeArr85;
    sat_data.lon85 = lon85;
    sat_data.lat85 = lat85;
    %
elseif strcmp(ext, '.mat')
    disp([' .mat type file detected.'])
    %
    % Reading in matlab file containing SSMIS data
    %
    load(file_input)
    %
    % Apply correction to low-res data
    indkeep = [];
    for ilores = 1:length(bt19v(1, :))
        if (sum(diff(bt19v(:, ilores))) ~= 0)
            indkeep = [indkeep ; ilores];
        end
    end
    %
    sat_data.lon = lon(:, indkeep);
    sat_data.lat = lat(:, indkeep);
    sat_data.bt19v = bt19v(:, indkeep);
    sat_data.bt19h = bt19h(:, indkeep);
    sat_data.bt37v = bt37v(:, indkeep);
    sat_data.bt37h = bt37h(:, indkeep);
    sat_data.bt85v = bt85v;
    sat_data.bt85h = bt85h;
    sat_data.lat85 = lat85;
    sat_data.lon85 = lon85;
    sat_data.time_lo = time85(1:length(squeeze(lon(1, indkeep))));
    sat_data.time_hi = time85;
    %
    clear lon* lat* bt*v bt*h time85 indkeep ilores
else
    error('A foreign file suffix name has caused this program to crash.')
end
%
return
end
