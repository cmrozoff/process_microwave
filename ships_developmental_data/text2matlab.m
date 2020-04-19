%
% Create a matlab formatted file from the text data for efficient use in
%  existing analysis programs
%
% Version for the standard SHIPS developmental datasets
%
%  Last modified 15 Sept. 2016 for new file updates
% --------------------------------------------------------------------
%
fid = fopen('lsdiage_1995_2019_sat_ts.dat', 'r');
x = textscan(fid, '%s');
%fclose(fid);
%
x = x{1};
%
% 29 scattered records, 18 lines with 24 columns
%
numrec4stm = 29 + 18 * 24 + 120 * 22;
numcases = length(x)/numrec4stm;
ix = numrec4stm; ixt = length(x);
stnam=x(1:ix:ixt);
date=char(x(2:ix:ixt+1));
yr=str2num(date(:,1:2)); mo=str2num(date(:,3:4)); 
da=str2num(date(:,5:6)); hr=str2num(char(x(3:ix:ixt+2)));
vmax=str2num(char(x(36:ix:ixt+35)));
%
stnum = char(x(8:ix:ixt+7));
stnum = str2num(stnum(:, 3:4));
%
ind = find(yr > 50); yr(ind) = yr(ind) + 1900;
ind = find(yr < 50); yr(ind) = yr(ind) + 2000;
%
xx = [];
%
for i = 1:numcases
    disp(['Case ' num2str(i)]);
    %
    % Put into xx: TIME VMAX MSLP
    %
    im1 = 10; 
    im2 = 3 * 24 + im1 - 1;
    part1 = str2double(x(im1 + (i - 1) * ...
        numrec4stm:1:im2 + (i - 1) * numrec4stm));
    part1 = ipermute(reshape(part1, 24, 3), [2 1]); 
    part1 = part1(:, 1:end-1);
    %   
    % Put into xx: DELV, INCV, LAT, LON, CSST, CD20, CD26, 
    % COHC, DTL, OAGE, NAGE, RSST
    %
    im1 = im2 + 1 + 24 + 22;
    im2 = 12 * 24 + im1 - 1; % (N * M + L - 1, N = num. variables
    part2 = str2double(x(im1 + (i - 1) * ...
        numrec4stm:1:im2 + (i - 1) * numrec4stm));
    part2 = ipermute(reshape(part2, 24, 12), [2 1]); 
    part2 = part2(:, 1:end-1);
    %
    full= ipermute([part1 ; part2], [2 3 1]);
    xx = [xx ; full];
    %
end
%
varname = {'TIME' ; 'VMAX' ; 'MSLP' ; 'DELV' ; 'INCV' ; 'LAT' ; ...
    'LON' ; 'CSST' ; 'CD20' ; 'CD26' ; 'COHC' ; 'DTL'};
%
% Save output to Matlab file
%
save lsdiaga_1995_2019_sat_ts.mat da hr mo yr stnam vmax xx varname stnum
%
