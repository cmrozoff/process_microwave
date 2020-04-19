function sat_data = amsre_reader(file_input)
%
% Reading in HDF file containin AMSRE data
%
file_id = hdfh('open', file_input, 'read', 0);
%
% Open HDF SDS and VDATA Interfaces
sd_id = hdfsd('start', file_input, 'read');
%
status = hdfv('start',file_id);
%
[n_datasets,n_file_attrs, status] = hdfsd('fileinfo',sd_id);
%
for index = 0:(n_datasets-1)
    sds_id = hdfsd('select',sd_id, index);
    [sds_name, rank, dim_sizes, num_type, attributes, status] = ...
        hdfsd('getinfo', sds_id);
    str = [' %2d) %-15s dimensions = ' repmat('%7d ',1,rank) ' '];
    status = hdfsd('endaccess',sds_id);
end
%
nparam = 4; %input('Number of parameters to write out or 0 to exit program. ');

if nparam == 0
    hdfml('closeall');
    return;
elseif nparam == n_datasets
    nindex = 0;
    for index = 1:n_datasets
        sds_index(index) = index;
    end
else
    temparm = [1 2 23 24 27 28 81 82 87 88]; % 92 variables are available
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
        stride = [];
        edges = [];
        start = [];
        for j = 1:rank
            edges(j) = dim_sizes(j);
            stride(j) = 1;
            start(j) = 0;
        end
        
        % Read AMSRE sds arrays
        [data{index}, status] = hdfsd('readdata',sds_id,start,[],edges);
        status = hdfsd('endaccess',sds_id);
    end
end
%
status = hdfsd('end',sd_id);
%
sat_data.lat = double(data{1});
sat_data.lon = double(data{2});
sat_data.bt19v = double(data{3}) /100 + 327.68;
sat_data.bt19h = double(data{4}) /100 + 327.68;
sat_data.bt37v = double(data{5}) /100 + 327.68;
sat_data.bt37h = double(data{6}) /100 + 327.68;
sat_data.lat85 = double(data{7});
sat_data.lon85 = double(data{8});
sat_data.bt85v = double(data{9}) / 100 + 327.68;
sat_data.bt85h = double(data{10}) / 100 + 327.68;
%
% Now read in the Vdata tables

vdata_ref = - 1;
vdata_ref = hdfvs('getid',file_id, vdata_ref);
if ( vdata_ref == -1 )
    error(' No Vdatas found in data set ');
end
%
total_vidx = 0;
while(vdata_ref ~= -1)
    vdata_id = hdfvs('attach',file_id, vdata_ref, 'r');
    [n_records, interlace, fields, vdata_size, vdata_name, status] = ...
        hdfvs('inquire', vdata_id);    
    total_vref(total_vidx+1) = vdata_ref;
    total_vidx = total_vidx + 1;
    status = hdfvs('detach',vdata_id);
    vdata_ref = hdfvs('getid',file_id,vdata_ref);
end
%
nparm = 0;
nparm = 1; % input('Enter total number of vdata to write out or 0 to exit program ');
if nparm == 0
    hdfml('closeall');
    return;
elseif (nparm == total_vidx)
    nindex = 1;
    vdata_index(nindex) = index+1;
    nindex = ndindex +1;
else
    temparm = 0;
    temparm = [1]; %input('Enter parameter numbers from above list as a matlab array ');
    nindex = 0;
    for index = 0:(nparm-1)
        if temparm <=total_vidx
            vdata_index = temparm;
            nindex = length(temparm);
        end
    end
end
%
% Now loop through vdatas
if nindex > 0
    for index = 1:nindex
        vdata_idx = vdata_index(index)-1;
        vdata_id = hdfvs('attach',file_id,total_vref(vdata_idx+1),'r'); 
        [n_records, interlace,fields, vdata_size, vdata_name, status] = hdfvs('inquire',vdata_id);
        %
        if status ~= 0
            error(sprintf('VSinquire failed on vdata %s ', vdata_name));
        end
        %
        status = hdfvs('setfields',vdata_id,fields);
        [vdatabuf, status] = hdfvs('read', vdata_id, n_records);
        %
        if status ~= n_records
            error('Vdata recs read and num_rec do not match');
        end
        %
        status = hdfvs('detach',vdata_id);
        
    end % end of for statement for index of total selected vdata
end % end of if statement for nindex

status = hdfv('end',file_id);
status = hdfh('close',file_id);
%
sat_data.time_lo = datenum(1993, 1, 1, 0, 0, vdatabuf{1}');
sat_data.time_hi = sat_data.time_lo;
% 
return
end