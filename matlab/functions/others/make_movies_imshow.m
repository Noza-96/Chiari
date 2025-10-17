function make_movies_imshow(cas, dat, whichfield, whichidat, showroi)


    write_movie = true;

    fh = 99;
    figure(fh)

    for idat = whichidat 

        if write_movie
            vid = VideoWriter([cas.dirvid, '/', cas.names{idat}, '_', whichfield]);
            vid.Quality   = 90;
            vid.FrameRate = 30;
            open(vid);
        end

        minvel = min(min(min(dat.U_SAS{idat})))
        maxvel = max(max(max(dat.U_SAS{idat})))
        maxabsvel = max(abs(minvel), abs(maxvel));

        for it = 1:dat.Nt{idat}
            
            switch whichfield
                case 'phase'
                    field = dat.phase{idat}(:, :, it);
                    imshow(field, [0, 4095], 'InitialMagnification', 1000);
                case 'magni'
                    maxval = max(max(max(dat.magni{1}(:,:,:))));
                    field = dat.magni{idat}(:, :, it);
                    imshow(field, [0, maxval], 'InitialMagnification', 1000);
                case 'compl'
                    maxval = max(max(max(dat.compl{idat}(:,:,:))));
                    field = squeeze(dat.compl{idat}(:, :, it))/maxval;
                    if showroi
                        roi = edge(dat.ROI_SAS{idat}(:, :));
                        roirgb = cat(3, 1.0*roi, 1.0*roi, 1.0*roi);
                        %field = fieldrgb;
                        field = imfuse(fieldrgb, roirgb, 'blend');
                    end
                    fieldrgb = cat(3, field, field, field);
                    imshow(field, [0, 1.0], 'InitialMagnification', 1000);
                case 'U_tot'
                    field = dat.U_tot{idat}(:, :, it);
                    imshow(field, dat.venc{idat}*[-1.0, 1.0], 'InitialMagnification', 1000);
                    crameri bam
                case 'U_sas'
                    field3 = 0.5 + dat.U_SAS{idat}(:, :, it)/(2.0*maxabsvel);
                    cmap = crameri('vik', 256);
                    field = ind2rgb(gray2ind(field3, 256), cmap);
                    if showroi
                        roi = edge(dat.ROI_SAS{idat}(:, :));
                        roirgb = 1.0 - cat(3, 1.0*roi, 1.0*roi, 1.0*roi);
                        field = roirgb.*field;
                    end
                    imshow(field, 'InitialMagnification', 1000);
                case 'all3'
                    maxval1 = max(max(max(dat.compl{1}(:,:,:))));
                    field1 = squeeze(dat.compl{idat}(:, :, it))/maxval1;
                    field1rgb = cat(3, field1, field1, field1);

                    field2 = dat.phase{idat}(:, :, it)/4095;
                    field2rgb = cat(3, field2, field2, field2);

                    field3 = 0.5 + dat.U_SAS{idat}(:, :, it)/(2.0*maxabsvel);
                    cmap = crameri('vik', 256);
                    field3rgb = ind2rgb(gray2ind(field3, 256), cmap);
                    if showroi
                        roi = edge(dat.ROI_SAS{idat}(:, :));
                        roirgb = 1.0 - cat(3, 1.0*roi, 1.0*roi, 1.0*roi);
                        field3rgb = roirgb.*field3rgb;
                    end
                    field123 = cat(2, field1rgb, field2rgb, field3rgb);
                    
                    imshow(field123, 'InitialMagnification', 1000);
                case 'all4'
                    maxval1 = max(max(max(dat.compl{1}(:,:,:))));
                    field1 = squeeze(dat.compl{idat}(:, :, it))/maxval1;
                    field1rgb = cat(3, field1, field1, field1);

                    field2 = dat.phase{idat}(:, :, it)/4095;
                    field2rgb = cat(3, field2, field2, field2);

                    field3 = 0.5 + dat.U_SAS{idat}(:, :, it)/(2.0*maxabsvel);
                    cmap = crameri('vik', 256);
                    field3rgb = ind2rgb(gray2ind(field3, 256), cmap);
                    if showroi
                        roi = edge(dat.ROI_SAS{idat}(:, :));
                        roirgb = 1.0 - cat(3, 1.0*roi, 1.0*roi, 1.0*roi);
                        field3rgb = roirgb.*field3rgb;
                    end
                    
                    field4 = dat.pxpos_alias{idat}(:, :, it);
                    field4rgb = cat(3, field4, field4, field4);

                    field1234 = cat(2, field1rgb, field2rgb, field3rgb, field4rgb);
                    
                    imshow(field1234, 'InitialMagnification', 1000);

                otherwise
                    field = dat.U_tot{idat}(:, :, it);
                    imshow(field, dat.venc{idat}*[-1.0, 1.0], 'InitialMagnification', 1000);
                    crameri bam
            end


            %sympcolor(fieldtoplot, fh)
            %title(['t = ', num2str(dat.t{idat}(it)), ' s'])
            %axis equal
            %clim(dat.venc{idat}*[-0.5, 0.5])
            %drawnow

            if write_movie
                frame = getframe(fh);
                writeVideo(vid, frame);
            end

        end

        if write_movie
            close(vid)
        end

    end
    
    close(fh)

end

