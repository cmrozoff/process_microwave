clear all
addpath sharedFiles

westPacTCs=dir('cyclones/2008*W');
for i=1:length(westPacTCs)
    fid=fopen(['cyclones/' westPacTCs(i).name '/curName.txt'],'r');
    myName=fgets(fid);
    myName(end)=[];
    %myName=load(['cyclones/' westPacTCs(i).name '/curName.txt']);
    unisysName{i}=upper(myName);
    unisysName{i}(unisysName{i}=='-')='_';
end

for tci=1:length(westPacTCs)
    
    clear trackTimes uLat uLon uVmax
    clear trackTimesClean uLatClean uLonClean uVmaxClean
    
    disp(unisysName{tci})
    unisysURL=['http://weather.unisys.com/hurricane/w_pacific/2008/' unisysName{tci} '/track.dat'];

    uYearPlace=findstr('20',unisysURL);
    uYear=str2num(unisysURL(uYearPlace:uYearPlace+3));
    url = java.net.URL(unisysURL);

    is = openStream(url);
    isr = java.io.InputStreamReader(is);
    br = java.io.BufferedReader(isr);

    tline=char(readLine(br));
    tline=char(readLine(br));
    tline=char(readLine(br));
    i=0;
    while 1
        i=i+1;
        tline=char(readLine(br));
        if isempty(tline), break, end
        disp(tline)
        if strcmp(tline(1),'+')
            if str2num(tline(2:4))<100 % When the forecast time is >100 hours, the numbers are pushed over one character
                uLat(i)=str2num(tline(6:10));
                uLon(i)=str2num(tline(12:18));
                uMon=str2num(tline(20:21));
                uDay=str2num(tline(23:24));
                uHour=str2num(tline(26:27));
                trackTimes(i)=datenum(uYear,uMon,uDay,uHour,0,0);
                if tline(33)=='-';
                    uVmax(i)=25;
                else
                    uVmax(i)=str2num(tline(31:33));
                end
            else
                uLat(i)=str2num(tline(7:11));
                uLon(i)=str2num(tline(13:19));
                uMon=str2num(tline(21:22));
                uDay=str2num(tline(24:25));
                uHour=str2num(tline(27:28));
                trackTimes(i)=datenum(uYear,uMon,uDay,uHour,0,0);
                if tline(34)=='-';
                    uVmax(i)=25;
                else
                    uVmax(i)=str2num(tline(32:34));
                end
            end
        else
            uLat(i)=str2num(tline(6:10));
            uLon(i)=str2num(tline(12:18));
            uMon=str2num(tline(20:21));
            uDay=str2num(tline(23:24));
            uHour=str2num(tline(26:27));
            trackTimes(i)=datenum(uYear,uMon,uDay,uHour,0,0);
            if tline(33)=='-';
                uVmax(i)=25;
            else
                uVmax(i)=str2num(tline(31:33));
            end
        end
    end

    j=1;
    trackTimesClean(j)=trackTimes(1);
    uLatClean(j)=uLat(1);
    uLonClean(j)=uLon(1);
    uVmaxClean(j)=uVmax(1);
    for i=2:length(trackTimes)
        if trackTimes(i)==trackTimes(i-1)
            trackTimesClean(j)=trackTimes(i);
            uLatClean(j)=uLat(i);
            uLonClean(j)=uLon(i);
            uVmaxClean(j)=uVmax(i);
        else
            j=j+1;
            trackTimesClean(j)=trackTimes(i);
            uLatClean(j)=uLat(i);
            uLonClean(j)=uLon(i);
            uVmaxClean(j)=uVmax(i);
        end
    end

    %writeTrackUnisys(westPacTCs(i).name,trackTimesClean,uLatClean,uLonClean,uVmaxClean);
    fidTrack=fopen(['cyclones/' westPacTCs(tci).name '/track/unisysTrack.txt'], 'w');
    for k=1:length(trackTimesClean)
        dT=datestr(trackTimesClean(k), 'yyyymmddTHHMMSS');
        %fprintf(1,'%04d %02d %02d %02d %02d %02d %6.2f %7.2f %03d\n', str2num(dT(1:4)),str2num(dT(5:6)),str2num(dT(7:8)),...
        %    str2num(dT(10:11)),str2num(dT(12:13)),str2num(dT(14:15)),uLatClean(k),uLonClean(k),uVmaxClean(k));
        fprintf(fidTrack,'%04d %02d %02d %02d %02d %02d %6.2f %7.2f %03d\n', str2num(dT(1:4)),str2num(dT(5:6)),str2num(dT(7:8)),...
            str2num(dT(10:11)),str2num(dT(12:13)),str2num(dT(14:15)),uLatClean(k),uLonClean(k),uVmaxClean(k));
    end

    fclose(fidTrack);
    
end