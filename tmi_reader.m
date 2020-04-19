function sat_data = tmi_reader(file_input)
%
% Read in TMI HDF files
%
file_id = hdfh('open', file_input, 'read', 0);
%
% Open HDF SDS and VDATA interfaces
sd_id = hdfsd('start', file_input, 'read');
%
status = hdfv('start', file_id);
%
[n_datasets, n_file_attrs, status] = hdfsd('fileinfo', sd_id);
%
for index = 0:(n_datasets - 1)
    sds_id = hdfsd('select', sd_id, index);
    [sds_name, rank, dim_sizes, num_types, attributes, status] = ...
        hdfsd('getinfo', sds_id);
    status = hdfsd('endaccess', sds_id);
end
%
nparam = 5;
%
if nparam == 0 
    hdfml('closeall');
    return;
elseif nparam == n_datasets
    nindex = 0;
    for index = 1:n_datasets
        sds_index(index) = index;
    end
    nindex = length(sds_index);
else
    temparm = [1 2 3 4 5 6 7 9 10 80 81];
    sds_index = temparm;
    nindex = length(temparm);
end
%
if nparam > 0
    for index = 1:nindex
        sds_idx = sds_index(index)-1;
        sds_id = hdfsd('select',sd_id,sds_idx);
        [sds_name, rank, dim_sizes, num_type, attributes, status] = ...
            hdfsd('getinfo', sds_id);
        [gain,gain_err,offset,offset_err,cal_data_type,status] = ...
            hdfsd('getcal', sds_id);
        %
        edges = [];
        start = [];
        for j = 1:rank
            edges(j) = dim_sizes(j);
            start(j) = 0;
        end
        %
        % Read TRMM sds arrays
        [data{index}, status] = ...
            hdfsd('readdata', sds_id, start, [], edges);
        %
        status = hdfsd('endaccess', sds_id);
    end
end
%
status = hdfsd('end', sd_id);
status = hdfv('end', file_id);
status = hdfh('close', file_id);
%
yrt = double(data{1});
mot = double(data{2});
dat = double(data{3});
hrt = double(data{4});
mnt = double(data{5});
sct = double(data{6});
time = datenum(yrt, mot, dat, hrt, mnt, sct);
%
test = data{8};
lat = double(test(1:2:end,:));
sat_data.lat = lat;
lat85 = double(test);
sat_data.lat85 = lat85;
test = data{9};
sat_data.lon = double(test(1:2:end,:));
sat_data.lon85 = double(test);
test = data{10};
sat_data.bt19v = double(squeeze(test(3,:,:))) / 100 + 100;
sat_data.bt19h = double(squeeze(test(4,:,:))) / 100 + 100;
sat_data.bt37v = double(squeeze(test(6,:,:))) / 100 + 100;
sat_data.bt37h = double(squeeze(test(7,:,:))) / 100 + 100;
test = data{11};
sat_data.bt85v = double(squeeze(test(1,:,:))) / 100 + 100;
sat_data.bt85h = double(squeeze(test(2,:,:))) / 100 + 100;
sat_data.time_lo = time;
sat_data.time_hi = sat_data.time_lo;
%
return
end