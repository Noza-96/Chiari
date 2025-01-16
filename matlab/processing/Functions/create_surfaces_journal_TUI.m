%Create-planes journal
function create_surfaces_journal_TUI(dat_PC, cas)

    N = dat_PC.Ndat;
    fileID = fopen(cas.diransys_in+"/create_surfaces_journal_TUI.jou", 'w');
    
    fprintf(fileID,'/file/set-tui-version "24.1"\n' );
    
    % Create slices of PC measurements
    for loc = 1:(N-1)
        XYZ = three_point_plane(dat_PC, loc);
        create_plane (fileID,XYZ,cas.locations{loc})

        if loc == 1
            XYZ(:,3) = XYZ(:,3) - 0.025; % create plane 25mm lower FM
            create_plane (fileID,XYZ,"FM-25")
        end
    end

    % Create surface to export later
    zone_names = {'cord', 'dura', 'tonsils'};
    for k = 1:length(zone_names)
        fprintf(fileID,sprintf('/surface/zone-surface %s_s "%s" q \n', zone_names{k}, zone_names{k}));
    end
    fprintf(fileID,sprintf('/surface/group-surfaces %s () wall  q \n', strjoin(append(zone_names,'_s'),' ')));

    fclose(fileID);
end


function create_plane (fileID, XYZ, sstt)
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