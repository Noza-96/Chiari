function dat = crop_data(cas, dat, croppedsize, single_reading)

    if isempty(single_reading) 
        sstt_name = "";
    else
        sstt_name = strjoin(cellstr(string(single_reading)), '-');
    end

    if exist(fullfile(cas.dirmat, sstt_name+"crop_xc_yc.mat")) == 0

        set_new_cropping = true;
        
    else

        disp("Previous cropping position found.")

        answer = input("Do you want to use it? [y/n] ", 's');
        
        if answer == 'n'
            set_new_cropping = true;
        else
            load(fullfile(cas.dirmat, sstt_name+"crop_xc_yc.mat"));
            set_new_cropping = false;
            disp("Using the previous cropping position.")
        end
        
    end

    if set_new_cropping
        
        fh = 99;

        for idat = 1:dat.Ndat

            disp("Click at the center of where to crop images ...")

            S_U_tot{idat} = sum(abs(dat.U_tot{idat}), 3)/dat.Nt{idat};
            S_compl{idat} = sum(abs(dat.compl{idat}), 3)/dat.Nt{idat};

            figure(fh)
            hF = gcf;
            monitors = get(0, 'MonitorPositions');
            monitor1 = monitors(1, :);
            hF.Position(1:2) = [monitor1(1)     monitor1(2)+80 ];
            hF.Position(3:4) = [monitor1(4)-200 monitor1(4)-200];
            clf
            imagesc(S_compl{idat} + S_U_tot{idat})
            cmocean gray

            [xc, yc] = ginput(1);

            xc = round(xc);
            yc = round(yc);

            crop_xc_yc{idat} = [xc, yc];

        end

        close(fh)

        save(fullfile(cas.dirmat, sstt_name+"crop_xc_yc.mat"), 'crop_xc_yc')


    end
    
    cl_orig = floor(0.5*croppedsize);

    for idat = 1:dat.Ndat
        
        cl = cl_orig;

        xc = crop_xc_yc{idat}(1);
        yc = crop_xc_yc{idat}(2);

        sizeorig = size(dat.phase{idat});

        ymax = sizeorig(1);
        xmax = sizeorig(2);

        if (xmax <= croppedsize) || (ymax <= croppedsize)
            disp("Crop size is larger than image size!")
            disp("Setting crop size equal to image size")
            cl = floor(0.5*min(xmax, ymax));
        end

        ycmcl_pre = yc-cl;
        ycpcl_pre = yc+cl;
        xcmcl_pre = xc-cl;
        xcpcl_pre = xc+cl;
        
        ycmcl = ycmcl_pre;
        ycpcl = ycpcl_pre;
        xcmcl = xcmcl_pre;
        xcpcl = xcpcl_pre;

        if ycmcl_pre < 1
            ycmcl = 0;
            ycpcl = 2.0*cl;
        end

        if ycpcl_pre > ymax
            ycpcl = ymax;
            ycmcl = ymax-2.0*cl;
        end

        if xcmcl_pre < 1
            xcmcl = 0;
            xcpcl = 2.0*cl;
        end

        if xcpcl_pre > xmax
            xcpcl = xmax;
            xcmcl = xmax-2.0*cl;
        end
        
        dat.phase{idat} = dat.phase{idat}(ycmcl+1 : ycpcl, xcmcl+1 : xcpcl, :);
        dat.magni{idat} = dat.magni{idat}(ycmcl+1 : ycpcl, xcmcl+1 : xcpcl, :);
        dat.compl{idat} = dat.compl{idat}(ycmcl+1 : ycpcl, xcmcl+1 : xcpcl, :);
        dat.U_tot{idat} = dat.U_tot{idat}(ycmcl+1 : ycpcl, xcmcl+1 : xcpcl, :);
        dat.pixel_coord{idat} = dat.pixel_coord{idat}(ycmcl+1 : ycpcl, xcmcl+1 : xcpcl, :);

    end

end
