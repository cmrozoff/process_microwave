function d = distanceDeg(lon1, lat1, lon2, lat2)

RPD=pi/180;

avgLat=0.5*(lat1+lat2);

latDist=abs(lat2-lat1);
lonDist=abs(lon2-lon1).*cos(RPD*avgLat);

d=sqrt(latDist.^2+lonDist.^2);
