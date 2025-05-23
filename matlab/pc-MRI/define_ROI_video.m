function dat = define_ROI_video(cas, dat)
    for idat = 1:dat.Ndat
    
        sstt_name = strjoin(cellstr(string(cas.locations(idat))), '-');
        % for each of the locations choose if you want to use the ROI 
        if exist(fullfile(cas.dirmat,'ROIs', sstt_name+"ROI.mat")) == 0
            set_new_ROI = true;       
        else
    
            disp("Previous ROI found for location: "+cas.locations(idat))
    
            answer = input("Do you want to use it? [y/n] ", 's');
            
            if answer == 'n'
                set_new_ROI = true;
            else
                load(fullfile(cas.dirmat,'ROIs', sstt_name+"ROI.mat"));
                set_new_ROI = false;
                disp("Using the previous ROI ...")
            end  
        end
        
        if set_new_ROI
            % see if there is polygon created
            vertex_file = fullfile(cas.dirmat, 'ROIs', sstt_name + "ROI_vertices.mat");
            has_vertices = exist(vertex_file, 'file');
            if has_vertices
                disp('Loading previous vertices ...')
            else
                disp('No previous vertex data found. You will need to draw the contours.')
            end
    
            Nt = dat.Nt{idat};
            
            U_tot = dat.U_tot{idat};
            magni = dat.magni{idat};
            compl = dat.compl{idat};
    
            venc = dat.venc{idat};
            
            satval = 0.9;
    
            [Ny, Nx] = size(U_tot(:, :, 1));
    
            S_U_tot = sum(abs(U_tot), 3) / Nt;
            S_magni = sum(abs(magni), 3) / Nt;
            S_compl = sum(abs(compl), 3) / Nt;
    
            S_U_tot = imadjust(S_U_tot / max(max(S_U_tot)), [0.0, 0.9]);
            S_magni = imadjust(S_magni / max(max(S_magni)), [0.0, 0.9]);
            S_compl = imadjust(S_compl / max(max(S_compl)), [0.0, 0.9]);
    
            disp("Please click on left or right panel and contour the DURA ...")
            show_composed_figure
            
            if has_vertices
                load(vertex_file, 'hvertices_dura');
                h = drawpolygon('Position', hvertices_dura, 'Color', [1, 0, 0], 'FaceAlpha', 0);
            else
                waitforbuttonpress
                h = drawpolygon('Color', [1, 0, 0], 'FaceAlpha', 0);
            end
            
            pause
            hvertices_dura = h.Position;
            BW_SPC = createMask(h);
            
            nshow = 0;
            it = 1;
            while nshow < 10000
                
                nshow = nshow + 1;
                
                S_compl = squeeze(compl(:, :, it))/max(max(compl(:,:,it)));
                S_magni = squeeze(magni(:, :, it))/max(max(magni(:,:,it)));
                S_U_tot = squeeze(U_tot(:, :, it))/(satval*venc);
    
                show_composed_figure
                
                subaxis(1, 3, 1, 'Margin', 0, 'Spacing', 0)
                h = drawpolygon('Position', hvertices_dura, 'Color', [1, 0, 0], 'FaceAlpha', 0);
                subaxis(1, 3, 2, 'Margin', 0, 'Spacing', 0)
                h = drawpolygon('Position', hvertices_dura, 'Color', [1, 0, 0], 'FaceAlpha', 0);
                subaxis(1, 3, 3, 'Margin', 0, 'Spacing', 0)
                h = drawpolygon('Position', hvertices_dura, 'Color', [1, 0, 0], 'FaceAlpha', 0);
                pause
                hvertices_dura = h.Position;
                BW_SPC = createMask(h);
                
                disp("j: next frame   k: previous frame   s: save");
                    
                wfbp = waitforbuttonpress;
                if wfbp
                    key = get(gcf, 'CurrentCharacter');
                end
    
                if key == 'j'
                    if it == Nt
                        it = 1;
                    else
                        it = it + 1;
                    end
                elseif key == 'k'
                    if it == 1
                        it = Nt;
                    else
                        it = it - 1;
                    end
                elseif key == 's'
                    disp('OK! moving on!')
                    break
                end
                
            end
    
            disp("Please click on left or right panel and contour the PIA ...")
            show_composed_figure_after_dura
            hold on
            
            if has_vertices
                load(vertex_file, 'hvertices_pia');
                h = drawpolygon('Position', hvertices_pia, 'Color', [1, 0, 0], 'FaceAlpha', 0);
            else
                waitforbuttonpress
                h = drawpolygon('Color', [1, 0, 0], 'FaceAlpha', 0);
            end
            
            pause
            hvertices_pia = h.Position;
            BW_COR = createMask(h);
            
            nshow = 0;
            it = 1;
            while nshow < 10000
                
                nshow = nshow + 1;
                it
                
                S_compl = squeeze(compl(:, :, it))/max(max(compl(:,:,it)));
                S_magni = squeeze(magni(:, :, it))/max(max(magni(:,:,it)));
                S_U_tot = squeeze(U_tot(:, :, it))/(satval*venc);
    
                show_composed_figure
                
                subaxis(1, 3, 1, 'Margin', 0, 'Spacing', 0)
                h = drawpolygon('Position', hvertices_pia, 'Color', [1, 0, 0], 'FaceAlpha', 0);
                subaxis(1, 3, 2, 'Margin', 0, 'Spacing', 0)
                h = drawpolygon('Position', hvertices_pia, 'Color', [1, 0, 0], 'FaceAlpha', 0);
                subaxis(1, 3, 3, 'Margin', 0, 'Spacing', 0)
                h = drawpolygon('Position', hvertices_pia, 'Color', [1, 0, 0], 'FaceAlpha', 0);
                pause
                hvertices_pia = h.Position;
                BW_COR = createMask(h);
                
                disp("j: next frame   k: previous frame   s: save");
                    
                wfbp = waitforbuttonpress;
                if wfbp
                    key = get(gcf, 'CurrentCharacter');
                    disp(key) %displays the character that was pressed
                end
                
                if key == 'j'
                    if it == Nt
                        it = 1;
                    else
                        it = it + 1;
                    end
                elseif key == 'k'
                    if it == 1
                        it = Nt;
                    else
                        it = it - 1;
                    end
                elseif key == 's'
                    disp('OK! moving on!')
                    break
                end
                
            end
            waitforbuttonpress
    
            BW_SAS = imsubtract(BW_SPC, BW_COR);
    
            ROI_SAS = BW_SAS;
            ROI_COR = BW_COR;
            ROI_SPC = BW_SPC;
    
            clear BW_SAS
            clear BW_COR
            clear BW_SPC
    
            figure(99)
            clf
            fused = imfuse(S_U_tot, ROI_SAS);
            imshow(fused, 'InitialMagnification', 400)
            pause
    
            % save poligon data
            save(vertex_file, 'hvertices_dura', 'hvertices_pia');
        end
    
        save(fullfile(cas.dirmat,'ROIs', sstt_name+"ROI.mat"), 'ROI_SAS', 'ROI_SPC', 'ROI_COR')

        dat.ROI_SAS{idat}=ROI_SAS;
        dat.ROI_COR{idat}=ROI_COR;
        dat.ROI_SPC{idat}=ROI_SPC;

        close all;
    end
    
    function show_composed_figure
    
        figure(99)
        hF = gcf;
        monitors = get(0, 'MonitorPositions');
        monitor1 = monitors(1, :);
        hF.Position(1:2) = [monitor1(1)+80               monitor1(2)+80 ];
        hF.Position(3:4) = [3*(floor(monitor1(3)/3))-160 floor(monitor1(3)/3)-160];
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
        imshow(S_U_tot, [-1.0, 1.0])
        text(4, 4, "UTOT", 'fontsize', 18, 'color', 'yellow')
        crameri vik
    
    end
    
    function show_composed_figure_after_dura
    
        figure(99)
        hF = gcf;
        monitors = get(0, 'MonitorPositions');
        monitor1 = monitors(1, :);
        hF.Position(1:2) = [monitor1(1)+80               monitor1(2)+80 ];
        hF.Position(3:4) = [3*(floor(monitor1(3)/3))-160 floor(monitor1(3)/3)-160];
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
        imshow(BW_SPC .* S_U_tot, [-1.0, 1.0])
        text(4, 4, "UTOT", 'fontsize', 18, 'color', 'yellow')
        crameri vik
    
    end

end
