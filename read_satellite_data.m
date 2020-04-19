%
% Obtain data from file
%
%  - determine sensor
if strcmp(img_sensor, 'AMSRE')
    try
        sat_data = amsre_reader([base sat_files(i).name]);
    catch
        error([num2str(i) 'There has been a problem reading ' ...
            sat_files(i).name]);
    end
elseif strcmp(img_sensor, 'AMSR2')
    try
        sat_data = amsr2_reader([base sat_files(i).name]);
    catch
        error([num2str(i) 'There has been a problem reading ' ...
            sat_files(i).name]);
    end
elseif strcmp(img_sensor, 'GMI')
    try
        sat_data = gmi_reader([base sat_files(i).name]);   
    catch
        error([num2str(i) 'There has been a problem reading ' ...
            sat_files(i).name]);
    end
elseif strcmp(img_sensor, 'SSMI')
   try
    [sat_data, good_pass] = ...
        ssmi_reader(base, sat_files(i).name, good_pass);
   catch
       error([num2str(i) 'There has been a problem reading ' ...
           sat_files(i).name]);
   end
elseif strcmp(img_sensor, 'SSMIS')
    try
        sat_data = ssmis_reader([base sat_files(i).name]);
    catch
        error([num2str(i) 'There has been a problem reading ' ...
            sat_files(i).name]);
    end
elseif strcmp(img_sensor, 'TMI')
   try
        sat_data = tmi_reader([base sat_files(i).name]);
   catch
       error([num2str(i) 'There has been a problem reading ' ...
           sat_files(i).name]);
   end
end