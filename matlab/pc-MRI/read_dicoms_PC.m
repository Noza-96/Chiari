function dat  = read_dicoms_PC(cas, resettimevector)

    Ndat = length(cas.folders_PC);

    if strcmp(cas.model, 'GE')
        dicom_ext = 'MR*';
    elseif strcmp(cas.model, 'SIEMENS')
        dicom_ext = '*.dcm';
    end

    % Get data for each case and store in cell structures were first dimension is case number:

    pixel_coord = cell(1, Ndat);
    for idat = 1:Ndat
        
        disp([cas.dirdcm, '/', cas.folders_PC_P{idat}]);
        
        dicomlist = dir(fullfile([cas.dirdcm, '/', cas.folders_PC_P{idat}], dicom_ext));

        numim = numel(dicomlist);

        % Run through all files and collect useful headers and image matrices:

        for jj = 1:numim

            fname = fullfile([cas.dirdcm, '/', cas.folders_PC_P{idat}], dicomlist(jj).name);
            info{idat}{jj} = dicominfo(fname);

            % Hack to find VENC:
            if strcmp(cas.model, 'SIEMENS')
                command = sprintf('awk ''/^sAngio.sFlowArray.asElm\\[0\\].nVelocity/'' %s', fname);
                [status, sysout] = system(command);
                sysout = erase(sysout, "sAngio.sFlowArray.asElm[0].nVelocity");
                sysout = erase(sysout, "=");
                sysout = sysout(find(~isspace(sysout)));
                venc{idat}(jj) = str2num(sysout);
            elseif strcmp(cas.model, 'GE')
                venc{idat}(jj)        = 0.1 * double(info{idat}{jj}.(dicomlookup('0019', '10CC')));
                vencscale{idat}(jj)   = double(info{idat}{jj}.(dicomlookup('0019', '10E2')));
            end



            if isfield(info{idat}{jj}, 'TriggerTime') == 1
                triggertime{idat}(jj) = info{idat}{jj}.(dicomlookup('0018', '1060'));
            else
                disp("No TriggerTime dicom field, using 0.0!")
                triggertime{idat}(jj) = 0.0;
            end
            
            location{idat}(jj) = double(info{idat}{jj}.(dicomlookup('0020', '1041'))) / 10.0;

            pixspacing = double(info{idat}{jj}.(dicomlookup('0028', '0030')));

            fcal_V_cm_px{idat}(jj) = pixspacing(1) / 10.0;
            fcal_H_cm_px{idat}(jj) = pixspacing(2) / 10.0;

            im_unsorted{idat}{jj} = double(dicomread(info{idat}{jj}));

        end

        % Load DICOM files with magnitude out of parallel directory for complementary use:
        
        if isempty(cas.folders_PC_MAG) == 1
            
            display("Magnitude images do not exist.")

            % Set magnitude images to zero.

            for jj = 1:numim
                
                immag_unsorted{idat}{jj} = zeros(size(im_unsorted{idat}{jj}));
                
            end

        else

            dicomlist = dir(fullfile([cas.dirdcm, '/', cas.folders_PC_MAG{idat}], dicom_ext));

            numim = numel(dicomlist);

            fname_showorient{idat} = fullfile([cas.dirdcm, '/', cas.folders_PC_MAG{idat}], dicomlist(1).name);

            for jj = 1:numim

                fname = fullfile([cas.dirdcm, '/', cas.folders_PC_MAG{idat}], dicomlist(jj).name);

                infomag{idat}{jj} = dicominfo(fname);

                immag_unsorted{idat}{jj} = double(dicomread(infomag{idat}{jj}));

            end

        end

        % Load DICOM files with stuff out of parallel directory for complementary use:

        dicomlist = dir(fullfile([cas.dirdcm, '/', cas.folders_PC_{idat}], dicom_ext));

        numim = numel(dicomlist);

        for jj = 1:numim

            fname = fullfile([cas.dirdcm, '/', cas.folders_PC_{idat}], dicomlist(jj).name);

            infocom{idat}{jj} = dicominfo(fname);

            imcom_unsorted{idat}{jj} = double(dicomread(infocom{idat}{jj}));

        end

        % Sort images as pairs by triggertime:

        [dummy, sortind] = sortrows([triggertime{idat}.'], [1]);

        venc{idat}(:)         = venc{idat}(sortind);
        triggertime{idat}(:)  = triggertime{idat}(sortind);
        location{idat}(:)     = location{idat}(sortind);
        fcal_V_cm_px{idat}(:) = fcal_V_cm_px{idat}(sortind);
        fcal_H_cm_px{idat}(:) = fcal_H_cm_px{idat}(sortind);

        % these do not change in a time series so we only keep one:

        venc{idat} = venc{idat}(1);
        location{idat} = location{idat}(1);
        fcal_V_cm_px{idat} = fcal_V_cm_px{idat}(1);
        fcal_H_cm_px{idat} = fcal_H_cm_px{idat}(1);

        for jj = 1:numim
            im{idat}{jj}    = im_unsorted{idat}{sortind(jj)};
            immag{idat}{jj} = immag_unsorted{idat}{sortind(jj)};
            imcom{idat}{jj} = imcom_unsorted{idat}{sortind(jj)};    
        end

        % Extract metadata for coordinate calculation
        pixel_spacing = info{idat}{1}.PixelSpacing; % [spacing_x; spacing_y]
        image_position = info{idat}{1}.ImagePositionPatient; % [x; y; z]
        image_orientation = info{idat}{1}.ImageOrientationPatient; % [row_dir_x; row_dir_y; row_dir_z; col_dir_x; col_dir_y; col_dir_z]
        
        % Directions
        row_direction = image_orientation(1:3);
        col_direction = image_orientation(4:6); 

        % Image dimensions
        [rows, cols] = size(dicomread(info{idat}{1}));
        
        % Preallocate array for coordinates
        pixel_coordinates = zeros(rows, cols, 3); % For (x, y, z) of each pixel
        
        % Calculate 3D coordinates for each pixel
        for i = 1:rows
            for j = 1:cols
            pixel_coordinates(i, j, :) = image_position ...
                                       + (j-1) * row_direction * pixel_spacing(1) ...
                                       + (i-1) * col_direction * pixel_spacing(2);

            end
        end
        
        filename = cas.locations{idat} + "_transformation.txt";
        transformation_path = fullfile(cas.dirseg, 'transformation', filename);

        if exist(transformation_path)
            % Read the matrix (assumes 4 rows, 4 columns, space-separated)
            transformation_matrix = dlmread(transformation_path);
            
            % Display to verify
            fprintf('Transformation %s applied! \n', filename);
            
            disp(transformation_matrix);
            
            pixel_coordinates = applyTransformation(pixel_coordinates, transformation_matrix);
        end

        % Store in cell for this case
        pixel_coord{idat} = pixel_coordinates;


        for jj = 1:numim

            % Save the acquisition times in seconds:

            t{idat}(jj) = double(triggertime{idat}(jj)) / 1000.0;

            % Save the phase and magnitude images:

            phase{idat}(:, :, jj) = im{idat}{jj};
            magni{idat}(:, :, jj) = immag{idat}{jj};
            compl{idat}(:, :, jj) = imcom{idat}{jj};

            % Convert image pairs to velocity fields in cm/s (Note: positive is craniocaudal flow):
            
            % Convert image pairs to velocity fields in cm/s:
            if strcmp(cas.model, 'GE')
                Vscale{idat}(jj) = pi * vencscale{idat}(jj) / venc{idat};
                U_tot{idat}(:, :, jj) = (phase{idat}(:, :, jj) ./ max(magni{idat}(:, :, jj), 1)) / Vscale{idat}(jj);
            elseif strcmp(cas.model, 'SIEMENS')
                U_tot{idat}(:, :, jj) = - venc{idat} .* ( (phase{idat}(:, :, jj) - 2048) ./ 2048 );
            end

        end

        % We subtract whatever is needed to set the timestamp of the first time to zero:
        
        t{idat}(:) = t{idat}(:) - t{idat}(1);
        
        % Save the number of acquisition times, the length of one period in seconds (can be
        % overridden in step 1B):
        
        Nt{idat} = numim;

        dt{idat} = t{idat}(end)/(Nt{idat}-1);
        
        T{idat} = t{idat}(end) + dt{idat};

        % Sometimes the acquisition does not equispace the time vector.
        % We then set the time vector ourselves:

        if resettimevector
            t{idat}(:) = [0:1:Nt{idat}-1]*dt{idat};
        end
        
        % Save the slice location in cm:

        locz{idat} = -location{idat};
        
    end

    disp(' '); disp(' '); disp(' ')
    disp('List of all cases:')
    for idat = 1:Ndat
        disp([num2str(idat, '%02d'), '  -  ', cas.names{idat}])
    end
    disp(' '); disp(' '); disp(' ');


    dat.pixel_coord  = pixel_coord;
    dat.Ndat         = Ndat;
    dat.locz         = locz;
    dat.Nt           = Nt;
    dat.T            = T;
    dat.dt           = dt;
    dat.t            = t;
    dat.U_tot        = U_tot;
    dat.phase        = phase;
    dat.magni        = magni;
    dat.compl        = compl;
    dat.venc         = venc;
    dat.fcal_H_cm_px = fcal_H_cm_px;
    dat.fcal_V_cm_px = fcal_V_cm_px;

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

