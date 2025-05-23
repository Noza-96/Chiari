%Create-planes journal
function TUI_create_surfaces_journal(dat_PC, cas, DNS, fileID)

    if nargin < 4
        fileID = fopen(fullfile(DNS.TUI_path,"create_surfaces_journal_TUI.jou"), 'w');
        fprintf(fileID,'/file/set-tui-version "24.1"\n' );
    end

    % data with anatomical positions
    load(fullfile(cas.dirmat,"anatomical_locations.mat"), 'anatomy');

    fprintf(fileID,';create surfaces\n' );

    N = dat_PC.Ndat;
    
    % Create slices of PC measurements
    for loc = 2:N-1 %TODO: skip top and bottom locations
        XYZ = three_point_plane(dat_PC, loc);
        create_plane (fileID,XYZ,cas.locations{loc})
    end

    % create planes perpendicular to z-dir at 5 mm separation FM  till 50 mm below    
    for Dz = 5:5:50
        % Dz foramen with respect to top pcmri location
        Dz_foramen = (anatomy.FM-Dz)/1000; % [m]

         % create plane at the location of the foramen_magnum
        XYZ(:,3) = Dz_foramen;
        create_plane (fileID,XYZ,"FM-"+Dz)
    end

    % Create surface to export later
    zone_names = {'cord', 'dura', 'tonsils'};
    for k = 1:length(zone_names)
        fprintf(fileID,sprintf('/surface/zone-surface %s_s "%s" q \n', zone_names{k}, zone_names{k}));
    end
    fprintf(fileID,sprintf('/surface/group-surfaces %s () wall  q \n', strjoin(append(zone_names,'_s'),' ')));

    if nargin < 4
        fclose(fileID);
    end
end


function create_plane (fileID, XYZ, sstt)
    fprintf(fileID,"/surface/plane-surface "+sstt+" three-points ");
    % Loop through the points (1 to 3) and print their XYZ coordinates
    for point = 1:3
        % Print each coordinate  
        fprintf(fileID, '%f %f %f ', XYZ(point, 1), XYZ(point, 2), XYZ(point, 3)); % [m]
    end
    fprintf(fileID,"no\n");
end

function XYZ = three_point_plane(dat_PC, index)

    xyz = dat_PC.pixel_coord{index}*1e-3; %m
    
    % xyz coordinates
    x = reshape(xyz(:,:,1),[],1);
    y = reshape(xyz(:,:,2),[],1);
    z = reshape(xyz(:,:,3),[],1);
    
    % coordinates to define the plane
    x_coords = transpose([x(1), x(floor(end/2)), x(end)]);
    y_coords = transpose([y(1), y(floor(end/2)), y(end)]);
    z_coords = transpose([z(1), z(floor(end/2)), z(end)]);

    XYZ = [x_coords,y_coords,z_coords];

end