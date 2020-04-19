
%
% ============================================================
% This script determines whether the TC track point falls within the
% satellite swath. If so, it tags the file to be copied to basin-specific
% directories. If not, the file is deleted from the local disk.
% ============================================================
%
% flags
% 0 = delete file (no match in either basin)
% 1 = keep file for Atlantic only
% 2 = keep file for Eastern Pacific only
% 3 = keep file for both the Atlantic and Eastern Pacific basins
%
% What is the starting time of the satellite swath?
%
inferior = min(timeS);
%
[yrinf, moinf, dainf, hrinf, mninf, scinf] = datevec(inferior);
%
reminf = hrinf + mninf / 60. + scinf / 3600.;
%
% Find candidate bounding best track points.
if reminf >= 0 && reminf < 6
    hrbtinf = 0.; hrbtsup = 6;
elseif reminf >= 6 && reminf < 12
    hrbtinf = 6; hrbtsup = 12;
elseif reminf >= 12 && reminf < 18
    hrbtinf = 12; hrbtsup = 18;
elseif reminf >= 18 && reminf < 24
    hrbtinf = 18; hrbtsup = 24;
end
%
btmin = datenum([yrinf moinf dainf hrbtinf 0 0]);
%
% Check to see if at least one upper bounding best track data point is
% available ; if not, the file should be deleted.
btmax = btmin + 0.25;
%
indbt = find(timeAll == btmax);
%
fileFlag = 0;
%
if ~isempty(indbt)
    n = length(indbt);
    for j = 1:n
        nmax = length(timeAll);
        if indbt(j) == 1
            delTimeSup = timeAll(2) - timeAll(indbt(j));
            if (delTimeSup == 0.25 && ...
                    strcmp(stidAll(2), stidAll(1)) )
                inx = [timeAll(1) timeAll(2)];
                inylon = [lonAll(1) lonAll(2)];
                inylat = [latAll(1) latAll(2)];
                interpLon = interp1(inx, inylon, timeS, 'linear', 'extrap');
                interpLat = interp1(inx, inylat, timeS, 'linear', 'extrap');
            else
                interpLon = lonAll(1) * ones(length(timeS), 1);
                interpLat = latAll(1) * ones(length(timeS), 1);
            end
        else
            delTimeInf = timeAll(indbt(j)) - timeAll(indbt(j)-1);
            %
            % Case where bounds exist
            % Point interpolated
            %
            if delTimeInf == 0.25 && ...
                    strcmp(stidAll(indbt(j)), stidAll(indbt(j)-1))
                inx = [timeAll(indbt(j) - 1) timeAll(indbt(j))];
                inylon = [lonAll(indbt(j) - 1) lonAll(indbt(j))];
                inylat = [latAll(indbt(j) - 1) latAll(indbt(j))];
                interpLon = interp1(inx, inylon, timeS, 'linear', 'extrap');
                interpLat = interp1(inx, inylat, timeS, 'linear', 'extrap');
            else
                interpLon = lonAll(indbt(j)) * ones(length(timeS), 1);
                interpLat = latAll(indbt(j)) * ones(length(timeS), 1);
            end

        end
        [arclen, az] = distance(interpLat, interpLon, ...
            squeeze(latS(104,:))', squeeze(lonS(104,:))');
        [mindist, imindist] = min(arclen);
        imindist = imindist(1);
        lonbt = interpLon(imindist); latbt = interpLat(imindist); 
        timeMx = timeS(imindist);
        localLats = latS > latbt - 10 & latS < latbt + 10;
        localLons = lonS > lonbt - 10 & lonS < lonbt + 10;
        localsInRow = sum(localLats & localLons);
        goodRows = find(localsInRow);
        if ~isempty(goodRows)
            
            %
            % later fix - determine number of polygons using difference of goodRows+1 - goodRows
            %
            indbreak = find(goodRows(2:end) - goodRows(1:end-1) ~= 1);
            npoly = length(indbreak) + 1;
            p1 = 1;
            p2 = length(goodRows);
            if ~isempty(indbreak)
                disp('mutliple polygons')
                p2 = indbreak(1);
            end
            %
            for k = 1:npoly
                lonMx = lonS(:,goodRows(p1:p2));
                latMx = latS(:,goodRows(p1:p2));
                btMx = btS(:,goodRows(p1:p2));
                %
                % Check polygon
                %
                lonPerim = [lonMx(1, :) lonMx(:, end)' lonMx(end, end:-1:1) ...
                    lonMx(end:-1:1, 1)'];
                latPerim = [latMx(1, :) latMx(:, end)' latMx(end, end:-1:1) ...
                    latMx(end:-1:1, 1)'];
               [yr, mo, da, hr, mn, sc]=datevec(timeMx);
%                 figure(1)
%                 plot(lonPerim, latPerim, lonbt, latbt, '*')
%                 title([num2str(hr) ':' num2str(mn) ':' num2str(sc) ' UTC ' ...
%                     num2str(mo) '/' num2str(da) '/' num2str(yr) ' ' ...
%                     stidAll(indbt(j))])
%                 figure(2)
%                 contourf(lonMx, latMx, btMx, 'linestyle', 'none'); colorbar
%                 title([num2str(hr) ':' num2str(mn) ':' num2str(sc) ' UTC ' ...
%                     num2str(mo) '/' num2str(da) '/' num2str(yr) ' ' ...
%                     stidAll(indbt(j))])
%                 caxis([180 280])
%                 pause
                fxInSwath = inpolygon(interpLon, interpLat, lonPerim, latPerim);
                if fxInSwath
                       fileFlag = 1;
                end
                %
                if length(indbreak) > 1 && k < npoly - 1
                    p1 = indbreak(k) + 1;
                    p2 = indbreak(k+1);
                end
                if k == npoly - 1
                    p1 = indbreak(k) + 1;
                    p2 = length(goodRows);
                end
                %
            end % end polygon loop
        end
    end
end
clear fxInSwath lonPerim latPerim lonbt latbt yr mo da hr mn sc *Mx
clear j k npoly nmax  *inf arclen az btmax btmin del* good* hrbt* imin* ind*
clear inferior interp* inx iny* local* mind* *S p* 
