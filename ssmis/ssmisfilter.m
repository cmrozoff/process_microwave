%
% This script filters through F16 - F19 data for good passes.
%  If a swath intersects a track point for a storm, then the file is 
%  kept as a matlab file and save to a directory for the ATL and/or the
%  EPAC.
%
load lsdiage_1982_2017_small.mat
%
yr_pic = 2015;
stnam_pic = 'PATR';
output_dir = '/glade/work/rozoff/jht/ssmis/output/'
%
ind = find(yr_pic == yr & strcmp(stnam_pic, stnam));
%
time = datenum(yr, mo, da, hr, 0 * hr, 0 * hr);
timeAll = time(ind);
stidAll = stnam(ind);
xx = xx(ind, :, :);
clear yr mo da hr vmax ind *_pic stnum time
latAll = 0.1 * xx(:, 4, 3);
lonAll = -0.1 * xx(:, 5, 3);
%
files = dir(['/gpfs/fs1/work/rozoff/jht/raw/NPR.SDRN.*']);
%
disp(' '); disp('Starting program to filter SSMIS'); disp(' ')
%
dirName = '/gpfs/fs1/work/rozoff/jht/raw/';
for i = 1:length(files)
    disp(['Checking ' files(i).name])
    fileName = [dirName files(i).name];
    %
    % Read in lat/lon/bt data
    %
    [lon85, lat85, bt85h, bt85v, yrS, doyS, hrS, mnS, flag_skip] = ...
        readSDRN(fileName);
    if flag_skip == 0
        %
        % See if any TC points are inside swath
        %
        fileNameShort = files(i).name;
        checkswath
        time85 = timeS;
        %
        if fileFlag == 0
            disp(['Found no coverage of a TC. Deleting file'])
            unix(['rm -f ' fileName]);
        elseif fileFlag == 1
            disp(['Found coverage of Eastern Pacific TC(s). ' ...
                'Copying file to output directory'])
            [lon, lat, bt19h, bt19v, bt37h, bt37v, skip_flag2] = ...
                readSDRNlo(fileName);
            if skip_flag2 == 0
                filesschar = char(fileNameShort);
                filemat = [filesschar(1:40) 'mat'];
                save(filemat, 'lon', 'lat', 'bt19h', 'bt19v', 'bt37h', ...
                    'bt37v', 'lon85','lat85','bt85h', 'bt85v', 'time85');
                unix(['mv -f ' filemat ' ' output_dir]);
            end
        end
    end
    unix(['rm -f ' fileName]);
end
