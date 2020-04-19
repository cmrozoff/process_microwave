function [lonS, latS, btS, timeS, out] = readSDRR(filess)
%
disp(['Processing SSMI file ' char(filess)])
%
dirfile = '../raw/';
%
% Read in SSMIS data
%
inputDir = './asciiOut';
%
yearNum = 2000 + str2num(filess(14:15));
useDisplay = false;
%
% Convert the SDRR file to an FNMOC-formatted .def file
%  (Code originally developed by Tony Wimmers)
%
disp(' Processing SDRR files into a readable format')
if exist('ssmiTempDir', 'dir') == 0; unix('mkdir ssmiTempDir'); end
filename = [dirfile filess];
executionLine = ['./sdrReaderPkg/back2def.out ' filename ...
    ' ./ssmiTempDir/converted_NPR_SDRR.def'];
unix(executionLine);
%
% Process the .def file into ascii files that get written to asciiOut/
%  (Code courtesy of Tony Wimmers)
%
unix('mkdir asciiOut');
executionLine = ['./sdrReaderPkg/def_decoderAJW.out  ' ...
    'ssmiTempDir/converted_NPR_SDRR.def'];
unix(executionLine);
%
% Extract data from text files
%
out = defAsciiReader(inputDir, yearNum, useDisplay);
%
unix('rm -rf ssmiTempDir');
unix('rm -rf asciiOut');
%
lonS = out.lonMxHiRes';
latS = out.latMxHiRes';
btS = out.t85hMxHiRes';
timeS = out.scanTimeHiResArr;
%
unix(['rm ' filename]);

return
end
