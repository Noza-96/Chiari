%Create velocity profile from velocity measurements and mesh points (bottom)

function [u_MRI,Q_MRI,A_MRI,u,Q,A,t,x_bottom,y_bottom] = MRI_to_ansys_inlet_velocity(subject,dat_PC,all_visualizations) 

    % Coordinates surface inlet
    points_bottom = readmatrix("bottom.csv");

    x_bottom = points_bottom(:, 1);
    y_bottom = points_bottom(:, 2);

    % Coordinates wall
    points_wall = readmatrix('wall');
    
    % Step 2: Extract relevant columns
    x_wall = points_wall(:, 2);         % x-coordinates
    y_wall = points_wall(:, 3);         % y-coordinates
    z_velocity = points_wall(:, 5);     % z-velocity
    
    % Step 3: Filter points where z_velocity is zero (outer wall points)
    ind_k = (z_velocity == 0);
    
    x_wall_filtered = x_wall(ind_k); 
    y_wall_filtered = y_wall(ind_k);
    
    % Step 4: Find the boundary for the outer wall
    outer_bound = boundary(x_wall_filtered, y_wall_filtered);
    x_out = x_wall_filtered(outer_bound);
    y_out = y_wall_filtered(outer_bound);
    
    % Step 5: Remove outer boundary points to get the inner wall points
    x_in = x_wall_filtered;
    y_in = y_wall_filtered;
    x_in(outer_bound) = [];
    y_in(outer_bound) = [];
    
    % Step 6: Find the boundary for the inner wall
    inner_bound = boundary(x_in, y_in);
    x_in = x_in(inner_bound);
    y_in = y_in(inner_bound);
    
    % Optional: Save the results in a .mat file
    save("data/"+subject+"/wall_processed.mat", 'x_out', 'y_out', 'x_in', 'y_in');

    
    % Optional: visualize the points
    if all_visualizations
        figure;
        plot(x_wall, y_wall, 'b.');
        hold on;
        % plot(x_bottom, y_bottom, 'r.');
        hold on;
        plot(x_out, y_out, 'k-');
        plot(x_in, y_in, 'k-');
        xlabel('X');
        ylabel('Y');
        title('Wall Points (Blue) and Bottom Points (Red)');
        legend('Wall Points', 'Bottom Points', 'Outer', 'Inner');
        hold off;
        grid on;
    end
    %% 3. Read the velocity measurements obtained from MRI
    load("03-apply_roi_compute_Q.mat");
    loc = length(dat_PC.ROI_SAS);
    ROI_U = dat_PC.ROI_SAS{loc};
    u_MRI = -dat_PC.U_SAS{loc};
    Nt = dat_PC.Nt{loc};
    t=linspace(0,dat_PC.T{1},Nt);
    
    % Optional: visualize the measurements
    if all_visualizations
        figure;
        for n = 1:Nt
            imagesc(u_MRI(:,:,n));
            bluetored(u_MRI(:,:,n));
            xlabel('X');
            ylabel('Y');
            title(sprintf('Velocity Profile for n = %.0f seconds', n));
        end
    end
    %% 4. Put the U values on the same space as the mesh points
    % Flip the original ROI mask
    ROI_U_flipped = flipud(ROI_U);
    
    % Bounding box for the contours
    min_x_out = min(x_out); max_x_out = max(x_out); min_y_out = min(y_out); max_y_out = max(y_out);
    % min_x_in = min(x_in); max_x_in = max(x_in); min_y_in = min(y_in); max_y_in = max(y_in);
    
    % Bounding box for the binary mask
    [mask_y, mask_x] = find(ROI_U_flipped);
    min_x_mask = min(mask_x); max_x_mask = max(mask_x); min_y_mask = min(mask_y); max_y_mask = max(mask_y);
    % Determine the center and size of bounding boxes
    center_x_out = (min_x_out + max_x_out) / 2; center_y_out = (min_y_out + max_y_out) / 2;
    width_out = max_x_out - min_x_out; height_out = max_y_out - min_y_out;
    center_x_mask = (min_x_mask + max_x_mask) / 2; center_y_mask = (min_y_mask + max_y_mask) / 2;
    width_mask = max_x_mask - min_x_mask; height_mask = max_y_mask - min_y_mask;
    % Compute scale factors
    scale_x = width_mask / width_out; scale_y = height_mask / height_out;
    % Compute translation vectors
    translation_x = center_x_mask - center_x_out * scale_x; translation_y = center_y_mask - center_y_out * scale_y;
    % Apply scaling and translation
    x_in_aligned = (x_in * scale_x) + translation_x;      y_in_aligned = (y_in * scale_y) + translation_y;
    x_out_aligned = (x_out * scale_x) + translation_x;    y_out_aligned = (y_out * scale_y) + translation_y;
    
    %% 5. Alignement two masks
    
    % Prepare contour points for transformation
    contours_out = [x_out_aligned, y_out_aligned];
    contours_in = [x_in_aligned, y_in_aligned];
    
    % Create a reference image for alignment (binary image with contours)
    ref_image = zeros(size(ROI_U), 'uint8'); % Create as uint8 for compatibility
    ref_image = poly2mask(contours_out(:,1), contours_out(:,2), size(ROI_U,1), size(ROI_U,2));
    % Optionally, include inner contours
    ref_image = ref_image | poly2mask(contours_in(:,1), contours_in(:,2), size(ROI_U,1), size(ROI_U,2));
    
    % Convert ROI_U_flipped to uint8 for registration
    ROI_U_flipped_uint8 = uint8(flipud(ROI_U));
    
    % Convert ref_image to double for registration
    ref_image_double = double(ref_image);
    
    % Use image registration to find the transformation
    [optimizer, metric] = imregconfig('multimodal');
    tform = imregtform(ROI_U_flipped_uint8, ref_image_double, 'affine', optimizer, metric);
    
    % Define the output image size
    output_image_size = size(ROI_U);
    
    % Apply the transformation to align the flipped mask
    aligned_mask = imwarp(ROI_U_flipped_uint8, tform, 'InterpolationMethod', 'cubic');
    current_size = size(aligned_mask);
    
    % Desired size
    desired_size = [128, 128];
    
    % Calculate the amount of padding needed
    pad_size = desired_size - current_size;
    
    % Calculate padding for each side: top, bottom, left, right
    pad_top = floor(pad_size(1) / 2);  pad_bottom = ceil(pad_size(1) / 2);
    pad_left = floor(pad_size(2) / 2); pad_right = ceil(pad_size(2) / 2);
    
    % Pad the array with zeros to achieve the desired size
    padded_mask = padarray(aligned_mask, [pad_top*(pad_top>0), pad_left*(pad_left>0)], 0, 'pre');
    padded_mask = padarray(padded_mask, [pad_bottom*(pad_bottom>0), pad_right*(pad_right>0)], 0, 'post');
    
    if pad_bottom < 0
        padded_mask(1:abs(pad_bottom),:) = [];
        padded_mask(end:end-abs(pad_bottom),:) = [];
    end
    if pad_right < 0
        padded_mask(:,1:abs(pad_bottom))=[];
        padded_mask(:,end:end-abs(pad_bottom))=[];
    end
    
    % Convert aligned_mask back to logical if needed
    aligned_mask = logical(padded_mask);
    
    %% 6. Non-rigid transformation
    
    % Create grid
    [X, Y] = meshgrid(1:128, 1:128);
    
    % Determine points inside the polygons
    in_outer = inpolygon(X, Y, x_out_aligned, y_out_aligned);
    in_inner = inpolygon(X, Y, x_in_aligned, y_in_aligned);
    
    % Create binary matrix
    binary_matrix = zeros(128, 128);
    binary_matrix(in_outer & ~in_inner) = 1;
    
    [D,trans_mask] = imregdemons(aligned_mask,binary_matrix,[500 400 200],'AccumulatedFieldSmoothing',0.5);
    % Visualize result
    if all_visualizations
        figure
        tiledlayout(1,3,'TileSpacing','compact','Padding','compact')
        set(gcf,"Position",[500,500,600,200])
        nexttile
        imshow(aligned_mask);
        title('MRI');
        nexttile
        imshow(binary_matrix);
        title('Ansys');
        
        % Estimate the transformation needed to bring the two images into alignment.
               
        nexttile
        imshow(trans_mask);
        title('Transformed');
        drawnow;
    end

    %% 7. Send back to original space 
    X_ansys = (X-translation_x)/scale_x;
    Y_ansys = (Y-translation_y)/scale_y;
    
    % Calculate the area of the outer boundary
    area_outer = polyarea(x_out, y_out);
    
    % Calculate the area of the inner boundary
    area_inner = polyarea(x_in, y_in);
    
    % Calculate the area of the annular region
    A = area_outer - area_inner;
    
    u=cell(1,Nt);
    Q=zeros(1,Nt);
    Q_MRI=dat_PC.Q_SAS; % Change sign to Q
    for n=1:Nt
        V_2 = imwarp(flipud(u_MRI(:,:,n)),D);
        u{n} = interp2(X_ansys, Y_ansys, V_2, x_bottom, y_bottom, 'linear');
        uaux=u{n};
        Q(n)=mean(uaux(:))*A*1e4; %[ml/s]
    end
        scale=max(abs(Q_MRI{loc}(:)))/max(abs(Q(:)));
        Q=Q*scale;
        A_MRI=dat_PC.area_SAS{loc}; %[mm^2]
        
     for n=1:Nt
        u{n}=u{n}*scale;
     end   

     %% 8. Create animation and save data
     create_animation(subject,u_MRI,-Q_MRI{loc},A_MRI,u,Q,A,t,x_bottom,y_bottom,cas,loc)
    % Assign x_bottom to x and y_bottom to y
    x = x_bottom;
    y = y_bottom;
    
    % Save the variables, including x and y instead of x_bottom and y_bottom
    save("data/"+subject+"/inlet_velocity.mat", 'u', 'Q', 'x', 'y', 't', 'A','-append');

    disp('4. Transformed PC-MRI measurements into ANSYS inlet velocity profile...')

end        





