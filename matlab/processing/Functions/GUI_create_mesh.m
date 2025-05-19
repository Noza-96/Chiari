function all_simulations = GUI_create_mesh(cas, dat_PC, DNS_cases)

fileID = fopen(fullfile(cas.diransys_in, "journals", "create_mesh.jou"), 'w');
all_simulations = true; % Initialize flag

prox_limit = [0.0002, 0.0008];

    for ii = 1:length(DNS_cases)
    
        load(fullfile(cas.dirmat, "DNS_" + DNS_cases{ii} + ".mat"), 'DNS');
    
        % Define to which boundaries apply local sizing
        if contains(DNS.geom, 'n')
            local_sizing = {"cord", "dura", "tonsils", "nerve_roots"};
        else
            local_sizing = {"cord", "dura", "tonsils"};
        end

        % TODO: delete after debug 
        % TUI_setup_Fluent_case(DNS, cas)
        % TUI_reports_journal(cas, DNS)
        % TUI_run_simulation(dat_PC, cas, DNS)
        % TUI_create_surfaces_journal(dat_PC, cas, DNS)
    
        case_name = DNS.case;
    
        sstt_sizing = sprintf("r'%s'", strjoin(cellstr(local_sizing), "', r'"));
    
        filename = fullfile(DNS.ansys_path, cas.subj, "geometry", DNS.geom + "_geometry.scdoc");
    
        if ii == 1
            fprintf(fileID,"(%%py-exec ""workflow.InitializeWorkflow(WorkflowType=r'Watertight Geometry')"")\n" );
        else
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Revert()"") \n" );
        end

        % Import geometry
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Arguments.set_state({r'FileName': r'"+strrep(strrep(filename, '\', '\\'), '/', '\\')+"',r'ImportCadPreferences': {r'MaxFacetLength': 0,},r'LengthUnit': r'm',})"") \n");
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Execute()"")\n" );

        % Add local sizings
        if ii == 1
            % wall_sizing
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 1,r'BOIControlName': r'wall_sizing',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Face Size',r'BOIFaceLabelList': ["+sstt_sizing+"],r'BOIGrowthRate': 1.1,r'BOISize': "+DNS.mesh_size+",r'BOIZoneorLabel': r'label',})"")\n" );
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].AddChildAndUpdate(DeferUpdate=False)"")\n" );
            % proximity
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 10,r'BOIControlName': r'proximity',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Proximity',r'BOIFaceLabelList': [r'cord', r'dura'],r'BOIGrowthRate': 1.1,r'BOIMaxSize': "+prox_limit(2)+",r'BOIMinSize': "+prox_limit(1)+",r'BOIZoneorLabel': r'label',})"")\n" );
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].AddChildAndUpdate(DeferUpdate=False)"")    \n" );
        else
            % wall_sizing
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['wall_sizing'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 1,r'BOIControlName': r'wall_sizing',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Face Size',r'BOIFaceLabelList': ["+sstt_sizing+"],r'BOIGrowthRate': 1.1,r'BOISize': "+DNS.mesh_size+",r'BOIZoneorLabel': r'label',r'CompleteFaceLabelList': ["+sstt_sizing+"],r'DrawSizeControl': True,})"")\n" );
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['wall_sizing'].Execute()"")\n" );
            % proximity
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['proximity'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 10,r'BOIControlName': r'proximity',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Proximity',r'BOIFaceLabelList': [r'cord', r'dura'],r'BOIGrowthRate': 1.1,r'BOIMaxSize': "+prox_limit(2)+",r'BOIMinSize': "+prox_limit(1)+",r'BOIZoneorLabel': r'label',})"")\n" );
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['proximity'].Execute()"")\n" );
        end    
        % Generate surface mesh
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].Arguments.set_state({r'CFDSurfaceMeshControls': {r'MaxSize': "+4*DNS.mesh_size+",r'MinSize': "+DNS.mesh_size+",},})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].Execute()"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Arguments.set_state(None)"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=False)"")\n" );
        
        % Improve surface mesh
        if ii == 1
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].InsertNextTask(CommandName=r'ImproveSurfaceMesh')"")\n" );
        end
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Surface Mesh'].Arguments.set_state({r'FaceQualityLimit': 0.7,r'MeshObject': r'',r'SMImprovePreferences': {r'AdvancedImprove': r'no',r'AllowDefeaturing': r'no',r'SIQualityCollapseLimit': 0.85,r'SIQualityIterations': 5,r'SIQualityMaxAngle': 160,r'SIRemoveStep': r'no',r'SIStepQualityLimit': 0,r'SIStepWidth': 0,r'ShowSMImprovePreferences': False,},r'SQMinSize': 0.001,})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Surface Mesh'].Execute()"")\n" );
        
        % Describe fluid regions
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=False)"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Arguments.set_state({r'NonConformal': r'No',r'SetupType': r'The geometry consists of only fluid regions with no voids',})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=True)"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Execute()"")\n" );
        
        % 1: constant pressure top and inlet velocity bottom
        if ismember(DNS.sim, [0, 1])
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Arguments.set_state({r'BoundaryLabelList': [r'top', r'bottom'],r'BoundaryLabelTypeList': [r'pressure-outlet', r'velocity-inlet'],r'OldBoundaryLabelList': [r'top', r'bottom'],r'OldBoundaryLabelTypeList': [r'wall', r'wall'],})"")\n" );
        
        % 2: inlet velocity bottom, top, continuity_boundary
        elseif DNS.sim == 2
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Arguments.set_state({r'BoundaryLabelList': [r'top', r'bottom', r'" + DNS.continuity + "'],r'BoundaryLabelTypeList': [r'velocity-inlet', r'velocity-inlet', r'velocity-inlet'],r'OldBoundaryLabelList': [r'top', r'bottom', r'" + DNS.continuity + "'],r'OldBoundaryLabelTypeList': [r'wall', r'wall', r'wall'],})"")\n" );
        
        else
            error('Error: case needs to be defined as ''0'', ''1'' or ''2''');
        end
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Execute()"")\n" );
        
       % Add inflation layers
        if ii == 1    
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Boundary Layers'].Arguments.set_state({r'BLControlName': r'boundary_layers',r'LocalPrismPreferences': {r'Continuous': r'Continuous',},r'Rate': 1.1,})"")\n" );
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Boundary Layers'].AddChildAndUpdate(DeferUpdate=False)"")\n" );
        else
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['boundary_layers'].ExecuteUpstreamNonExecutedAndThisTask()"")\n" );
        end   
    
        % Generate volume mesh
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].Arguments.set_state({r'VolumeFill': r'polyhedra',})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].Execute()"")\n" );
        
        % Improve volume mesh
        if ii == 1
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].InsertNextTask(CommandName=r'ImproveVolumeMesh')"")\n" );
        end
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Volume Mesh'].Arguments.set_state({r'CellQualityLimit': 0.3,r'QualityMethod': r'Orthogonal',r'VMImprovePreferences': {r'ShowVMImprovePreferences': False,r'VIQualityIterations': 5,r'VIQualityMinAngle': 0,r'VIgnoreFeature': r'yes',},})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Volume Mesh'].Execute()"")\n" );
        
        filename_2 = fullfile(DNS.ansys_path, cas.subj, "inputs", "case-files", case_name);
        % export case file 
        fprintf(fileID,"(cx-gui-do cx-activate-item ""MenuBar*ExportSubMenu*Case..."") \n" );     
        fprintf(fileID,"(cx-gui-do cx-set-file-dialog-entries ""Select File"" '( """+strrep(strrep(filename_2, '\', '\\'), '/', '\\')+""") ""Legacy Compressed Case Files (*.cas.gz )"") \n\n" );
    
        fprintf(fileID,"(cx-gui-do cx-activate-item ""Information*OK"") \n");

        % Check if the case file exists
        if ~isfile(fullfile(cas.diransys_in, "case-files", DNS.case + ".cas.gz"))
            fprintf('case file %s needs to be created ...\n', DNS.case);
            all_simulations = false;
        end
    end

    if all_simulations
        fprintf('all fluent cases already exist. Ready to run simulation!\n');
    end
end

