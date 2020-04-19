function sat_data = qc_satellite_data(sat_data, img_sensor)
%
% Apply unique sensor quality control
%
disp(' Conducting simple quality control of data')
% 
%  - determine sensor
if strcmp(img_sensor, 'AMSRE') ...
        || strcmp(img_sensor, 'AMSR2') ...
        || strcmp(img_sensor, 'GMI') ...
        || strcmp(img_sensor, 'TMI')
    %
    ind = find(sat_data.bt19h == 0); sat_data.bt19h(ind) = NaN;
    ind = find(sat_data.bt19v == 0); sat_data.bt19v(ind) = NaN;
    ind = find(sat_data.bt37h == 0); sat_data.bt37h(ind) = NaN;
    ind = find(sat_data.bt37v == 0); sat_data.bt37v(ind) = NaN;
    ind = find(sat_data.bt85h == 0); sat_data.bt85h(ind) = NaN;
    ind = find(sat_data.bt85v == 0); sat_data.bt85v(ind) = NaN;
    %
end
%
ind = find(sat_data.bt19h >= 333.15 | sat_data.bt19h <= 78.15);
sat_data.bt19h(ind) = NaN;
ind = find(sat_data.bt19v >= 333.15 | sat_data.bt19v <= 78.15);
sat_data.bt19v(ind) = NaN;
ind = find(sat_data.bt37h >= 333.15 | sat_data.bt37h <= 78.15);
sat_data.bt37h(ind) = NaN;
ind = find(sat_data.bt37v >= 333.15 | sat_data.bt37v <= 78.15);
sat_data.bt37v(ind) = NaN;
ind = find(sat_data.bt85h >= 333.15 | sat_data.bt85h <= 78.15);
sat_data.bt85h(ind) = NaN;
ind = find(sat_data.bt85v >= 333.15 | sat_data.bt85v <= 78.15);
sat_data.bt85v(ind) = NaN;
%
% Fix time glitch in some of the SSMI/SSMIS files
if strcmp(img_sensor, 'SSMI') || strcmp(img_sensor, 'SSMIS')
    %
    ind = find(sat_data.time_lo(2:end) - sat_data.time_lo(1:end-1)~=0);
    if ~isempty(ind)
        sat_data.time_lo = sat_data.time_lo(ind);
        sat_data.lon = sat_data.lon(:, ind);
        sat_data.lat = sat_data.lat(:, ind);
        sat_data.bt19h = sat_data.bt19h(:, ind);
        sat_data.bt19v = sat_data.bt19v(:, ind);
        sat_data.bt37h = sat_data.bt37h(:, ind);
        sat_data.bt37v = sat_data.bt37v(:, ind);
        ind = find(sat_data.time_hi(2:end)-sat_data.time_hi(1:end-1)~=0);
        sat_data.time_hi = sat_data.time_hi(ind);
        sat_data.lon85 = sat_data.lon85(:, ind);
        sat_data.lat85 = sat_data.lat85(:, ind);
        sat_data.bt85h = sat_data.bt85h(:, ind);
        sat_data.bt85v = sat_data.bt85v(:, ind);
    end
    %
end
%
return
end