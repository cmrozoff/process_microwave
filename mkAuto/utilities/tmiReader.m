function satData = tmiReader(fileName)
%
% Read in TMI data  from HDF files
% 
file_id = hdfh('open', fileName, 'read', 0);
%
% Open HDF SDS and VDATA interfaces
sd_id = hdfsd('start', fileName, 'read');
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
        num_element = 1;
        sds_idx = sds_index(index)-1;
        sds_id = hdfsd('select',sd_id,sds_idx);
        [sds_name, rank, dim_sizes, num_type, attributes, status] = hdfsd('getinfo', sds_id);
        [gain,gain_err,offset,offset_err,cal_data_type,status] = ...
            hdfsd('getcal',sds_id);
        %
        for j=1:rank
            num_element = num_element*dim_sizes(j);
        end
        %
        stride = [];
        edges = [];
        start = [];
        for j = 1:rank
            edges(j) = dim_sizes(j);
            stride(j) = 1;
            start(j) = 0;
        end
        %
        % Read TRMM sds arrays
        [data{index}, status] = hdfsd('readdata',sds_id,start,[],edges);
        %
        status = hdfsd('endaccess',sds_id);
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
satData.scanTime = datenum(yrt, mot, dat, hrt, mnt, sct);
%
test = data{8};
satData.lat = double(test(1:2:end,:));
satData.lat85 = double(test);
test = data{9};
satData.lon = double(test(1:2:end,:));
satData.lon85 = double(test);
test = data{10};
satData.bt19V = double(squeeze(test(3,:,:)));
satData.bt19H = double(squeeze(test(4,:,:)));
satData.bt37V = double(squeeze(test(6,:,:)));
satData.bt37H = double(squeeze(test(7,:,:)));
test = data{11};
satData.bt85V = double(squeeze(test(1,:,:)));
satData.bt85H = double(squeeze(test(2,:,:)));
%
return
end