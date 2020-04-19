function tmiBTs=ssmi2tmiConversion2(ssmiBTs)
% Calibrated on willie:/~MIMIC/histEq/ssmi2tmiTest2007data.m
% Data: .../histEq/newSetInfo/pairingsSSMI.txt
% July 2008 AJW

ssmiTrainingPoints=120:5:300;
tmiTrainingPoints=[90.0  95.0 100.0 105.0 110.0 115.0 120.0 129.0 137.9 146.9 155.9 162.1 ...
    166.6 170.9 179.5 183.6 190.8 198.2 204.9 211.4 218.2 224.8 230.8 236.6 242.6 248.1 252.8 ...
    257.7 262.4 267.3 273.2 278.9 282.7 287.8 292.8 297.8 302.8];

tmiBTs=interp1(ssmiTrainingPoints,tmiTrainingPoints,ssmiBTs,'linear','extrap');
