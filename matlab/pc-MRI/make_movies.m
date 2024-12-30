function make_movies(cas, dat, whichfield)


    write_movie = true;

    fh = 99;
    figure(fh)

    for idat = 1:dat.Ndat

        if write_movie
            vid = VideoWriter([cas.dirvid, '/', cas.names{idat}]);
            vid.Quality   = 100;
            vid.FrameRate = 20;
            open(vid);
        end

        for it = 1:dat.Nt{idat}

            if     whichfield == 'U_tot'
                fieldtoplot = dat.U_tot{idat}(:, :, it);
            elseif whichfield == 'U_SAS'
                fieldtoplot = dat.U_CSF_SAS{idat}(:, :, it);
            else
                print('please specify field to plot')
            end

            sympcolor(fieldtoplot, fh)
            title(['t = ', num2str(dat.t{idat}(it)), ' s'])
            axis equal
            clim(dat.venc{idat}*[-0.5, 0.5])
            drawnow

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

    function sympcolor(field, fh)

        sortfield = sort(field(:));

        maxfield = sortfield(end-3);
        minfield = sortfield(1+3);

        maxabsfield = max(abs([minfield, maxfield]));

        set(groot, 'CurrentFigure', fh)
        pcolor(field)
        shading flat
        ax = gca;
        disableDefaultInteractivity(ax)
        set(gca, 'Ydir', 'reverse')
        clim(maxabsfield*[-1, 1])
        crameri berlin
        colorbar
        axis equal
        axis off
        drawnow

    end

end
