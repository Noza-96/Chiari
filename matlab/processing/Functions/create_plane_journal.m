%Create-planes journal
function create_plane_journal(dat_PC, cas)

    N = dat_PC.Ndat;
    fileID = fopen(cas.diransys_in+"/create_planes_journal.jou", 'w');
    
    fprintf(fileID,'/file/set-tui-version "24.1"\n' );
    fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Results|Surfaces"))\n' );
    fprintf(fileID,'(cx-gui-do cx-list-tree-right-click "NavigationPane*Frame2*Table1*List_Tree2" )\n' );
    fprintf(fileID,'(cx-gui-do cx-activate-item "MenuBar*NewSubMenu*Plane...")' );
    fprintf(fileID,'(cx-gui-do cx-set-list-selections "Plane Surface*Table1*Table2(Method)*DropDownList1" ''( 4))\n' );
    fprintf(fileID,'(cx-gui-do cx-activate-item "Plane Surface*Table1*Table2(Method)*DropDownList1")\n' );
    
    for loc = 1:N
        XYZ = three_point_plane(dat_PC, loc);
        loop_points (fileID,XYZ,cas.locations{loc})

        if loc == 1
            XYZ(:,3) = XYZ(:,3) - 0.025; % create plane 25mm lower FM
            loop_points (fileID,XYZ,"FM-25")
        end
    end
    fprintf(fileID,'(cx-gui-do cx-activate-item "Plane Surface*PanelButtons*PushButton2(Cancel)")\n');

    save_vel_journal (fileID, cas)

    fprintf(fileID,'(cx-gui-do cx-activate-item "MenuBar*WriteSubMenu*Stop Journal")\n');
end


function loop_points (fileID,XYZ, sstt)
    xyz_sstt = {'X','Y','Z'};
    for point = 1:3
        for xyz = 1:3
        fprintf(fileID,"(cx-gui-do cx-set-real-entry-list ""Plane Surface*Table1*Frame4*Table1*Table"+num2str(point)+"(Point "+num2str(point)+")*RealEntry"+num2str(xyz)+"("+xyz_sstt{xyz}+")"" '( "+XYZ(point,xyz)+"))\n" );
        fprintf(fileID,"(cx-gui-do cx-activate-item ""Plane Surface*Table1*Frame4*Table1*Table"+num2str(point)+"(Point "+num2str(point)+")*RealEntry"+num2str(xyz)+"("+xyz_sstt{xyz}+")"")\n" );
        end
    end
    fprintf(fileID,"(cx-gui-do cx-set-text-entry ""Plane Surface*Table1*Table1*TextEntry1(New Surface Name)"" """+sstt+""")\n" );
    fprintf(fileID,'(cx-gui-do cx-activate-item "Plane Surface*PanelButtons*PushButton1(OK)")\n');
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

function save_vel_journal (fileID, cas)

    filename = "C:\\Users\\guill\\Documents\\chiari\\computations\\ansys\\"+cas.subj+"\\output\\surface_velocities/vel";
    
    % fileID = fopen(cas.diransys_in+"/create_planes_journal.jou", 'w');
    
    fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Solution|Calculation Activities"))\n' );
    fprintf(fileID,'(cx-gui-do cx-activate-item "Calculation Activities*ButtonBox4*PushButton1(Create)")\n' );
    fprintf(fileID,'(cx-gui-do cx-activate-item "MenuBar*PopupMenuAutomaticExport*Solution Data Export...")\n' );
    fprintf(fileID,'(cx-gui-do cx-set-list-selections "Automatic Export*Table1*Table2*Table3*List1(Surfaces)" ''( 0 1 2 3 4 6))\n' );
    fprintf(fileID,'(cx-gui-do cx-activate-item "Automatic Export*Table1*Table2*Table3*List1(Surfaces)")\n' );
    fprintf(fileID,'(cx-gui-do cx-set-list-selections "Automatic Export*Table1*Table2*Table4*List1(Quantities)" ''( 0 9 10 11))\n' );
    fprintf(fileID,'(cx-gui-do cx-activate-item "Automatic Export*Table1*Table2*Table4*List1(Quantities)")\n' );
    fprintf(fileID,'(cx-gui-do cx-set-text-entry "Automatic Export*Table1*Table1*TextEntry1(Name)" "surface-vel")\n' );
    fprintf(fileID,'(cx-gui-do cx-set-list-selections "Automatic Export*Table1*Table1*DropDownList2(File Type)" ''( 1))\n' );
    fprintf(fileID,'(cx-gui-do cx-activate-item "Automatic Export*Table1*Table1*DropDownList2(File Type)")\n' );
    fprintf(fileID,"(cx-gui-do cx-set-text-entry ""Automatic Export*Table1*Table2*Table7*Table1*TextEntry1(File Name)"" """+filename+""")\n" );
    % fprintf(fileID,'(cx-gui-do cx-activate-item "Automatic Export*PanelButtons*PushButton1(OK)")\n' );

end