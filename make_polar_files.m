%
% Create storm-centered polar analyses of Tb with
%  4-km radial spacing and 10-degree azimuthal spacing
%
% The domain of these analyses is 600 km in radius.
%
% -----------------------------------------------------
%
% User set parameters
% -------------------
%
img_sensor = 'GMI';
basin = 'ep';
%
disp(' ')
disp(['Processing ' img_sensor ' data for the ' basin ' basin.'])
disp(' ')
%
% Determine base directory for input data
%
if strcmp(img_sensor, 'AMSR2')
    base = ['amsr2/' basin '/'];
    sat_files = dir([base 'GW1AM2_*']);
elseif strcmp(img_sensor, 'GMI')
    base = ['gmi/' basin '/'];
    sat_files = dir([base '1B.GPM.GMI.*HDF5']);
elseif strcmp(img_sensor, 'SSMI')
    base = ['ssmi/' basin '/'];
    sat_files = dir([base 'NPR.SDRR.S9.D*']);
elseif strcmp(img_sensor, 'SSMIS')
    base = ['ssmis/' basin '/'];
    sat_files = dir([base 'NPR.SDRN.*']);
else
    error('Unknown satellite sensor chosen. Programming stopping.')
end
%
% Add paths to ARCHER-related programs
archer_path
%
% Load relevant best-track data
load_bt
%
% Loop through satellite files to create polar imagery
%
n_swaths = length(sat_files);
%
disp('Looping through satellite swaths')
%
n_start = 1;
%
for i = n_start:n_swaths
    %
    disp(' ')
    disp([num2str(i) '. Reading in file ' ...
        sat_files(i).name])
    %
    good_pass = 1; % Until specified otherwise, assume we have a
    %  good satellite pass
    %
    % Read-in script with logic to determine sensor
    read_satellite_data
    %
    % Quality-control check data
    sat_data = qc_satellite_data(sat_data, img_sensor);
    %
    % Does the TC have best-track fixes before and after the time of
    %  the satellite image?
    mst = mean(sat_data.time_hi);
    u_ind = find((date_bt - mst) <= 0.5 & (date_bt - mst) >= 0);
    l_ind = find((mst - date_bt) <= 0.5 & (mst - date_bt) >= 0);
    %
    % Begin best-track bracket code
    if ~isempty(u_ind) && ~isempty(l_ind) && good_pass
        upper = date_bt(u_ind) - mst;
        upper_min = min(upper); umin_ind = find(upper == upper_min);
        lower = mst - date_bt(l_ind);
        lower_min = min(lower); lmin_ind = find(lower == lower_min);
        lower_stnam_bt = stnam_bt(l_ind(lmin_ind));
        upper_stnam_bt = stnam_bt(u_ind(umin_ind));
        [stnam_sub, ind_sub_l, ind_sub_u] = ...
            intersect(lower_stnam_bt, upper_stnam_bt);
        %
        % Loop through each storm that satisifies the intersection
        %  and see if it's in satellite swath. If so, process data.
        %
        for istm = 1:length(stnam_sub)
            %
            disp(['  - Analyzing TC ' char(stnam_sub(istm))])
            %
            iu = u_ind(umin_ind(ind_sub_u(istm)));
            il = l_ind(lmin_ind(ind_sub_l(istm)));
            if (iu == il); continue; end
            %
            % Best track interpolation for first guess at center
            inx = [date_bt(il) date_bt(iu)];
            inylon = [lon_bt(il) lon_bt(iu)];
            inylat = [lat_bt(il) lat_bt(iu)];
            inydl = [dl_bt(il) dl_bt(iu)];
            inyvmax = [vmax_bt(il) vmax_bt(iu)];
            interp_lat = ...
                interp1(inx, inylat, sat_data.time_hi, ...
                'linear', 'extrap');
            interp_lon = ...
                interp1(inx, inylon, sat_data.time_hi, ...
                'linear', 'extrap');
            interp_dl = ...
                interp1(inx, inydl, sat_data.time_hi, ...
                'linear', 'extrap');
            interp_spd = ...
                interp1(inx, inyvmax, sat_data.time_hi, ...
                'linear', 'extrap');
            [arclen, az] = distance(interp_lat, interp_lon, ...
                squeeze(sat_data.lat85(round(end/2), :))', ...
                squeeze(sat_data.lon85(round(end/2), :))');
            [mindist, imindist] = min(arclen);
            imindist = imindist(1);
            %
            if sat_data.time_hi(end) - sat_data.time_hi(1) ~= 0
                interp_lat = interp_lat(imindist);
                interp_lon = interp_lon(imindist);
                interp_dl = interp_dl(imindist);
                interp_spd = interp_spd(imindist);
            else
                interp_lat = interp_lat(1);
                interp_lon = interp_lon(1);
                interp_dl = interp_dl(1);
                interp_spd = interp_spd(1);
            end
            %
            % Pick out data near the TC center
            local_lats = sat_data.lat > interp_lat - 10 & ...
                sat_data.lat < interp_lat + 10;
            local_lons = sat_data.lon > interp_lon - 10 & ...
                sat_data.lon < interp_lon + 10;
            %
            local_lats85 = sat_data.lat85 > interp_lat - 10 & ...
                sat_data.lat85 < interp_lat + 10;
            local_lons85 = sat_data.lon85 > interp_lon - 10 & ...
                sat_data.lon85 < interp_lon + 10;
            %
            locals_in_row = sum(local_lats & local_lons);
            good_rows = find(locals_in_row);
            locals_in_row85 = sum(local_lats85 & local_lons85);
            good_rows85 = find(locals_in_row85);
            if isempty(good_rows)
                disp(['  - ' sat_files(i).name ' does not cover TC'])
            elseif interp_dl < 0
                disp(['  - ' sat_files(i).name ': TC over land.'])
            else
                disp(['  - Proceeding forward with ARCHER & output'])
                %
                sat_sub.bt19h = sat_data.bt19h(:, good_rows);
                sat_sub.bt19v = sat_data.bt19v(:, good_rows);
                sat_sub.bt37h = sat_data.bt37h(:, good_rows);
                sat_sub.bt37v = sat_data.bt37v(:, good_rows);
                sat_sub.lon = sat_data.lon(:, good_rows);
                sat_sub.lat = sat_data.lat(:, good_rows);
                sat_sub.time_lo = sat_data.time_lo(good_rows);
                sat_sub.bt85h = sat_data.bt85h(:, good_rows85);
                sat_sub.bt85v = sat_data.bt85v(:, good_rows85);
                sat_sub.lon85 = sat_data.lon85(:, good_rows85);
                sat_sub.lat85 = sat_data.lat85(:, good_rows85);
                sat_sub.time_hi = sat_data.time_hi(good_rows85);
                %
                % Determine if best-track center is within satellite swath
                lon_perim = [sat_sub.lon(1, :) sat_sub.lon(:, end)' ...
                    sat_sub.lon(end, end:-1:1) sat_sub.lon(end:-1:1, 1)'];
                lat_perim = [sat_sub.lat(1, :) sat_sub.lat(:, end)' ...
                    sat_sub.lat(end, end:-1:1) sat_sub.lat(end:-1:1, 1)'];
                fx_in_swath = inpolygon(interp_lon, interp_lat, ...
                    lon_perim, lat_perim);
                %
                % If so, proceed.
                if fx_in_swath && sum(sum(isnan(sat_sub.bt37h) == 0)) > 0
                    %
                    % Apply land mask
                    land_mask_application
                    %
                    % Histogram-matched calibration
                    %  - Matched to GMI, AMSRE/2 18.7, 36.5, and 89 GHz
                    sat_sub_calib = histogram_match(sat_sub, img_sensor);
                    %
                    % Calculate Polarization Corrected Temperatures
                    sat_sub.pct37 = 2.18 * sat_sub.bt37v - ...
                        1.18 * sat_sub.bt37h;
                    sat_sub_calib.pct37 = 2.18 * sat_sub_calib.bt37v - ...
                        1.18 * sat_sub_calib.bt37h;
                    sat_sub.pct85 = 1.818 * sat_sub.bt85v - ...
                        0.818 * sat_sub.bt85h;
                    sat_sub_calib.pct85 = 1.818 * sat_sub_calib.bt85v - ...
                        0.818 * sat_sub_calib.bt85h;
                    %
                    % Call ARCHER for more accurate center find
                    disp('  - Refining TC center estimate using 36.5GHz')
                    out37 = archer(sat_sub.lon, sat_sub.lat, ...
                        sat_sub_calib.bt37h, '37GHz', ...
                        interp_lon, interp_lat, interp_spd, ...
                        interp_lon, interp_lat, mean(sat_sub.time_lo), ...
                        img_sensor, [], []);
                    disp('  - Refining TC center estimate using 89GHz')
                    out85 = archer(sat_sub.lon85, sat_sub.lat85, ...
                        sat_sub_calib.bt85h, '85-92GHz', ...
                        interp_lon, interp_lat, interp_spd, ...
                        interp_lon, interp_lat, mean(sat_sub.time_hi), ...
                        img_sensor, [], []);
                    %
                    % Make output file
                    %
                    output_file
                    %
                else
                    disp(['  - Turns out best track center is not in ' ...
                        'the satellite swath. Skipping.'])
                end
            end
        end
    end % end best-track bracket code
    clear mst u_ind l_ind upper* umin* lower* lmin*
    clear iny* iu il inx interp_* local* good*
    clear *_perim fxInSwath
    %
end % end of i/n_swaths loop
%
disp(' ')
disp('Program make_polar_files.m complete.')
disp(' ')
