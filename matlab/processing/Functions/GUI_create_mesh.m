function all_simulations = GUI_create_mesh(cas, mesh_size)

    full_ansys_path = correct_path(full_path(fullfile(pwd, '..', '..', '..','computations','ansys')));
    
    GUI_journal_path = fullfile(full_ansys_path, cas.subj, "inputs", "journals", "create_mesh.jou");
    TUI_journal_path = fullfile(full_ansys_path, cas.subj, "inputs", "journals", "TUI_create_mesh.jou");

    % Create TUI journal to call GUI journal 

    fileID = fopen(TUI_journal_path, 'w');

    fprintf(fileID,'/file/set-tui-version "24.1"\n' );
    
    fprintf(fileID,"/file read-journal "+strrep(strrep(GUI_journal_path, '\', '\\'), '/', '\\')+"\n" );

    fclose(fileID);


    fileID = fopen(GUI_journal_path, 'w');
    all_simulations = true; % Initialize flag
    geometry_exist = true;
    count_sim = 1; 
    
    n_cores = 10;
    
    % geom = ["c", "cn"];
    geom = ["c"];
    
    continuity_condition = "tonsils";
    
    prox_limit = [0.0002, 0.0008];
    
    for k = 1: length(geom)
    
        for ii = 1:length(mesh_size)
    
            case_name = geom(k) + "_dx" + mesh_size(ii);
            % check if case already exists or needs to be created
            if isfile(fullfile(cas.diransys_in, "case-files", case_name + ".cas.gz"))
                fprintf('case file %s already exists ...\n', case_name);
            else
                all_simulations = false;
                fprintf('case file %s needs to be created ...\n', case_name);
                    
                % Define to which boundaries apply local sizing
                if contains(geom(k), 'n')
                    local_sizing = {"cord", "dura", "tonsils", "nerve_roots"};
                else
                    local_sizing = {"cord", "dura", "tonsils"};
                end
            
                sstt_sizing = sprintf("r'%s'", strjoin(cellstr(local_sizing), "', r'"));
            
                geometry_path = fullfile(full_ansys_path, cas.subj, "geometry", geom(k)+ "_geometry.scdoc");
    
                if ~isfile(geometry_path)
                    geometry_exist = false; % cannot run simulation
                end
            
                if count_sim == 1
                    fprintf(fileID,"(%%py-exec ""workflow.InitializeWorkflow(WorkflowType=r'Watertight Geometry')"")\n" );
                else
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Revert()"") \n" );
                end
        
                % Import geometry
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Arguments.set_state({r'FileName': r'"+strrep(strrep(geometry_path, '\', '\\'), '/', '\\')+"',r'ImportCadPreferences': {r'MaxFacetLength': 0,},r'LengthUnit': r'm',})"") \n");
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Execute()"")\n" );
        
                % Add local sizings
                if count_sim == 1
                    % wall_sizing
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 1,r'BOIControlName': r'wall_sizing',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Face Size',r'BOIFaceLabelList': ["+sstt_sizing+"],r'BOIGrowthRate': 1.1,r'BOISize': "+mesh_size(ii)+",r'BOIZoneorLabel': r'label',})"")\n" );
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].AddChildAndUpdate(DeferUpdate=False)"")\n" );
                    % proximity
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 10,r'BOIControlName': r'proximity',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Proximity',r'BOIFaceLabelList': [r'cord', r'dura'],r'BOIGrowthRate': 1.1,r'BOIMaxSize': "+prox_limit(2)+",r'BOIMinSize': "+prox_limit(1)+",r'BOIZoneorLabel': r'label',})"")\n" );
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].AddChildAndUpdate(DeferUpdate=False)"")    \n" );
                else
                    % wall_sizing
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['wall_sizing'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 1,r'BOIControlName': r'wall_sizing',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Face Size',r'BOIFaceLabelList': ["+sstt_sizing+"],r'BOIGrowthRate': 1.1,r'BOISize': "+mesh_size(ii)+",r'BOIZoneorLabel': r'label',r'CompleteFaceLabelList': ["+sstt_sizing+"],r'DrawSizeControl': True,})"")\n" );
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['wall_sizing'].Execute()"")\n" );
                    % proximity
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['proximity'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 10,r'BOIControlName': r'proximity',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Proximity',r'BOIFaceLabelList': [r'cord', r'dura'],r'BOIGrowthRate': 1.1,r'BOIMaxSize': "+prox_limit(2)+",r'BOIMinSize': "+prox_limit(1)+",r'BOIZoneorLabel': r'label',})"")\n" );
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['proximity'].Execute()"")\n" );
                end    
                % Generate surface mesh
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].Arguments.set_state({r'CFDSurfaceMeshControls': {r'MaxSize': "+4*mesh_size(ii)+",r'MinSize': "+mesh_size(ii)+",},})"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].Execute()"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Arguments.set_state(None)"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=False)"")\n" );
                
                % Improve surface mesh
                if count_sim == 1
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].InsertNextTask(CommandName=r'ImproveSurfaceMesh')"")\n" );
                end
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Surface Mesh'].Arguments.set_state({r'FaceQualityLimit': 0.7,r'MeshObject': r'',r'SMImprovePreferences': {r'AdvancedImprove': r'no',r'AllowDefeaturing': r'no',r'SIQualityCollapseLimit': 0.85,r'SIQualityIterations': 5,r'SIQualityMaxAngle': 160,r'SIRemoveStep': r'no',r'SIStepQualityLimit': 0,r'SIStepWidth': 0,r'ShowSMImprovePreferences': False,},r'SQMinSize': 0.001,})"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Surface Mesh'].Execute()"")\n" );
                
                %---------- PAUSE JOURNAL   

                fprintf(fileID,"(%%py-exec ""input('Journal paused - check quality surface mesh and press Enter to continue...')"")\n" );

                % Describe fluid regions
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=False)"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Arguments.set_state({r'NonConformal': r'No',r'SetupType': r'The geometry consists of only fluid regions with no voids',})"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=True)"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Execute()"")\n" );
                
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Arguments.set_state({r'BoundaryLabelList': [r'top', r'bottom', r'" + continuity_condition + "'],r'BoundaryLabelTypeList': [r'velocity-inlet', r'velocity-inlet', r'velocity-inlet'],r'OldBoundaryLabelList': [r'top', r'bottom', r'" + continuity_condition + "'],r'OldBoundaryLabelTypeList': [r'wall', r'wall', r'wall'],})"")\n" );
                
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Execute()"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Regions'].Execute()"")\n" );
                
               % Add inflation layers
                if count_sim == 1    
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Boundary Layers'].Arguments.set_state({r'BLControlName': r'boundary_layers',r'LocalPrismPreferences': {r'Continuous': r'Continuous',},r'Rate': 1.1,})"")\n" );
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Boundary Layers'].AddChildAndUpdate(DeferUpdate=False)"")\n" );
                else
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['boundary_layers'].ExecuteUpstreamNonExecutedAndThisTask()"")\n" );
                end   
            
                % Generate volume mesh
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].Arguments.set_state({r'VolumeFill': r'polyhedra',})"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].Execute()"")\n" );
                
                % Improve volume mesh
                if count_sim == 1
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].InsertNextTask(CommandName=r'ImproveVolumeMesh')"")\n" );
                end
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Volume Mesh'].Arguments.set_state({r'CellQualityLimit': 0.3,r'QualityMethod': r'Orthogonal',r'VMImprovePreferences': {r'ShowVMImprovePreferences': False,r'VIQualityIterations': 5,r'VIQualityMinAngle': 0,r'VIgnoreFeature': r'yes',},})"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Volume Mesh'].Execute()"")\n" );
                
                %---------- PAUSE JOURNAL   

                fprintf(fileID,"(%%py-exec ""input('Journal paused - check quality volume mesh and press Enter to continue...')"")\n" );

                filename_2 = fullfile(full_ansys_path, cas.subj, "inputs", "case-files", case_name);
                % export case file 
                fprintf(fileID,"(cx-gui-do cx-activate-item ""MenuBar*WriteSubMenu*Case..."") \n" );     
                fprintf(fileID,"(cx-gui-do cx-set-file-dialog-entries ""Select File"" '( """+strrep(strrep(filename_2, '\', '\\'), '/', '\\')+""") ""Legacy Compressed Case Files (*.cas.gz )"") \n\n" );
            
                fprintf(fileID,"(cx-gui-do cx-activate-item ""Information*OK"") \n");    
                count_sim = count_sim + 1;
            end  
        end
    end

    fclose(fileID);

    % run ansys meshing to run simulations
    if all_simulations
        fprintf('all fluent cases already exist. Ready to run simulation!\n');
    elseif geometry_exist
        visualize_console = 1;
        fluent_command = get_fluent_command(); 
        fprintf('opening Fluent meshing to create simulation using GUI journal\n');
        fluent_cmd = fluent_command + " 3ddp -meshing -t" + n_cores + "-i """ + TUI_journal_path + """";
        if visualize_console == 0
            fluent_cmd = fluent_cmd + " > nul";
        end
        system(fluent_cmd); % Run with "> nul" to suppress terminal output
    else
        fprintf(2, '.scdoc geometry files need to be created!\n');
    end

end

function filepath = correct_path(filepath)
    filepath = strrep(filepath, '\', '/');
end