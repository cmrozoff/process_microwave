function newSwath=evenOutGapsHoriz(swath)
% Fills in gaps with NaNs

numCols=length(swath.latMx(1,:));
if strcmp(swath.sensorType,'TMI')
    lon1=swath.lonMx(:,1);
    dLon=lon1(2:end)-lon1(1:end-1);
    medl=median(dLon); % A rough estimate of the appropriate longitude gap distance
    gapNums=round(dLon/medl); % Number of missing lines
else
    lat1=swath.latMx(:,1);
    dLat=lat1(2:end)-lat1(1:end-1);
    medl=median(dLat); % A rough estimate of the appropriate latitude gap distance
    gapNums=round(dLat/medl); % Number of missing lines
end
gapInds=find(gapNums>1)';
fixedLatMx=swath.latMx;
fixedLonMx=swath.lonMx;
fixedValMx=swath.bthMx;
if size(swath.timeArray,2)>size(swath.timeArray,1); swath.timeArray=swath.timeArray'; end
fixedTimes=swath.timeArray;

for i=fliplr(gapInds) % Going backwards keeps the next indeces the same
    gapLen=gapNums(i);
    gapLats=interp2(1:numCols,[1;gapLen+1],fixedLatMx(i:i+1,:),1:numCols,(1:gapLen+1)');
    gapLons=interp2(1:numCols,[1;gapLen+1],fixedLonMx(i:i+1,:),1:numCols,(1:gapLen+1)');
    gapTimes=interp1([1 gapLen+1]', swath.timeArray(i:i+1), [1:gapLen+1]');
    fixedLatMx=[fixedLatMx(1:i,:); gapLats(2:end-1,:); fixedLatMx(i+1:end,:)];
    fixedLonMx=[fixedLonMx(1:i,:); gapLons(2:end-1,:); fixedLonMx(i+1:end,:)];
    fixedValMx=[fixedValMx(1:i,:); NaN*ones(gapLen-1,numCols); fixedValMx(i+1:end,:)];
    %keyboard
    fixedTimes=[fixedTimes(1:i); gapTimes(2:end-1); fixedTimes(i+1:end)];
end

if 0
    figure(1); clf; plot(fixedLonMx,fixedLatMx,'r.'); hold on;
    plot(swath.lonMx,swath.latMx,'k.'); hold on;
end

newSwath=swath;
newSwath.latMx=fixedLatMx;
newSwath.lonMx=fixedLonMx;
newSwath.bthMx=fixedValMx;
newSwath.timeArray=fixedTimes;