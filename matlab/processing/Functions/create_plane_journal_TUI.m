%Create-planes journal
function create_plane_journal_TUI(dat_PC, cas)

    N = dat_PC.Ndat;
    fileID = fopen(cas.diransys_in+"/create_planes_TUI.jou", 'w');

    ansys_dir = "C:/Users/guill/Documents/chiari/computations/ansys";
    
    fprintf(fileID,'/file/set-tui-version "24.1"\n' );

    low_FM = "FM-25";
    
    for loc = 1:N
        XYZ = three_point_plane(dat_PC, loc);
        create_plane (fileID,XYZ,cas.locations{loc})

        if loc == 1
            XYZ(:,3) = XYZ(:,3) - 0.025; % create plane 25mm lower FM
            create_plane (fileID,XYZ,low_FM)
        end

    end
    locations = [cas.locations, low_FM, "bottom", "(top)"];
    filename = "report";
    directory = ansys_dir+"/"+cas.subj+"/outputs/"+filename;
    fields = {'pressure', 'x-velocity', 'y-velocity', 'z-velocity'}; 

    save_every_time_step_TUI (fileID, fields, locations, directory, filename)
    % save_vel_journal (fileID, cas)

    % fprintf(fileID,'(cx-gui-do cx-activate-item "MenuBar*WriteSubMenu*Stop Journal")\n');
end


function create_plane (fileID, XYZ, sstt)
    xyz_sstt = {'X','Y','Z'};
    fprintf(fileID,"/surface/plane-surface "+sstt+" three-points ");
    % Loop through the points (1 to 3) and print their XYZ coordinates
    for point = 1:3
        % Print each coordinate, multiplied by 1e3 (in one line)
        fprintf(fileID, '%f %f %f ', XYZ(point, 1) * 1e3, XYZ(point, 2) * 1e3, XYZ(point, 3) * 1e3);
    end
    fprintf(fileID,"no\n");
end

function XYZ = three_point_plane(dat_PC, index)

    xyz = dat_PC.pixel_coord{index}*1e-3; %m
    
    %xyz coordinates
    x = reshape(xyz(:,:,1),[],1);
    y = reshape(xyz(:,:,2),[],1);
    z = reshape(xyz(:,:,3),[],1);
    
    % coordinates to define the plane
    x_coords = transpose([x(1), x(floor(end/2)), x(end)]);
    y_coords = transpose([y(1), y(floor(end/2)), y(end)]);
    z_coords = transpose([z(1), z(floor(end/2)), z(end)]);

    XYZ = [x_coords,y_coords,z_coords];

end

function save_every_time_step_TUI (fileID, fields, locations, directory, filename)
    % SETUP
    frequency = 1;
    comma = 'no'; % Delimiter/Comma?
    Cell_centered = 'no'; % Location/Cell-Centered?
    export_every = 'time-step'; % Export data every: ("time-step" "flow-time")
    
    % Join fields and locations into a single string
    fields_str = strjoin(fields, ' '); % Concatenate fields with space delimiter
    locations_str = strjoin(locations, ' '); % Concatenate locations with space delimiter
    
    % Build the string using sprintf
    TUI_sstt = sprintf('/file/transient-export/ascii "%s" %s %s q %s %s %s "%s" %d time-step \n', ...
    directory, locations_str, fields_str, Cell_centered, comma, filename, export_every, frequency);

    fprintf(fileID,TUI_sstt);
end