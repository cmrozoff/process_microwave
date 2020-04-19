%
% This program is designed to filter GMI data so that only data to keep
%  only swaths that contain storm
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
files = dir(['*.HDF5']);
%
disp(' '); disp('Starting program to filter AMSR2'); disp(' ')
%
for i = 1:length(files)
    disp(['Checking ' files(i).name])
    fileName = [files(i).name];
    %
    [timeS, lonS, latS, btS] = gmiReader(fileName);
    if ~isempty(btS)
        checkSwath
    else
        fileFlag = 0;
    end
    %
    if fileFlag == 0
        disp(['Found no coverage of a TC. Deleting file'])
        unix(['rm ' fileName]);
    elseif fileFlag == 1
        disp(['Found coverage of TC. Copying file to output directory'])
        unix(['mv ' fileName ' output/']);
    end
end