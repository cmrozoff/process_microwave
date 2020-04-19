function [latPerimeter, lonPerimeter] = ssmiPerimeterTight(lt1, lg1)

leftLats=lt1(2:end-1,1);
leftLons=lg1(2:end-1,1);

rightLats=lt1(2:end-1,end);
rightLons=lg1(2:end-1,end);

upperLats=lt1(1,2:end-1);
upperLons=lg1(1,2:end-1);

lowerLats=lt1(end,2:end-1);
lowerLons=lg1(end,2:end-1);

upperLeftLat=leftLats(1,1);
lowerLeftLat=leftLats(end,1);
upperRightLat=rightLats(1,1);
lowerRightLat=rightLats(end,1);

upperLeftLon=leftLons(1,1);
lowerLeftLon=leftLons(end,1);
upperRightLon=rightLons(1,1);
lowerRightLon=rightLons(end,1);

%Lighten it up:
rowStep=8;
colStep=4;
leftLats=leftLats(rowStep:rowStep:end);
rightLats=rightLats(rowStep:rowStep:end);
leftLons=leftLons(rowStep:rowStep:end);
rightLons=rightLons(rowStep:rowStep:end);
upperLats=upperLats(colStep:colStep:end);
lowerLats=lowerLats(colStep:colStep:end);
upperLons=upperLons(colStep:colStep:end);
lowerLons=lowerLons(colStep:colStep:end);

latPerimeter=[upperLeftLat leftLats' lowerLeftLat lowerLats lowerRightLat rightLats(end:-1:1)' upperRightLat upperLats(end:-1:1) upperLeftLat];
lonPerimeter=[upperLeftLon leftLons' lowerLeftLon lowerLons lowerRightLon rightLons(end:-1:1)' upperRightLon upperLons(end:-1:1) upperLeftLon];
