%
% This program is to filter the data down so that only data that includes 
%  relevant Atlantic and Eastern Pacific Ocean tropical cyclones are kept.
%
addpath /Users/rozoff/research/ships_developmental_data/
load lsdiage_1982_2017_small.mat
%
yr_pic = 2015;
stnam_pic = 'PATR';
output_dir = 'output/'
%
ind = find(yr_pic == yr & strcmp(stnam_pic, stnam));
time = datenum(yr, mo, da, hr, 0 * hr, 0 * hr);
timeAll = time(ind);
stidAll = stnam(ind);
xx = xx(ind, :, :);
clear yr mo da hr vmax ind *_pic stnum time
latAll = 0.1 * xx(:, 4, 3);
lonAll = -0.1 * xx(:, 5, 3);
%
files = dir(['../*.h5']);
%
disp(' '); disp('Starting program to filter AMSR2'); disp(' ')
%
dirName = '/Volumes/d1/jht/polar_files/';
for i = 1:length(files)
    disp(['Checking ' files(i).name])
    fileName = [dirName files(i).name];
    disp(['Checking ' fileName]);
    %
    % Read in lat/lon/bt data
    %
    [timeS, lonS, latS, btS] = amsr2read(fileName);
    checkSwath
    %
    if fileFlag == 0
        disp(['Found no coverage of a TC. Deleting file'])
        unix(['rm ' fileName]);
    elseif fileFlag == 1
        disp(['Found coverage of TC(s). ' ...
            'Copying file to output directory'])
        unix(['mv ' fileName ' output/']);
    end
end
