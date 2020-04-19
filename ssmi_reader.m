function [sat_data, good_pass] = ...
    ssmi_reader(base_dir, file_input, good_pass)
%
% Read in SSMI data from a variety of file formats
%
file_id = file_input(1:8);
test_file = [base_dir file_input];
file_input = [base_dir file_input];
%
if strcmp(file_id, 'NPR.SDRR')
    [pathstr, name, ext] = fileparts(file_input);
    if strcmp(ext, '.nc')
        disp(' .nc type file detected.')
        %
        % Input date / time
        %
        secsAfter1987 = ncread(file_input, 'scan_time_since87_lores');
        escanTimeArr = datenum(1987, 1, 1, 0, 0, secsAfter1987);
        secsAfter1987 = ncread(file_input, 'scan_time_since87_hires');
        escanTimeArr85 = datenum(1987, 1, 1, 0, 0, secsAfter1987);
        %
        % lat / lon for imager channels
        %
        sat_data.lon = ncread(file_input, 'longitude_lores');
        sat_data.lat = ncread(file_input, 'latitude_lores');
        %
        bt = ncread(file_input,'temperatures_lores');
        sat_data.bt19h = squeeze(bt(2, :, :));
        sat_data.bt19v = squeeze(bt(1, :, :));
        sat_data.bt37h = squeeze(bt(5, :, :));
        sat_data.bt37v = squeeze(bt(4, :, :));
        %
        % lat / lon for imager channels
        %
        sat_data.lon85 = ncread(file_input, 'longitude_hires');
        sat_data.lat85 = ncread(file_input, 'latitude_hires');
        %
        bt = ncread(file_input, 'temperatures_hires');
        sat_data.bt85h = squeeze(bt(2, :, :));
        sat_data.bt85v = squeeze(bt(1, :, :));
        %
        sat_data.time_lo = escanTimeArr;
        sat_data.time_hi = escanTimeArr85;
    elseif strcmp(ext, '.mat')
        disp(' .mat type file detected.')
        %
        load(file_input)
        %
        sat_data.lon = out.lonMxLoRes';
        sat_data.lat = out.latMxLoRes';
        sat_data.bt19v = out.t19vMxLoRes';
        sat_data.bt19h = out.t19hMxLoRes';
        sat_data.bt37v = out.t37vMxLoRes';
        sat_data.bt37h = out.t37hMxLoRes';
        sat_data.lon85 = out.lonMxHiRes';
        sat_data.lat85 = out.latMxHiRes';
        sat_data.bt85v = out.t85vMxHiRes';
        sat_data.bt85h = out.t85vMxHiRes';
        sat_data.time_lo = out.scanTimeLoResArr;
        sat_data.time_hi = out.scanTimeHiResArr;
    end
else
    %
    disp(' NCDC SSMI file detected.')
    %
    % Obtain storm name from file name
    %
    ind = find(test_file == '.');
    mstnam = test_file(ind(1)+1:ind(2)-1);
    %
    % Dumb hard-wired conversion; May break easily
    if strcmp(mstnam,'ONE'); mstnam = char('TD01'); end
    if strcmp(mstnam,'EIGHT'); mstnam = char('TD08'); end
    if strcmp(mstnam,'TEN'); mstnam = char('TD10'); end
    if strcmp(mstnam,'FIFTEEN'); mstnam = char('TD15'); end
    if strcmp(mstnam,'SIXTEEN'); mstnam = char('TD16'); end
    if strcmp(mstnam,'NINETEEN'); mstnam = char('TD19'); end
    if length(mstnam) > 4
        mstnam = mstnam(1:4);
    end
    mstnam = cellstr(mstnam);
    myr = str2num(test_file(ind(2)+1:ind(3)-1));
    mmo = str2num(test_file(ind(3)+1:ind(4)-1));
    mda = str2num(test_file(ind(4)+1:ind(5)-1));
    mhr = str2num(test_file(ind(5)+1:ind(5)+2));
    mmn = str2num(test_file(ind(5)+3:ind(5)+4));    
    datePolOrb = datenum(myr, mmo, mda, mhr, mmn, 0);
    sat_data.lon = double(ncread(file_input, 'lon_sw_lo'));
    sat_data.lat = double(ncread(file_input, 'lat_sw_lo'));
    sat_data.lon85 = double(ncread(file_input, 'lon_sw_hi'));
    sat_data.lat85 = double(ncread(file_input, 'lat_sw_hi'));
    genarr = sat_data.lon;
    sat_data.time_lo = zeros(length(genarr(1, :)), 1) + datePolOrb;
    genarr = sat_data.lon85;
    sat_data.time_hi = zeros(length(genarr(1, :)), 1) + datePolOrb;    
    %
    tb_lo = double(ncread(file_input, 'tb_lo'));
    tb_hi = double(ncread(file_input, 'tb_hi'));
    if size(tb_lo, 1) == 5 && size(tb_hi, 1) == 2
        sat_data.bt19h = squeeze(tb_lo(2, :, :));
        ind = find(sat_data.bt19h == 0); sat_data.bt19h(ind) = NaN;
        sat_data.bt19v = squeeze(tb_lo(1, :, :));
        ind = find(sat_data.bt19v == 0); sat_data.bt19v(ind) = NaN;
        sat_data.bt37h = squeeze(tb_lo(5, :, :));
        ind = find(sat_data.bt37h == 0); sat_data.bt37h(ind) = NaN;        
        sat_data.bt37v = squeeze(tb_lo(4, :, :));
        ind = find(sat_data.bt37v == 0); sat_data.bt37v(ind) = NaN;
        der1 = diff(sat_data.lon);
        ind = find(abs(der1) > 0.35); 
        % Force program to ignore bad datasets
        if ~isempty(ind); good_pass = 0.0; end
        %
        sat_data.bt85h = squeeze(tb_hi(2, :, :));
        ind = find(sat_data.bt85h == 0); sat_data.bt85h(ind) = NaN;
        sat_data.bt85v = squeeze(tb_hi(1, :, :));
        ind = find(sat_data.bt85v == 0); sat_data.bt85v(ind) = NaN;
        der1 = diff(sat_data.lon85);
        ind = find(abs(der1) > 0.35);
        if ~isempty(ind); good_pass = 0; end
    else
        good_pass = 0;
    end
end
%
return
end