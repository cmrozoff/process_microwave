function sat_data = histogram_match(sat_data, img_sensor)
%
% Use histogram matching linear adjustments to various sensors
%  to match to AMSR-E/2 and GMI channels
%
disp('  - Carrying out histogram matching: sensor calibration.')
%
if strcmp(img_sensor, 'SSMIS')
    load ssmis_gmi_coef.mat
elseif strcmp(img_sensor, 'SSMI')
    load ssmi_gmi_coef.mat
elseif strcmp(img_sensor, 'TMI')
    load tmi_amsre_coef.mat  
else
    disp(' No calibration needed.')
end
if strcmp(img_sensor, 'SSMIS') || strcmp(img_sensor, 'SSMI') || ...
        strcmp(img_sensor, 'TMI')
    ind = find(sat_data.bt19h < lim19h_2 & sat_data.bt19h >= lim19h_1);
    sat_data.bt19h(ind) = p19h(2) + p19h(1) * sat_data.bt19h(ind);
    ind = find(sat_data.bt19v < lim19v_2 & sat_data.bt19v >= lim19v_1);
    sat_data.bt19v(ind) = p19v(2) + p19v(1) * sat_data.bt19v(ind);
    ind = find(sat_data.bt37h < lim37h_2 & sat_data.bt37h >= lim37h_1);
    sat_data.bt37h(ind) = p37h(2) + p37h(1) * sat_data.bt37h(ind);
    ind = find(sat_data.bt37v < lim37v_2 & sat_data.bt37v >= lim37v_1);
    sat_data.bt37v(ind) = p37v(2) + p37v(1) * sat_data.bt37v(ind);
    ind = find(sat_data.bt85h < lim85h_2 & sat_data.bt85h >= lim85h_1);
    sat_data.bt85h(ind) = p85h(2) + p85h(1) * sat_data.bt85h(ind);
    ind = find(sat_data.bt85v < lim85v_2 & sat_data.bt85v >= lim85v_1);
    sat_data.bt85v(ind) = p85v(2) + p85v(1) * sat_data.bt85v(ind);  
end
%
return
end