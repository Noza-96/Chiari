function main_9_mesh(cas, case_name, mesh_size, n_cores)

    fprintf("9) Meshing:\n");
    
    % run fluent-meshing to create meshes and corresponding .cas files
    GUI_create_mesh(cas, mesh_size, case_name, n_cores);
    
    % Get cases  with first digit 3
    cases_zones = case_name(cellfun(@(s) ~isempty(regexp(s, '\D*3', 'once')), case_name));
    
    if ~isempty(cases_zones)   
        GUI_create_mesh_zones(cas, mesh_size, cases_zones, n_cores);
    end
end

function GUI_create_mesh(cas, mesh_size, case_name, n_cores)

    all_simulations = true; 
    geometry_exist = true;
    count_sim = 1; 

    full_ansys_path_in = correct_path(full_path(cas.dir.ansys_in));
    
    GUI_journal_path = fullfile(full_ansys_path_in, "journals", "create_mesh.jou");

    fileID = fopen(GUI_journal_path, 'w');

    geom = [];
    version = [];
    
    for k = 1:numel(case_name)
        s = case_name{k};  % current case name, e.g. 'cnl3_dx00004_v1'
    
        % prefix: everything before the first digit
        prefix = regexp(s, '^\D*', 'match', 'once');
    
        % first digit in the string
        firstDigit = regexp(s, '\d', 'match', 'once');
  
        if ~isempty(prefix) && ~isempty(firstDigit) && ~strcmp(firstDigit, '3')
            [gg, ~, ~, vv] = get_type_simulation(case_name{k});
            geom = [geom, string(gg)];
            version = [version, string(vv)];
        end
    end
    % (optional) remove duplicates, keep first occurrence
    geom = unique(geom, 'stable');

    % for type 2 simulation, which boundary has continuity condition
    continuity_condition = "tonsils";  
    
    for k = 1: length(geom)
        for ii = 1:length(mesh_size)
            prox_limit = [mesh_size(ii), mesh_size(ii)*4];
            case_i = geom(k) + "_dx" + mesh_size(ii) + version(k);

            if isfile(fullfile(cas.dir.ansys_in, "case-files", case_i + ".cas.gz"))
                fprintf('- Case file %s already exists... \n', case_i + ".cas.gz");
            else
                all_simulations = false;
                fprintf('- Case file %s needs to be created...\n', case_i + ".cas.gz");
                % Define to which boundaries apply local sizing
                local_sizing = {"cord", "dura", "tonsils"}; 

                if contains(geom(k), 'n')
                    local_sizing{end+1} = "nerve_roots";
                end
                
                if contains(geom(k), 'l')
                    local_sizing{end+1} =  "ligaments";
                end
            
                sstt_sizing = sprintf("r'%s'", strjoin(cellstr(local_sizing), "', r'"));

                geom_name = geom + "_geometry" + version(k) + ".scdoc";
            
                geometry_path = fullfile(full_ansys_path_in, "geometry", geom_name);
    
                if ~isfile(geometry_path)
                    geometry_exist = false; % cannot run simulation
                    fprintf(2, '- Geometry file %s does not exist...\n', geom_name);
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

                filename_2 = fullfile(full_ansys_path_in, "case-files", case_i);
                % export Case file 
                fprintf(fileID,"(cx-gui-do cx-activate-item ""MenuBar*WriteSubMenu*Case..."") \n" );     
                fprintf(fileID,"(cx-gui-do cx-set-file-dialog-entries ""Select File"" '( """+strrep(strrep(filename_2, '\', '\\'), '/', '\\')+""") ""Legacy Compressed Case files (*.cas.gz )"") \n\n" );
            
                fprintf(fileID,"(cx-gui-do cx-activate-item ""Information*OK"") \n");    
                count_sim = count_sim + 1;
            end  
        end
    end
    fprintf(fileID,"exit \n"); 
    fprintf(fileID,"o \n"); 
    fclose(fileID);

    % run ansys meshing to run simulations
    if all_simulations
        fprintf('- All fluent cases exist -> Ready to run CFD simulation! \n\n');
    elseif geometry_exist
        visualize_console = 1;
        fluent_command = get_fluent_command(cas);
        fprintf('- Opening Fluent Meshing to create fluent .cas files...\n');
        fluent_cmd = """" + fluent_command + """" + " 3ddp -meshing -t" + n_cores + " -i """ + GUI_journal_path + """";
        if visualize_console == 0
            fluent_cmd = fluent_cmd + " > nul";
        end
        system(fluent_cmd); 
        a = '';
        while ~strcmpi(a, 'ok')
            a = input('Type "ok" to continue: ', 's');
        end
    end

end

function GUI_create_mesh_zones(cas, mesh_size, cases_zones, n_cores)

    all_simulations = true; 
    geometry_exist = true;
    count_sim = 1; 


    full_ansys_path_in = correct_path(full_path(cas.dir.ansys_in));
    
    GUI_journal_path = fullfile(full_ansys_path_in, "journals", "create_mesh.jou");

    fileID = fopen(GUI_journal_path, 'w');
       
    % continuity condition distributed in cord between slices
    continuity_condition = compose("cord_%d", 1:(cas.Ncas-1));
    
    for k = 1: length(cases_zones)

        [geom, ~, ~, version] = get_type_simulation(cases_zones{k});

    
        for ii = 1:length(mesh_size)
    
            case_name = geom + "_dx" + mesh_size(ii) + "_zones" + version;
            % check if case already exists or needs to be created
            if isfile(fullfile(cas.dir.ansys_in, "case-files", case_name + ".cas.gz"))
                fprintf('Case file %s already exists... \n', case_name + ".cas.gz");
            else
                all_simulations = false;
                fprintf(2, 'Case file %s needs to be created...\n', case_name + ".cas.gz");
                    
                % Define to which boundaries apply local sizing
                local_sizing = [continuity_condition, "dura", "tonsils"];
                if contains(geom, 'n')
                    local_sizing = [local_sizing, "nerve_roots"];
                end
                if contains(geom, 'l')
                    local_sizing = [local_sizing, "ligaments"];
                end
                
                sstt_sizing = sprintf("r'%s'", strjoin(local_sizing, "', r'"));            
                geometry_path = fullfile(full_ansys_path_in, "geometry", geom+ "_geometry_zones"+version+".scdoc");
    
                if ~isfile(geometry_path)
                    geometry_exist = false; % cannot run simulation
                    fprintf(2, 'geometry file %s does not exist...\n', geom+ "_geometry_zones"+version+".scdoc");
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
                else
                    % wall_sizing
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['wall_sizing'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 1,r'BOIControlName': r'wall_sizing',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Face Size',r'BOIFaceLabelList': ["+sstt_sizing+"],r'BOIGrowthRate': 1.1,r'BOISize': "+mesh_size(ii)+",r'BOIZoneorLabel': r'label',r'CompleteFaceLabelList': ["+sstt_sizing+"],r'DrawSizeControl': True,})"")\n" );
                    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['wall_sizing'].Execute()"")\n" );
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

                % Describe fluid regions
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=False)"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Arguments.set_state({r'NonConformal': r'No',r'SetupType': r'The geometry consists of only fluid regions with no voids',})"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=True)"")\n" );
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Execute()"")\n" );
                
                fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Arguments.set_state({r'BoundaryLabelList': [r'top', r'bottom', " + strjoin(compose("r'%s'", continuity_condition),", ") +"]," +...
               " r'BoundaryLabelTypeList': ["+strjoin(repmat("r'velocity-inlet'", 1, 1 + cas.Ncas),", ")+"],r'OldBoundaryLabelList': [r'top', r'bottom', " + strjoin(compose("r'%s'", continuity_condition),", ") +"] ,r'OldBoundaryLabelTypeList': ["+strjoin(repmat("r'wall'", 1, 1 + cas.Ncas),", ")+"],})"")\n" );

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

                filename_2 = fullfile(full_ansys_path_in, "case-files", case_name);
                % export Case file 
                fprintf(fileID,"(cx-gui-do cx-activate-item ""MenuBar*WriteSubMenu*Case..."") \n" );     
                fprintf(fileID,"(cx-gui-do cx-set-file-dialog-entries ""Select File"" '( """+strrep(strrep(filename_2, '\', '\\'), '/', '\\')+""") ""Legacy Compressed Case files (*.cas.gz )"") \n\n" );
            
                fprintf(fileID,"(cx-gui-do cx-activate-item ""Information*OK"") \n");    
                count_sim = count_sim + 1;
            end  
        end
    end
    fprintf(fileID,"exit \n"); 
    fprintf(fileID,"o \n"); 
    fclose(fileID);

    % run ansys meshing to run simulations
    if all_simulations
        fprintf('- All fluent cases with microanatomy exist -> Ready to run CFD simulation! \n\n');
        else
        if geometry_exist
            visualize_console = 1;

            fluent_command = get_fluent_command(cas);

            fluent_cmd = """" + fluent_command + """" + " 3ddp -meshing -t" + n_cores + " -i """ + GUI_journal_path + """";

            if visualize_console == 0
                fluent_cmd = fluent_cmd + " > nul";
            end
            system(fluent_cmd); % Run with "> nul" to suppress terminal output
            a = '';
            while ~strcmpi(a, 'ok')
                a = input('Type "ok" to continue: ', 's');
            end
        end
    end

end







