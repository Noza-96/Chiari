function [cas,dat_PC] = main_2_crop_set_roi(cas,dat_PC, crop_size)

fprintf('\n4) PC-MRI measurements:\n')

data_name = "data_1.mat";

% Check if data needs to be created/updated
d_prev = dir(fullfile(cas.dir.mat,"data_0.mat"));
d_now = dir(fullfile(cas.dir.mat,data_name));

dlist = dir(fullfile(cas.dir.trans, '*'));

if ~isempty(dlist)
    latestDate = max([dlist.datenum, d_prev.datenum]);
else
    latestDate = d_prev.datenum;
end

if exist(fullfile(cas.dir.mat,data_name), 'file')
    if datetime(latestDate, 'ConvertFrom', 'datenum') > datetime(d_now.datenum, 'ConvertFrom', 'datenum')
        fprintf("- Data needs to be updated...\n")
    else
        if askYN('- Data up to date. Skip? ([y]/n): ')
            load(fullfile(cas.dir.mat, data_name'), 'cas', 'dat_PC');
            return;
        end
    end
end


fprintf("- Apply linear transformation to align DICOMs with segmentation...\n")
dat_PC = apply_linear_transformation(dat_PC, cas);

fprintf("\n- Cropping data... \n")

dat_PC = crop_data(cas, dat_PC, crop_size);

fprintf("\n- Setting up ROIs... ")

dat_PC = define_ROI_video(cas, dat_PC);

fprintf("\n\nSaving %s ...\n\n", data_name)

save(fullfile(cas.dir.mat, data_name), 'cas', 'dat_PC');

end

     
function dat_PC = apply_linear_transformation(dat_PC, cas)

    for idat = 1:dat_PC.Ndat
        data_name = dat_PC.locations{idat} + "_transformation.txt";
        transformation_path = fullfile(cas.dir.seg, 'transformation', data_name);
        
        if exist(transformation_path, 'file')
            % Read the matrix (assumes 4 rows, 4 columns, space-separated)
            transformation_matrix = dlmread(transformation_path);
                     
            dat_PC.pixel_coord{idat} = applyTransformation(dat_PC.pixel_coord{idat}, transformation_matrix);
        
            % Display to verify
            fprintf('\tTransformation %s applied! \n', dat_PC.locations{idat});
        else
            fprintf('\tThere is no transformation for: %s \n', dat_PC.locations{idat});
        end
    end
end

function transformed_pixel_coordinates = applyTransformation(pixel_coordinates, transformation_matrix)
% Apply a 4x4 transformation matrix to a [rows x cols x 3] pixel coordinate grid
%
% Inputs:
%   pixel_coordinates     - [rows x cols x 3] array of original (x,y,z) positions
%   transformation_matrix - [4 x 4] transformation matrix from 3D slicer
%
% Output:
%   transformed_pixel_coordinates - [rows x cols x 3] array of transformed positions

    % Get dimensions
    [rows, cols, ~] = size(pixel_coordinates);
    N = rows * cols;

    % Flatten pixel coordinates into [N x 3]
    coords = reshape(pixel_coordinates, [N, 3]);

    % Convert to homogeneous coordinates [N x 4]
    coords_hom = [coords, ones(N, 1)];

    % Apply transformation matrix [N x 4]
    transformed_coords_hom = (transformation_matrix * coords_hom')';  % [N x 4]

    % Extract (x, y, z)
    transformed_coords = transformed_coords_hom(:, 1:3);

    % Reshape back to [rows x cols x 3]
    transformed_pixel_coordinates = reshape(transformed_coords, [rows, cols, 3]);
end


function dat = crop_data(cas, dat, croppedsize)


    if exist(fullfile(cas.dir.mat, "crop_xc_yc.mat"), 'file') == 0

        set_new_cropping = true;
        
    else

        fprintf("\tPrevious cropping positions found.\n\t")

        answer = input("Do you want to use it? [y]/n ", 's');
        
        if answer == 'n'
            set_new_cropping = true;
        else
            load(fullfile(cas.dir.mat, "crop_xc_yc.mat"));
            set_new_cropping = false;
        end
        
    end

    if set_new_cropping
        
        fh = 99;

        for idat = 1:dat.Ndat

            fprintf("\tClick at the center of where to crop images ...")

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

        save(fullfile(cas.dir.mat, "crop_xc_yc.mat"), 'crop_xc_yc')


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
            fprintf("\tCrop size is larger than image size!")
            fprintf("\tSetting crop size equal to image size")
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

function dat = define_ROI_video(cas, dat)
    for idat = 1:dat.Ndat

        sstt_name = strjoin(cellstr(string(cas.locations(idat))), '-');
        roi_dir   = fullfile(cas.dir.mat,'ROIs');
        if ~exist(roi_dir, 'dir'), mkdir(roi_dir); end

        roi_file    = fullfile(roi_dir, sstt_name + "ROI.mat");
        vertex_file = fullfile(roi_dir, sstt_name + "ROI_vertices.mat");
        
        % decide whether to use existing ROIs
        if exist(roi_file,'file')
            fprintf("\n\tPrevious ROI found for location: %s \n\t", cas.locations{idat})
            display_regions(roi_file, cas.locations{idat})
            answer = input("Do you want to use it? [y]/n ", 's');
            if ~(answer == "n")
                load(roi_file, 'ROI_SAS','ROI_DURA','ROI_CORD','ROI_TONS');
                dat.ROI_SAS{idat}=ROI_SAS;
                dat.ROI_CORD{idat}=ROI_CORD;
                dat.ROI_DURA{idat}=ROI_DURA;
                if exist('ROI_TONS','var'), dat.ROI_TONS{idat}=ROI_TONS; end
                close all;
                continue
            end
        end
        previous_ROI = 0;
        % build from scratch / edit
        has_vertices = exist(vertex_file, 'file');
        if has_vertices
            previous_ROI = 1;
            fprintf('\tLoading previous vertices ...\n')
            S = load(vertex_file);
            if ~isfield(S,'hvertices_dura'), S.hvertices_dura = []; end
            if ~isfield(S,'hvertices_cord'),  S.hvertices_cord  = []; end
            if ~isfield(S,'hvertices_tons'), S.hvertices_tons = []; end
        else
            fprintf('\tNo previous vertex data found.')
            S = struct('hvertices_dura',[],'hvertices_cord',[],'hvertices_tons',[]);
        end

        % gather data
        Nt    = dat.Nt{idat};
        U_tot = dat.U_tot{idat};
        magni = dat.magni{idat};
        phase = dat.phase{idat};
        venc  = dat.venc{idat};

        satval = 0.9;

        [Ny, Nx] = size(U_tot(:, :, 1)); %#ok<ASGLU>

        % time-averaged helper images
        S_U_tot = sum(abs(U_tot), 3) / Nt;
        S_magni = sum(abs(magni), 3) / Nt;
        S_phase = sum(abs(phase), 3) / Nt;

        S_U_tot = imadjust(S_U_tot / max(S_U_tot(:)), [0.0, 0.9]);
        S_magni = imadjust(S_magni / max(S_magni(:)), [0.0, 0.9]);
        S_phase = imadjust(S_phase / max(S_phase(:)), [0.0, 0.9]);

        %% -------- DURA ----------
        [BW_DURA, hvertices_dura] = ROI_location(S_phase, S_magni, S_U_tot, S.hvertices_dura, "DURA", previous_ROI);   

        %% -------- CORD ----------
        [BW_CORD, hvertices_cord] = ROI_location(S_phase, S_magni, S_U_tot, S.hvertices_cord, "CORD", previous_ROI); 

        % SAS region
        ROI_CORD = logical(BW_CORD);
        ROI_DURA = logical(BW_DURA);
        ROI_SAS = ROI_DURA & ~ ROI_CORD;

        % S_magni_in = BW_DURA .* S_magni;
        % S_Utot_in  = BW_DURA .* S_U_tot;
        ROI_TONS = false(size(BW_DURA));

        %% -------- TONSILS (optional) ----------
        [BW_TONS, hvertices_tons] = ROI_location(S_phase, S_magni, S_U_tot, S.hvertices_tons, "TONSILS", previous_ROI);

        if isempty(BW_TONS)
            ROI_TONS = false(size(BW_DURA));   % keep empty
            save(vertex_file, 'hvertices_cord', 'hvertices_dura');
            close all;
        else
            ROI_TONS = logical(BW_TONS);
            ROI_SAS  = ROI_SAS & ~ ROI_TONS;
            ROI_TONS  = ROI_TONS & ~ ROI_CORD;
            save(vertex_file, 'hvertices_tons', 'hvertices_cord', 'hvertices_dura');
            close all;
        end     

        save(roi_file,'ROI_SAS','ROI_DURA','ROI_CORD','ROI_TONS')

        dat.ROI_SAS{idat}=ROI_SAS;
        dat.ROI_CORD{idat}=ROI_CORD;
        dat.ROI_TONS{idat}=ROI_TONS;
        dat.ROI_DURA{idat}=ROI_DURA;
        

        display_regions(roi_file, cas.locations{idat})
        pause 
        close all;
    end

    function display_regions(roi_file, location)
        % Load ROIs
        load(roi_file,'ROI_SAS','ROI_DURA','ROI_CORD','ROI_TONS')
        
        % Assign integer codes
        sas  = ROI_SAS * 1;   % SAS → 1
        cord = ROI_CORD * 2;   % cord → 2
        tons = ROI_TONS * 3;  % TONS → 3
        
        % Combine (take max so overlaps resolve by priority)
        L = max(sas, max(cord, tons));
        
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
        caxis([0.5 3.5]);   % lock to [1,3]
        
        axis equal tight ij
        colorbar('Ticks',[1,2,3], 'TickLabels',{'SAS','COR','TONS'})
        title(location)
        drawnow;
    end

    function key = get_key()
        % key = '';
        % wfbp = waitforbuttonpress;
        % if wfbp
            key = get(gcf, 'CurrentCharacter');
            if isempty(key)
                key = ''; 
            else
                key = char(key);
            end
        % end
    end

    function show_composed_figure(SC, SM, SU, tt, ini)
        % Default value for ini if not provided
        if nargin < 5
            ini = 1;  % or whatever default you want
        end
        figure(99)
        hF = gcf;
        monitors = get(0, 'MonitorPositions');
        monitor1 = monitors(1, :);
        hF.Position(3:4) = [3*(floor(monitor1(3)/3))-100, floor(monitor1(3)/3)-80];
        % Compute centered horizontal position
        centerX = monitor1(1) + (monitor1(3) - hF.Position(3)) / 2;
        % Align to top (small margin if you want)
        marginTop = 100; % pixels below the top edge
        topY = monitor1(2) + monitor1(4) - hF.Position(4) - marginTop;
        hF.Position(1:2) = [centerX, topY];
        clf
        subaxis(1, 3, 1,  'Spacing', 0)
        imshow(SC)
        text(4, 4, "PHASE", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 2,  'Spacing', 0)
        imshow(SM)
        text(4, 4, "MAGNI", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 3,  'Spacing', 0)
        imshow(SU, [-1.0, 1.0])
        text(4, 4, "U", 'fontsize', 18, 'color', 'yellow')
        crameri vik
        if ini == 0
            if lower(tt) == "tonsils"
                sstt = "\bf(OPTIONAL, q:quit) Click on left or right panel and contour the " + tt + "";
            else
                sstt = "\bfClick on left or right panel and contour the " + tt;
            end
        else
            if lower(tt) == "tonsils"
                sstt = "\bfContour the " + tt + "\rm   (j:next frame, k:previous frame, s:save, q:quit)";
            else
                sstt = "\bfContour the " + tt + "\rm   (j:next frame, k:previous frame, s:save)";
            end
        end
        sgtitle(sstt, 'FontSize', 14, 'Interpreter', 'tex');
    end

    function show_composed_figure_after_dura(BW_DURA_in, SC, SM, SU)
        figure(99)
        hF = gcf;
        monitors = get(0, 'MonitorPositions');
        monitor1 = monitors(1, :);
        hF.Position(3:4) = [3*(floor(monitor1(3)/3))-160, floor(monitor1(3)/3)-160];
        % Compute centered horizontal position
        centerX = monitor1(1) + (monitor1(3) - hF.Position(3)) / 2;
        hF.Position(1:2) = [centerX, monitor1(2) + 20];
        clf
        subaxis(1, 3, 1, 'Margin', 0, 'Spacing', 0)
        imshow(BW_DURA_in .* SC)
        text(4, 4, "PHASE", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 2, 'Margin', 0, 'Spacing', 0)
        imshow(BW_DURA_in .* SM)
        text(4, 4, "MAGNI", 'fontsize', 18, 'color', 'yellow')
        crameri lapaz
        subaxis(1, 3, 3, 'Margin', 0, 'Spacing', 0)
        imshow(BW_DURA_in .* SU, [-1.0, 1.0])
        text(4, 4, "UTOT", 'fontsize', 18, 'color', 'yellow')
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

    function [BW, hvertices] = ROI_location(S_phase, S_magni, S_U_tot, vertices, tt, previous_ROI)
        
        show_composed_figure(S_phase, S_magni, S_U_tot, tt, previous_ROI)
    
        if ~isempty(vertices)
            h = drawpolygon('Position', vertices, 'Color', [1, 0, 0], 'FaceAlpha', 0);
        else
            waitforbuttonpress
            if lower(tt) == "tonsils"
                key = get_key();
                if key == 'q' 
                    BW = [];
                    hvertices = [];
                    return
                end
            end
            h = drawpolygon('Color', [1, 0, 0], 'FaceAlpha', 0);
        end
        pause
        hvertices = h.Position;
        BW = logical(poly2mask(hvertices(:,1), hvertices(:,2), size(S_U_tot,1), size(S_U_tot,2)));
    
        % refine across time
        nshow = 0; it = 1;
        while nshow < 10000
            nshow = nshow + 1;
            S_phase_it = squeeze(phase(:,:,it)); S_phase_it = S_phase_it/max(S_phase_it(:)+eps);
            S_magni_it = squeeze(magni(:,:,it)); S_magni_it = S_magni_it/max(S_magni_it(:)+eps);
            S_Utot_it  = squeeze(U_tot(:,:,it))/(satval*venc);
    
            show_composed_figure(S_phase_it, S_magni_it, S_Utot_it, tt)
            subaxis(1,3,1); 
            h = drawpolygon('Position', hvertices,'Color',[1,0,0],'FaceAlpha',0);
            subaxis(1,3,2); 
            h = drawpolygon('Position', hvertices,'Color',[1,0,0],'FaceAlpha',0);
            subaxis(1,3,3); 
            h = drawpolygon('Position', hvertices,'Color',[1,0,0],'FaceAlpha',0);
            pause
            hvertices = h.Position;
            BW = logical(poly2mask(hvertices(:,1), hvertices(:,2), size(S_U_tot,1), size(S_U_tot,2)));
            key = get_key();
            if key == 'q' && (lower(tt) == "tonsils")
              BW = [];
              break
            end
            if key == 'j'
                it = it + 1; if it > Nt, it = 1; end
            elseif key == 'k'
                it = it - 1; if it < 1,  it = Nt; end
            elseif key == 's'
                break
            end
        end
    end
end

