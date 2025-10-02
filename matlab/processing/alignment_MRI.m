function alignment_MRI(subject)
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
    dir_chiari        = full_path(fullfile(pwd,'..', '..'));
    segmentation_path = full_path(fullfile(dir_chiari, 'computations','segmentation',subject));
    transformation_path = fullfile(segmentation_path,'transformation');

    if isfolder(transformation_path) && numel(dir(transformation_path)) > 2
        if askYN('-Transformations already exist. Skip? ([y]/n): ')
            return;
        end
    end

    createDirIfNotExists(segmentation_path);
    
    disp("-Running Slicer3D...")
    % ---------------- Slicer3D post-processing ----------------
    python_script = full_path(fullfile(dir_chiari,'git-chiari', 'slicer3D-code','alignment-MRI.py'));
    system("slicer3D  --python-script """ + python_script + """ """ + subject + """ """ + dir_chiari + """");

end

% ---------------- helpers (local) ----------------
function createDirIfNotExists(dirPath)
    if ~isfolder(dirPath), mkdir(dirPath); end
end

function absolutePath = full_path(folder_path)
    absolutePath = char(java.io.File(folder_path).getCanonicalPath());
end

function v = askInt(prompt, lo, hi)
    v = input(prompt);
    while ~(isscalar(v) && isnumeric(v) && isfinite(v) && v==floor(v) && v>=lo && v<=hi)
        v = input(sprintf('Enter an integer in [%d, %d]: ', lo, hi));
    end
end
