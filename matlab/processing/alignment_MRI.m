function alignment_MRI(cas)
% RUN_SEGMENTATION(subject)
% - Finds the anatomy DICOM folder under patient-data/<subject>/anatomy
% - Converts DICOMs to NIfTI (if needed)
% - Runs SCT auto-segmentation (if needed)
% - Launches Slicer3D post-processing
%
% Assumes organize_flow_anatomy(subject) (or equivalent) already created
% patient-data/<subject>/anatomy/<series_desc> with DICOMs inside.

    fprintf('\n3) Alignment velocity measurements to segmentation...\n')

    % ---------------- Paths & constants ----------------

    if isfolder(cas.dir.trans) && numel(dir(cas.dir.trans)) > 2
        if askYN('- Transformations already exist. Skip? ([y]/n): ')
            return;
        end
    end
    
    disp("- Running Slicer3D...")
    
    % ---------------- Slicer3D ----------------
    python_script = fullfile(cas.dir.git, 'slicer3D-code','alignment-MRI.py');

    run_slicer_python(cas, python_script)
end