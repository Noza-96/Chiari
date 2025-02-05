function create_mesh_journal(cas, DNS)
    fileID = fopen(DNS.TUI_path+"/create_mesh.jou", 'w');

    filename = DNS.ansys_path+"/"+cas.subj+"/"+cas.subj+"_files/dp0/Geom/DM/Geom.scdoc";
    fprintf(fileID,'/file/set-tui-version "24.1"\n' );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Arguments.set_state({r'FileName': r'"+strrep(filename, '/', '\\')+"',r'ImportCadPreferences': {r'MaxFacetLength': 0,},r'LengthUnit': r'm',})"") \n");
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Import Geometry'].Execute()"")\n" );
    fprintf(fileID,"(newline)\n");
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].Arguments.set_state({r'AddChild': r'yes',r'BOICellsPerGap': 1,r'BOIControlName': r'wall_sizing',r'BOICurvatureNormalAngle': 18,r'BOIExecution': r'Face Size',r'BOIFaceLabelList': [r'cord', r'dura', r'tonsils'],r'BOIGrowthRate': 1.1,r'BOISize': "+DNS.mesh_size+",r'BOIZoneorLabel': r'label',})"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Local Sizing'].AddChildAndUpdate(DeferUpdate=False)"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].Arguments.set_state({r'CFDSurfaceMeshControls': {r'MaxSize': "+4*DNS.mesh_size+",r'MinSize': "+DNS.mesh_size+",},})"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].Execute()"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Arguments.set_state(None)"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=False)"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Surface Mesh'].InsertNextTask(CommandName=r'ImproveSurfaceMesh')"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Surface Mesh'].Arguments.set_state({r'FaceQualityLimit': 0.7,r'MeshObject': r'',r'SMImprovePreferences': {r'AdvancedImprove': r'no',r'AllowDefeaturing': r'no',r'SIQualityCollapseLimit': 0.85,r'SIQualityIterations': 5,r'SIQualityMaxAngle': 160,r'SIRemoveStep': r'no',r'SIStepQualityLimit': 0,r'SIStepWidth': 0,r'ShowSMImprovePreferences': False,},r'SQMinSize': 0.001,})"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Surface Mesh'].Execute()"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=False)"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Arguments.set_state({r'NonConformal': r'No',r'SetupType': r'The geometry consists of only fluid regions with no voids',})"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].UpdateChildTasks(SetupTypeChanged=True)"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Describe Geometry'].Execute()"")\n" );
    if contains(DNS.case,"c1")
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Arguments.set_state({r'BoundaryLabelList': [r'top', r'bottom'],r'BoundaryLabelTypeList': [r'pressure-outlet', r'velocity-inlet'],r'OldBoundaryLabelList': [r'top', r'bottom'],r'OldBoundaryLabelTypeList': [r'wall', r'wall'],})"")\n" );
    else
        fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Arguments.set_state({r'BoundaryLabelList': [r'top', r'bottom', r'cord'],r'BoundaryLabelTypeList': [r'velocity-inlet', r'velocity-inlet', r'velocity-inlet'],r'OldBoundaryLabelList': [r'top', r'bottom', r'cord'],r'OldBoundaryLabelTypeList': [r'wall', r'wall', r'wall'],})"")\n" );
    end
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Boundaries'].Execute()"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Regions'].Arguments.set_state({r'OldRegionNameList': [r'patch-body1'],r'OldRegionTypeList': [r'fluid'],r'RegionNameList': [r'fluid'],r'RegionTypeList': [r'fluid'],})"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Update Regions'].Execute()"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Boundary Layers'].Arguments.set_state({r'BLControlName': r'boundary_layers',r'LocalPrismPreferences': {r'Continuous': r'Continuous',},r'Rate': 1.1,})"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Add Boundary Layers'].AddChildAndUpdate(DeferUpdate=False)"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].Arguments.set_state({r'VolumeFill': r'polyhedra',})"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].Execute()"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Generate the Volume Mesh'].InsertNextTask(CommandName=r'ImproveVolumeMesh')"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Volume Mesh'].Arguments.set_state({r'CellQualityLimit': 0.3,r'QualityMethod': r'Orthogonal',r'VMImprovePreferences': {r'ShowVMImprovePreferences': False,r'VIQualityIterations': 5,r'VIQualityMinAngle': 0,r'VIgnoreFeature': r'yes',},})"")\n" );
    fprintf(fileID,"(%%py-exec ""workflow.TaskObject['Improve Volume Mesh'].Execute()"")\n" );
    fprintf(fileID,"(cx-gui-do cx-activate-item ""MenuBar*WriteSubMenu*Stop Journal"")\n" );
    fclose(fileID);
end