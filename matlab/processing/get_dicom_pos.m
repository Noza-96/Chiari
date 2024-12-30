% Load the DICOM file
close all; clear;
filename = 'sample_dicom.dcm';
info = dicominfo(filename); % Get metadata
image_data = dicomread(filename); % Read pixel data

% Extract metadata
pixel_spacing = info.PixelSpacing; % [spacing_x; spacing_y]
image_position = info.ImagePositionPatient; % [x; y; z]
image_orientation = info.ImageOrientationPatient; % [row_dir_x; row_dir_y; row_dir_z; col_dir_x; col_dir_y; col_dir_z]

% Directions
row_direction = image_orientation(1:3);
col_direction = image_orientation(4:6);

% Image dimensions
[rows, cols] = size(image_data);

% Preallocate array for coordinates
coordinates = zeros(rows, cols, 3); % For (x, y, z) of each pixel

% Calculate 3D coordinates
for i = 1:rows
    for j = 1:cols
        coordinates(i, j, :) = image_position ...
                             + (i-1) * row_direction * pixel_spacing(2) ...
                             + (j-1) * col_direction * pixel_spacing(1);
    end
end

% Access the (x, y, z) position of a specific pixel (e.g., pixel[10, 20])
pixel_row = 10;
pixel_col = 20;
x = coordinates(pixel_row, pixel_col, 1);
y = coordinates(pixel_row, pixel_col, 2);
z = coordinates(pixel_row, pixel_col, 3);

fprintf('Pixel [%d, %d]: x=%.2f, y=%.2f, z=%.2f\n', pixel_row, pixel_col, x, y, z);
