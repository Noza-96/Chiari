function dat = define_ROI_video(cas, dat)
    for idat = 1:dat.Ndat

        sstt_name = strjoin(cellstr(string(cas.locations(idat))), '-');
        roi_dir   = fullfile(cas.dirmat,'ROIs');
        if ~exist(roi_dir, 'dir'), mkdir(roi_dir); end

        roi_file    = fullfile(roi_dir, sstt_name + "ROI.mat");
        vertex_file = fullfile(roi_dir, sstt_name + "ROI_vertices.mat");

        % decide whether to use existing ROIs
        if exist(roi_file,'file') == 0
            set_new_ROI = true;
        else
            disp("Previous ROI found for location: "+cas.locations(idat))
            display_regions(roi_file)
            answer = input("Do you want to use it? [y/n] ", 's');
            if answer == 'n'
                set_new_ROI = true;
            else
                load(roi_file, 'ROI_SAS','ROI_SPC','ROI_COR','ROI_TONS');
                dat.ROI_SAS{idat}=ROI_SAS;
                dat.ROI_COR{idat}=ROI_COR;
                dat.ROI_SPC{idat}=ROI_SPC;
                if exist('ROI_TONS','var'), dat.ROI_TONS{idat}=ROI_TONS; end
                disp("Using the previous ROI ...")
                close all;
                continue
            end
        end

        % build from scratch / edit
        has_vertices = exist(vertex_file, 'file');
        if has_vertices
            disp('Loading previous vertices ...')
            S = load(vertex_file);
            if ~isfield(S,'hvertices_dura'), S.hvertices_dura = []; end
            if ~isfield(S,'hvertices_pia'),  S.hvertices_pia  = []; end
            if ~isfield(S,'hvertices_tons'), S.hvertices_tons = []; end
        else
            disp('No previous vertex data found. You will need to draw the contours.')
            S = struct('hvertices_dura',[],'hvertices_pia',[],'hvertices_tons',[]);
        end

        % gather data
        Nt    = dat.Nt{idat};
        U_tot = dat.U_tot{idat};
        magni = dat.magni{idat};
        compl = dat.compl{idat};
        venc  = dat.venc{idat};

        satval = 0.9;

        [Ny, Nx] = size(U_tot(:, :, 1)); %#ok<ASGLU>

        % time-averaged helper images
        S_U_tot = sum(abs(U_tot), 3) / Nt;
        S_magni = sum(abs(magni), 3) / Nt;
        S_compl = sum(abs(compl), 3) / Nt;

        S_U_tot = imadjust(S_U_tot / max(S_U_tot(:)), [0.0, 0.9]);
        S_magni = imadjust(S_magni / max(S_magni(:)), [0.0, 0.9]);
        S_compl = imadjust(S_compl / max(S_compl(:)), [0.0, 0.9]);

        %% -------- DURA ----------
        disp("Please click on left or right panel and contour the DURA ...")
        show_composed_figure(S_compl, S_magni, S_U_tot)

        if ~isempty(S.hvertices_dura)
            h = drawpolygon('Position', S.hvertices_dura, 'Color', [1, 0, 0], 'FaceAlpha', 0);
        else
            waitforbuttonpress
            h = drawpolygon('Color', [1, 0, 0], 'FaceAlpha', 0);
        end
        pause
        hvertices_dura = h.Position;
        BW_SPC = logical(poly2mask(hvertices_dura(:,1), hvertices_dura(:,2), size(S_U_tot,1), size(S_U_tot,2)));

        % refine across time
        nshow = 0; it = 1; key = '';
        while nshow < 10000
            nshow = nshow + 1;
            S_compl_it = squeeze(compl(:,:,it)); S_compl_it = S_compl_it/max(S_compl_it(:)+eps);
            S_magni_it = squeeze(magni(:,:,it)); S_magni_it = S_magni_it/max(S_magni_it(:)+eps);
            S_Utot_it  = squeeze(U_tot(:,:,it))/(satval*venc);

            show_composed_figure(S_compl_it, S_magni_it, S_Utot_it)
            subaxis(1,3,1,'Margin',0,'Spacing',0); h = drawpolygon('Position', hvertices_dura,'Color',[1,0,0],'FaceAlpha',0);
            subaxis(1,3,2,'Margin',0,'Spacing',0); h = drawpolygon('Position', hvertices_dura,'Color',[1,0,0],'FaceAlpha',0);
            subaxis(1,3,3,'Margin',0,'Spacing',0); h = drawpolygon('Position', hvertices_dura,'Color',[1,0,0],'FaceAlpha',0);
            pause
            hvertices_dura = h.Position;
            BW_SPC = logical(poly2mask(hvertices_dura(:,1), hvertices_dura(:,2), size(S_U_tot,1), size(S_U_tot,2)));

            disp("j: next frame   k: previous frame   s: save");
            key = get_key();
            if key == 'j'
                it = it + 1; if it > Nt, it = 1; end
            elseif key == 'k'
                it = it - 1; if it < 1,  it = Nt; end
            elseif key == 's'
                disp('Dura saved. Moving on...')
                break
            end
        end

       

        %% -------- PIA ----------
        disp("Please click on left or right panel and contour the PIA ...")
        % show_composed_figure_after_dura(BW_SPC, S_compl, S_magni, S_U_tot)
        show_composed_figure(S_compl, S_magni, S_U_tot)

        if ~isempty(S.hvertices_pia)
            h = drawpolygon('Position', S.hvertices_pia, 'Color', [1, 0, 0], 'FaceAlpha', 0);
        else
            waitforbuttonpress
            h = drawpolygon('Color', [1, 0, 0], 'FaceAlpha', 0);
        end
        pause
        hvertices_pia = h.Position;
        BW_COR = logical(poly2mask(hvertices_pia(:,1), hvertices_pia(:,2), size(S_U_tot,1), size(S_U_tot,2)));

        nshow = 0; it = 1; key = '';
        while nshow < 10000
            nshow = nshow + 1;
            S_compl_it = squeeze(compl(:,:,it)); S_compl_it = S_compl_it/max(S_compl_it(:)+eps);
            S_magni_it = squeeze(magni(:,:,it)); S_magni_it = S_magni_it/max(S_magni_it(:)+eps);
            S_Utot_it  = squeeze(U_tot(:,:,it))/(satval*venc);

            show_composed_figure(S_compl_it, S_magni_it, S_Utot_it)
            subaxis(1,3,1,'Margin',0,'Spacing',0); h = drawpolygon('Position', hvertices_pia,'Color',[1,0,0],'FaceAlpha',0);
            subaxis(1,3,2,'Margin',0,'Spacing',0); h = drawpolygon('Position', hvertices_pia,'Color',[1,0,0],'FaceAlpha',0);
            subaxis(1,3,3,'Margin',0,'Spacing',0); h = drawpolygon('Position', hvertices_pia,'Color',[1,0,0],'FaceAlpha',0);
            pause
            hvertices_pia = h.Position;
            BW_COR = logical(poly2mask(hvertices_pia(:,1), hvertices_pia(:,2), size(S_U_tot,1), size(S_U_tot,2)));

            disp("j: next frame   k: previous frame   s: save");
            key = get_key();
            if key == 'j'
                it = it + 1; if it > Nt, it = 1; end
            elseif key == 'k'
                it = it - 1; if it < 1,  it = Nt; end
            elseif key == 's'
                disp('Pia saved. Moving on...')
                break
            end
        end

        % SAS region
        ROI_COR = logical(BW_COR);
        ROI_SPC = logical(BW_SPC);
        ROI_SAS = ROI_SPC & ~ ROI_COR;
        

        %% -------- TONSILS (optional) ----------
        disp("OPTIONAL: Contour the TONSILS (press 'q' now to skip if not visible).")
        show_composed_figure(S_compl, S_magni, S_U_tot)

        S_magni_in = BW_SPC .* S_magni;
        S_Utot_in  = BW_SPC .* S_U_tot;
        % show_tonsils_figure(S_magni_in, S_Utot_in)

        ROI_TONS = false(size(BW_SPC));   % default empty
        skipped_tonsils = false;
        do_tonsils = true;

        if ~isempty(S.hvertices_tons)
            h = drawpolygon('Position', S.hvertices_tons, 'Color', [1,1,0], 'FaceAlpha', 0);
        else
            disp("Press any key to start drawing polygon, or 'q' to skip.");
            wfbp = waitforbuttonpress;
            if wfbp
                key = get(gcf,'CurrentCharacter');
                if key == 'q'
                    disp("Skipping tonsils before drawing any polygon.");
                    skipped_tonsils = true;
                    do_tonsils = false;   % do not enter the edit loop
                    save(vertex_file, 'hvertices_pia', 'hvertices_dura');
                    close all;
                end
            end
            if do_tonsils
                h = drawpolygon('Color',[1,1,0],'FaceAlpha',0);
            end
        end

        if do_tonsils
            pause
            if ~isvalid(h) || isempty(h.Position)
                disp("Skipping tonsils (no polygon drawn).");
                skipped_tonsils = true;
                do_tonsils = false;
            else
                hvertices_tons = h.Position;
                BW_TONS = logical(poly2mask(hvertices_tons(:,1), hvertices_tons(:,2), size(S_U_tot,1), size(S_U_tot,2)));

                nshow = 0; it = 1; key = '';
                while nshow < 10000
                    nshow = nshow + 1;

                    S_compl_it = squeeze(compl(:,:,it)); S_compl_it = S_compl_it/max(S_compl_it(:)+eps);
                    S_magni_it = squeeze(magni(:,:,it)); S_magni_it = S_magni_it/max(S_magni_it(:)+eps);
                    S_Utot_it  = squeeze(U_tot(:,:,it))/(satval*venc);

                    S_magni_in_it = BW_SPC .* S_magni_it;
                    S_Utot_in_it  = BW_SPC .* S_Utot_it;

                    % 2-panel tonsils view
                    figure(99); clf
                    show_composed_figure(S_compl_it, S_magni_it, S_Utot_it)

                    subaxis(1,3,1,'Margin',0,'Spacing',0); h = drawpolygon('Position', hvertices_tons,'Color',[1,1,0],'FaceAlpha',0);
                    subaxis(1,3,2,'Margin',0,'Spacing',0); h = drawpolygon('Position', hvertices_tons,'Color',[1,1,0],'FaceAlpha',0);
                    subaxis(1,3,3,'Margin',0,'Spacing',0); h = drawpolygon('Position', hvertices_tons,'Color',[1,1,0],'FaceAlpha',0);
  
                    pause
                    hvertices_tons = h.Position;
                    BW_TONS = poly2mask(hvertices_tons(:,1), hvertices_tons(:,2), size(S_U_tot,1), size(S_U_tot,2));

                    disp("j: next   k: prev   s: save   q: skip tonsils");
                    key = get_key();
                    if key == 'j'
                        it = it + 1; if it > Nt, it = 1; end
                    elseif key == 'k'
                        it = it - 1; if it < 1,  it = Nt; end
                    elseif key == 's'
                        disp('Tonsils saved.')
                        ROI_TONS = logical(BW_TONS);
                        ROI_SAS  = ROI_SAS & ~ ROI_TONS;
                        ROI_TONS  = ROI_TONS & ~ ROI_COR;
                        save(vertex_file, 'hvertices_tons', 'hvertices_pia', 'hvertices_dura');
                        close all;
                        break
                    elseif key == 'q'
                        disp('Skipping tonsils for this location.')
                        skipped_tonsils = true;
                        ROI_TONS = false(size(BW_SPC));   % keep empty
                        save(vertex_file, 'hvertices_pia', 'hvertices_dura');
                        close all;
                        break
                    end
                end
            end
        end
       

        save(roi_file,'ROI_SAS','ROI_SPC','ROI_COR','ROI_TONS')

        dat.ROI_SAS{idat}=ROI_SAS;
        dat.ROI_COR{idat}=ROI_COR;
        dat.ROI_TONS{idat}=ROI_TONS;
        dat.ROI_SPC{idat}=ROI_SPC;
        

        display_regions(roi_file)
        pause 
    end

    function display_regions(roi_file)
        % Load ROIs
        load(roi_file,'ROI_SAS','ROI_SPC','ROI_COR','ROI_TONS')
        
        % Assign integer codes
        sas  = ROI_SAS * 1;   % SAS → 1
        cor  = ROI_COR * 2;   % COR → 2
        tons = ROI_TONS * 3;  % TONS → 3
        
        % Combine (take max so overlaps resolve by priority)
        L = max(sas, max(cor, tons));
        
        % Plot with discrete levels
        figure; hold on
        contourf(L, [0.5 1.5 2.5 3.5], 'LineColor','none');
        
        % Colormap with 3 fixed ROI colors (blue, red, yellow)
        cmap = [
            0 0 1;   % SAS
            1 0 0;   % COR
            1 1 0    % TONS
        ];
        colormap(cmap);
        caxis([0.5 3.5])   % lock to [1,3]
        
        axis equal tight ij
        colorbar('Ticks',[1,2,3], 'TickLabels',{'SAS','COR','TONS'})
        title('ROI masks')
        drawnow;
    end

    function key = get_key()
        key = '';
        wfbp = waitforbuttonpress;
        if wfbp
            key = get(gcf, 'CurrentCharacter');
        end
        if isempty(key), key = ''; end
    end

    function show_composed_figure(SC, SM, SU)
        figure(99)
        hF = gcf;
        monitors = get(0, 'MonitorPositions');
        monitor1 = monitors(1, :);
        hF.Position(1:2) = [monitor1(1)+80, monitor1(2)+80];
        hF.Position(3:4) = [3*(floor(monitor1(3)/3))-160, floor(monitor1(3)/3)-160];
        clf
        subaxis(1, 3, 1, 'Margin', 0, 'Spacing', 0)
        imshow(SC)
        text(4, 4, "COMPL", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 2, 'Margin', 0, 'Spacing', 0)
        imshow(SM)
        text(4, 4, "MAGNI", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 3, 'Margin', 0, 'Spacing', 0)
        imshow(SU, [-1.0, 1.0])
        text(4, 4, "UTOT", 'fontsize', 18, 'color', 'yellow')
        crameri vik
    end

    function show_composed_figure_after_dura(BW_SPC_in, SC, SM, SU)
        figure(99)
        hF = gcf;
        monitors = get(0, 'MonitorPositions');
        monitor1 = monitors(1, :);
        hF.Position(1:2) = [monitor1(1)+80, monitor1(2)+80 ];
        hF.Position(3:4) = [3*(floor(monitor1(3)/3))-160, floor(monitor1(3)/3)-160];
        clf
        subaxis(1, 3, 1, 'Margin', 0, 'Spacing', 0)
        imshow(BW_SPC_in .* SC)
        text(4, 4, "COMPL", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 2, 'Margin', 0, 'Spacing', 0)
        imshow(BW_SPC_in .* SM)
        text(4, 4, "MAGNI", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 3, 'Margin', 0, 'Spacing', 0)
        imshow(BW_SPC_in .* SU, [-1.0, 1.0])
        text(4, 4, "UTOT", 'fontsize', 18, 'color', 'yellow')
        crameri vik
    end

    function show_tonsils_figure(SM_in, SU_in)
        figure(99)
        hF = gcf;
        monitors = get(0, 'MonitorPositions');
        monitor1 = monitors(1, :);
        hF.Position(1:2) = [monitor1(1)+80, monitor1(2)+80 ];
        hF.Position(3:4) = [2*(floor(monitor1(3)/3))-160, floor(monitor1(3)/3)-160];
        clf
        subaxis(1, 2, 1, 'Margin', 0, 'Spacing', 0)
        imshow(SM_in)
        text(4, 4, "MAGNI (intra-dural)", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 2, 2, 'Margin', 0, 'Spacing', 0)
        imshow(SU_in, [-1.0, 1.0])
        text(4, 4, "UTOT (intra-dural)", 'fontsize', 18, 'color', 'yellow')
        crameri vik
    end


    function fill_mask(mask, rgb, alphaVal)
    % Fills each connected component of a logical mask with a semi-transparent patch.
    % mask: logical HxW
    % rgb:  1x3 color [r g b]
    % alphaVal: scalar in [0,1]
    if ~any(mask(:)), return; end
    B = bwboundaries(mask, 'noholes');
    % draw larger regions first (optional: nicer layering)
    areas = cellfun(@(b) polyarea(b(:,2), b(:,1)), B);
    [~, order] = sort(areas, 'descend');
    for ii = order(:)'
        b = B{ii};
        % x = columns, y = rows (imshow's coordinate system)
        patch('XData', b(:,2), 'YData', b(:,1), ...
              'FaceColor', rgb, 'FaceAlpha', alphaVal, ...
              'EdgeColor', 'none', 'LineStyle', 'none', ...
              'HitTest', 'off', 'PickableParts', 'none');
    end
end
end