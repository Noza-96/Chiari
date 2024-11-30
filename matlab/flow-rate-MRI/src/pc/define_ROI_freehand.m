function dat = define_ROI_freehand(cas, dat)

    if exist([cas.dirmat, '/ROI.mat']) == 0

        set_new_ROI = true;
        
    else

        disp("Previous ROI found.")

        answer = input("Do you want to use it? [y/n] ", 's');
        
        if answer == 'n'
            set_new_ROI = true;
        else
            load([cas.dirmat, '/ROI.mat']);
            set_new_ROI = false;
            disp("Using the previous ROI ...")
        end
        
    end
    
    if set_new_ROI

        for idat = 1:dat.Ndat
            
            Nt = dat.Nt{idat};
            
            U_tot = dat.U_tot{idat};
            magni = dat.magni{idat};
            compl = dat.compl{idat};

            [Ny, Nx] = size(U_tot(:, :, 1));

            S_U_tot = sum(abs(U_tot), 3) / Nt;
            S_magni = sum(abs(magni), 3) / Nt;
            S_compl = sum(abs(compl), 3) / Nt;

            S_U_tot = imadjust(S_U_tot / max(max(S_U_tot)), [0.0, 0.9]);
            S_magni = imadjust(S_magni / max(max(S_magni)), [0.0, 0.9]);
            S_compl = imadjust(S_compl / max(max(S_compl)), [0.0, 0.9]);

            disp("Please click on left or right panel and contour the DURA ...")
            
            show_composed_figure
            
            waitforbuttonpress

            h = drawpolygon('Color', [1, 0, 0])
            pause
            BW_SPC = createMask(h);

            disp("Please click on left or right panel and contour the PIA ...")

            show_composed_figure_after_dura
            hold on

            waitforbuttonpress

            h = drawpolygon('Color', [0, 1, 0]);
            pause
            BW_COR = createMask(h);

            BW_SAS = imsubtract(BW_SPC, BW_COR);

            ROI_SAS{idat} = BW_SAS;
            ROI_COR{idat} = BW_COR;
            ROI_SPC{idat} = BW_SPC;

            clear BW_SAS
            clear BW_COR
            clear BW_SPC

            figure(99)
            clf
            fused = imfuse(S_U_tot, ROI_SAS{idat});
            imshow(fused, 'InitialMagnification', 400)
            pause

        end

        save([cas.dirmat, '/ROI.mat'], 'ROI_SAS', 'ROI_SPC', 'ROI_COR')
    
    end

    dat.ROI_SAS = ROI_SAS;
    dat.ROI_COR = ROI_COR;
    dat.ROI_SPC = ROI_SPC;
    
    function show_composed_figure

        figure(99)
        hF = gcf;
        monitors = get(0, 'MonitorPositions');
        monitor1 = monitors(1, :);
        hF.Position(1:2) = [monitor1(1)         monitor1(2)+80 ];
        hF.Position(3:4) = [3*(floor(monitor1(3)/3)) floor(monitor1(3)/3)];
        clf
        subaxis(1, 3, 1, 'Margin', 0, 'Spacing', 0)
        imshow(S_compl)
        text(4, 4, "COMPL", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 2, 'Margin', 0, 'Spacing', 0)
        imshow(S_magni)
        text(4, 4, "MAGNI", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 3, 'Margin', 0, 'Spacing', 0)
        imshow(S_U_tot)
        text(4, 4, "UTOT", 'fontsize', 18, 'color', 'yellow')
        crameri davos

    end
    
    function show_composed_figure_after_dura

        figure(99)
        hF = gcf;
        monitors = get(0, 'MonitorPositions');
        monitor1 = monitors(1, :);
        hF.Position(1:2) = [monitor1(1)         monitor1(2)+80 ];
        hF.Position(3:4) = [3*(floor(monitor1(3)/3)) floor(monitor1(3)/3)];
        clf
        subaxis(1, 3, 1, 'Margin', 0, 'Spacing', 0)
        imshow(BW_SPC .* S_compl)
        text(4, 4, "COMPL", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 2, 'Margin', 0, 'Spacing', 0)
        imshow(BW_SPC .* S_magni)
        text(4, 4, "MAGNI", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 3, 'Margin', 0, 'Spacing', 0)
        imshow(BW_SPC .* S_U_tot)
        text(4, 4, "UTOT", 'fontsize', 18, 'color', 'yellow')
        crameri davos

    end

end
