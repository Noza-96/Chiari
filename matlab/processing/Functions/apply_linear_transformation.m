     
function dat_PC = apply_linear_transformation(dat_PC, cas)

    for idat = 1:dat_PC.Ndat
        filename = dat_PC.locations{idat} + "_transformation.txt";
        transformation_path = fullfile(cas.dir.seg, 'transformation', filename);
        
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


