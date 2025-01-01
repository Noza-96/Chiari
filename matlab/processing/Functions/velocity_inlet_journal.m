%Save velocity field on udms
function velocity_inlet_journal(dat_PC, cas)
    cycles = 3;
    fileID = fopen(cas.diransys_in+"/velocity_inlet_journal.jou", 'w');
    
    fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Solution|Initialization"))\n' );
    fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Solution|Initialization"))\n' );
    fprintf(fileID,'(cx-gui-do cx-activate-item "NavigationPane*Frame2*Table1*List_Tree2")\n' );
    fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Solution|Initialization"))\n' );
    fprintf(fileID,'(cx-gui-do cx-activate-item "Solution Initialization*Table1*Frame9*PushButton1(Initialize)")\n' );
    
    fprintf(fileID,'\n' );
    fprintf(fileID,'\n' );
    fprintf(fileID,'\n' );
    
    
    % fprintf(fileID,'(cx-gui-do cx-activate-item "Question*OK")\n' );
    
    for k=1:cycles
        for n = 1:100   
            fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Setup|Boundary Conditions"))\n');
            fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Setup|Boundary Conditions"))\n');
            fprintf(fileID,'(cx-gui-do cx-activate-item "NavigationPane*Frame2*Table1*List_Tree2")\n');
            fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Setup|Boundary Conditions"))\n');
            fprintf(fileID,'(cx-gui-do cx-activate-item "Boundary Conditions*Table1*Table3*Table4*Table2*ButtonBox1*PushButton2(Profiles)")\n');
            fprintf(fileID,'(cx-gui-do cx-activate-item "Profiles*Table7*Table1*PushButton1(Read)")\n');
            fprintf(fileID,"(cx-gui-do cx-set-file-dialog-entries ""Select File"" '( ""inlet_"+num2str(n)+".csv"") ""Profile Files (*.csv* *.prof* *.ttab* )"")\n");
            fprintf(fileID,'(cx-gui-do cx-activate-item "Profiles*PanelButtons*PushButton1(OK)")\n');
            fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Solution|Run Calculation"))\n');
            fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Solution|Run Calculation"))\n');
            fprintf(fileID,'(cx-gui-do cx-activate-item "NavigationPane*Frame2*Table1*List_Tree2")\n');
            fprintf(fileID,'(cx-gui-do cx-set-list-tree-selections "NavigationPane*Frame2*Table1*List_Tree2" (list "Solution|Run Calculation"))\n');
            fprintf(fileID,'(cx-gui-do cx-activate-item "Run Calculation*Table1*Table9(Solution Advancement)*Table1*PushButton1(Calculate)")\n');
            if n==1
                % fprintf(fileID,'(cx-gui-do cx-activate-item "Question*OK")\n');
            else
                fprintf(fileID,'(cx-gui-do cx-activate-item "Settings have changed!*PanelButtons*PushButton1(OK)")\n' );
            end
            fprintf(fileID,'(cx-gui-do cx-activate-item "Information*OK")\n');
        end
    end
        fprintf(fileID,'(cx-gui-do cx-activate-item "MenuBar*WriteSubMenu*Stop Journal")\n' );
            
        %Generate .csv files with profile information to input in Ansys
        profiles_inlet (subject, 0)

        disp('5. Generated journal for variable velocity profile together with .csv files...')
end