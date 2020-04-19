function [lon85, lat85, bt85h, bt85v, yrS, doyS, ...
    hrS, mnS, flag_skip] = readSDRN(filess)
%
disp(['Processing SSMIS file ' char(filess)])
%
executionLine = ['/glade/work/rozoff/jht/ssmis/readssmis ' char(filess) ' > ch85.txt'];
unix(executionLine);
%
disp(['Reading in SSMIS file data into matlab'])
%
filename = 'ch85.txt';
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
    yrS=NaN; doyS=NaN;
    hrS=NaN; mnS=NaN;
    lon85=NaN; lat85=NaN;
    bt85h=NaN; bt85v=NaN;
else
    %
    yrS = str2num(filess(44:45)) + 2000;
    doyS = str2num(filess(46:48));
    hrS = str2num(filess(51:52));
    mnS = str2num(filess(53:54));
    %
    %
    img_scan85 = str2num(char(x(13:6:end-5)));
    img_scene85 = str2num(char(x(14:6:end-5)));
    %
    nscan = max(img_scan85) + 1;
    nscene = max(img_scene85) + 1;
    %
    img_lat85 = str2num(char(x(15:6:end-5))) * 0.01;
    img_lon85 = str2num(char(x(16:6:end-5))) * 0.01;
    img_tb85v = str2num(char(x(17:6:end-5))) * 0.01;
    img_tb85h = str2num(char(x(18:6:end-5))) * 0.01;
    %
    if mod(length(img_tb85v),nscene) == 0
        disp([' Reshaping data'])
        lon85 = reshape(img_lon85, [nscene length(img_lat85)/nscene]);
        lat85 = reshape(img_lat85, [nscene length(img_lat85)/nscene]);
        bt85h = reshape(img_tb85h, [nscene length(img_lat85)/nscene]);
        bt85v = reshape(img_tb85v, [nscene length(img_lat85)/nscene]);
    else
        disp('File error detected. Skipping file.')
        flag_skip = 1;
        yrS=NaN; doyS=NaN;
        hrS=NaN; mnS=NaN;
        lon85=NaN; lat85=NaN;
        bt85h=NaN; bt85v=NaN;
    end
    %
end
unix('rm -f ch85.txt');
%
return
end
