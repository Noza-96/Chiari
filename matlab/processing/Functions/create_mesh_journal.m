function all_simulations = create_mesh_journal(cas, DNS_cases)

fileID = fopen(cas.diransys_in+"/create_mesh.jou", 'w');
all_simulations = true; % Initialize flag

local_sizing = {"cord", "dura", "tonsils"}; % to which boundaries apply local sizing

    for ii = 1:length(DNS_cases)
    
        load(fullfile(cas.dirmat, "DNS_" + DNS_cases{ii} + ".mat"), 'DNS');
    
        case_name = DNS.case + "_0";
    
        sstt_sizing = sprintf("r'%s'", strjoin(cellstr(local_sizing), "', r'"));
    
        filename = fullfile(DNS.ansys_path, cas.subj, cas.subj+"_files","dp0","Geom","DM","Geom.scdoc");
    
        if ii == 1
            fprintf(fileID,'/file/set-tui-version "24.1"\n' );
        else
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Revert()"") \n" );
        end
    
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Arguments.set_state({r'FileName': r'"+strrep(strrep(filename, '\', '\\'), '/', '\\')+"',r'ImportCadPreferences': {r'MaxFacetLength': 0,},r'LengthUnit': r'm',})"") \n");
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Execute()"")\n" );
        fprintf(fileID,"(newline)\n");
        if ii == 1
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 1,r'BOIControlName': r'wall_sizing',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Face Size',r'BOIFaceLabelList': ["+sstt_sizing+"],r'BOIGrowthRate': 1.1,r'BOISize': "+DNS.mesh_size+",r'BOIZoneorLabel': r'label',})"")\n" );
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].AddChildAndUpdate(DeferUpdate=False)"")\n" );
        else
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['wall_sizing'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 1,r'BOIControlName': r'wall_sizing',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Face Size',r'BOIFaceLabelList': ["+sstt_sizing+"],r'BOIGrowthRate': 1.1,r'BOISize': "+DNS.mesh_size+",r'BOIZoneorLabel': r'label',r'CompleteFaceLabelList': ["+sstt_sizing+"],r'DrawSizeControl': True,})"")\n" );
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['wall_sizing'].Execute()"")\n" );
        end    
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].Arguments.set_state({r'CFDSurfaceMeshControls': {r'MaxSize': "+4*DNS.mesh_size+",r'MinSize': "+DNS.mesh_size+",},})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].Execute()"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Arguments.set_state(None)"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=False)"")\n" );
        if ii == 1
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].InsertNextTask(CommandName=r'ImproveSurfaceMesh')"")\n" );
        end
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Surface Mesh'].Arguments.set_state({r'FaceQualityLimit': 0.7,r'MeshObject': r'',r'SMImprovePreferences': {r'AdvancedImprove': r'no',r'AllowDefeaturing': r'no',r'SIQualityCollapseLimit': 0.85,r'SIQualityIterations': 5,r'SIQualityMaxAngle': 160,r'SIRemoveStep': r'no',r'SIStepQualityLimit': 0,r'SIStepWidth': 0,r'ShowSMImprovePreferences': False,},r'SQMinSize': 0.001,})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Surface Mesh'].Execute()"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=False)"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Arguments.set_state({r'NonConformal': r'No',r'SetupType': r'The geometry consists of only fluid regions with no voids',})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=True)"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Execute()"")\n" );
        if contains(DNS.case,"c1")
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Arguments.set_state({r'BoundaryLabelList': [r'top', r'bottom'],r'BoundaryLabelTypeList': [r'pressure-outlet', r'velocity-inlet'],r'OldBoundaryLabelList': [r'top', r'bottom'],r'OldBoundaryLabelTypeList': [r'wall', r'wall'],})"")\n" );
        elseif contains(DNS.case,"c2")
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Arguments.set_state({r'BoundaryLabelList': [r'top', r'bottom', r'cord'],r'BoundaryLabelTypeList': [r'velocity-inlet', r'velocity-inlet', r'velocity-inlet'],r'OldBoundaryLabelList': [r'top', r'bottom', r'cord'],r'OldBoundaryLabelTypeList': [r'wall', r'wall', r'wall'],})"")\n" );
        else
            error('Error: case needs to be defined as ''c1'' or ''c2''');
        end
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Execute()"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Regions'].Arguments.set_state({r'OldRegionNameList': [r'patch-body1'],r'OldRegionTypeList': [r'fluid'],r'RegionNameList': [r'fluid'],r'RegionTypeList': [r'fluid'],})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Regions'].Execute()"")\n" );
        if ii ==1
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Boundary Layers'].Arguments.set_state({r'BLControlName': r'boundary_layers',r'LocalPrismPreferences': {r'Continuous': r'Continuous',},r'Rate': 1.1,})"")\n" );
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Boundary Layers'].AddChildAndUpdate(DeferUpdate=False)"")\n" );
        else
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['boundary_layers'].ExecuteUpstreamNonExecutedAndThisTask()"")\n" );
        end   
    
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].Arguments.set_state({r'VolumeFill': r'polyhedra',})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].Execute()"")\n" );
        if ii == 1
            fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].InsertNextTask(CommandName=r'ImproveVolumeMesh')"")\n" );
        end
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Volume Mesh'].Arguments.set_state({r'CellQualityLimit': 0.3,r'QualityMethod': r'Orthogonal',r'VMImprovePreferences': {r'ShowVMImprovePreferences': False,r'VIQualityIterations': 5,r'VIQualityMinAngle': 0,r'VIgnoreFeature': r'yes',},})"")\n" );
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Volume Mesh'].Execute()"")\n" );
        fprintf(fileID,"(cx-gui-do cx-activate-item ""MenuBar*ExportSubMenu*Case..."") \n" );
        filename_2 = fullfile(DNS.ansys_path, cas.subj, "inputs",case_name);
        fprintf(fileID,"(cx-gui-do cx-set-file-dialog-entries ""Select File"" '( """+strrep(strrep(filename_2, '\', '\\'), '/', '\\')+""") ""Legacy Compressed Case Files (*.cas.gz )"") \n\n" );
    
            % Check if the case file exists
        if ~isfile(fullfile(cas.diransys_in, DNS.case + "_0.cas.gz"))
            fprintf(2, 'Case file %s needs to be created.\n', DNS.case);
            all_simulations = false;
        end
        % fprintf(fileID,"(cx-gui-do cx-activate-item ""MenuBar*WriteSubMenu*Stop Journal"")\n" );
    end

    if all_simulations
        fprintf('All fluent cases already exist. Ready to run simulation.');
    end


end