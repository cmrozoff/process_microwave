function [lon, lat, bt19h, bt19v, bt37h, bt37v, flag_skip] = readSDRN(filess)
%
disp(['Processing SSMIS file ' char(filess)])
%
executionLine = ['/gpfs/fs1/work/rozoff/jht/ssmis/ssmis_lores ' char(filess) ' > chlo.txt'];
unix(executionLine);
%
disp(['Reading in SSMIS file data into matlab'])
%
filename = 'chlo.txt';
fid = fopen(filename, 'r');
x = textscan(fid, '%s');
fclose(fid);
%
x = x{1};
flag_skip = 0;
if ~isempty(find(strcmp(x, 'Segmentation'))) || ...
        ~isempty(find(strcmp(x, 'segmentation')))
    disp('Segmentation fault detected. Skipping file.')
    flag_skip = 1;
    lon=NaN; lat=NaN;
    bt19h=NaN; bt19v=NaN;
    bt37h=NaN; bt37v=NaN;
else
    %
    img_scan = str2num(char(x(13:8:end-5)));
    img_scene = str2num(char(x(14:8:end-5)));
    %
    nscan = max(img_scan) + 1;
    nscene = max(img_scene) + 1;
    %
    img_lat = str2num(char(x(15:8:end-5))) * 0.01;
    img_lon = str2num(char(x(16:8:end-5))) * 0.01;
    img_tb19h = str2num(char(x(17:8:end-5))) * 0.01;
    img_tb19v = str2num(char(x(18:8:end-5))) * 0.01;
    img_tb37h = str2num(char(x(19:8:end-5))) * 0.01;
    img_tb37v = str2num(char(x(20:8:end-5))) * 0.01;
    %
    if mod(length(img_tb19v),nscene) == 0
        disp([' Reshaping data'])
        lon = reshape(img_lon, [nscene length(img_lat)/nscene]);
        lat = reshape(img_lat, [nscene length(img_lat)/nscene]);
        bt19h = reshape(img_tb19h, [nscene length(img_lat)/nscene]);
        bt19v = reshape(img_tb19v, [nscene length(img_lat)/nscene]);
        bt37h = reshape(img_tb37h, [nscene length(img_lat)/nscene]);
        bt37v = reshape(img_tb37v, [nscene length(img_lat)/nscene]);
    else
        disp('File error detected. Skipping file.')
        flag_skip = 1;
        lon=NaN; lat=NaN;
        bt19h=NaN; bt19v=NaN;
        bt37h=NaN; bt37v=NaN;
    end
    %
end
unix('rm -f chlo.txt');
%
return
end
