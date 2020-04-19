%
% This script filters through F15 data for good passes.
%  If a swath intersects a track point for a storm, then the file is 
%  kept as a matlab file and save to a directory for the ATL and/or the
%  EPAC.
%
addpath /Users/rozoff/research/ships_developmental_data
load lsdiage_1982_2017_small.mat
%
yr_pic = 2015;
stnam_pic = 'PATR';
%
timeAll = datenum(yr, mo, da, hr, 0 * hr, 0 * hr);
%
ind = find(yr_pic == yr & strcmp(stnam_pic, stnam));
timeAll = timeAll(ind);
stidAll = stnum(ind);
xx = xx(ind, :, :);
latAll = 0.1 * xx(:, 4, 3);
lonAll = -0.1 * xx(:, 5, 3);
%
clear yr mo da hr
clear *pic ind xx stnam vmax
%
files = dir(['../raw/NPR.SDRR.*']);
%
disp(' '); disp('Starting program to filter SSMI'); disp(' ')

for i = 1:length(files)
    disp(['Checking ' files(i).name])
    fileName = files(i).name;
    %
    % Read in lat/lon/bt data
    %
    [lonS, latS, btS, timeS, out] = readSDRR(fileName);
    checkswath_ssmi
    if fileFlag == 0
        disp(['Found no coverage of a TC. Deleting file'])
    elseif fileFlag == 1

        disp(['Found coverage of East Pacific TC(s). ' ...
            'Copying file to ep directory'])
        filesschar = char(fileName);
        filemat = [filesschar(1:40) 'mat'];
        save(filemat, 'out');
        unix(['mv ' filemat ' output/']);
    end
end