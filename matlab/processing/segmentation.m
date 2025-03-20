% Perform automated segmentation
clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s101_b";


dir_chiari = full_path(fullfile(pwd, '..', '..', '..'));
dicom_path = full_path(fullfile(dir_chiari,'patient-data',subject, 'anatomy'));
files = dir(dicom_path);

% Get only the folder names (excluding '.' and '..')
folder_names = {files([files.isdir] & ~ismember({files.name}, {'.', '..'})).name}';

if numel(folder_names) > 1
    % Ask the user to choose a folder
    fprintf('Multiple folders found:\n');
    for i = 1:numel(folder_names)
        fprintf('%d: %s\n', i, folder_names{i});
    end
    choice = input('Enter the number corresponding to the desired folder to build segmentation: ');
    
    % Validate the choice
    while choice < 1 || choice > numel(folder_names) || isnan(choice)
        choice = input('Invalid choice. Please enter a valid number: ');
    end

    anatomy_dicom = folder_names{choice};
else
    anatomy_dicom = folder_names{1}; % Only one folder, no need to ask
end

% Construct the new DICOM path with the selected folder
dicom_path = fullfile(dicom_path, anatomy_dicom);
disp(['Segmentation DICOMS: ', anatomy_dicom]);

segmentation_path = full_path(fullfile(dir_chiari, 'computations','segmentation',subject));

createDirIfNotExists(segmentation_path);

%% Convert DICOMS to  NIfTI 
nii_file = fullfile(segmentation_path, anatomy_dicom + ".nii.gz");

% Check if the file exists
if ~isfile(nii_file)
    % Run conversion if the file does not exist
    status = system("dcm2niix -o " + segmentation_path + " -f " + anatomy_dicom + " -z y " + dicom_path);

    % Check if conversion was successful
    if status == 0
        disp("Conversion DICOM to NIfTI has been done successfully.");
    else
        disp("Error: Conversion failed.");
    end
else
    disp("NIfTI file already exists. Skipping conversion.");
end

%% Automated segmentation

% Check if the file exists
if ~isfile(fullfile(segmentation_path, anatomy_dicom + "_seg.nii.gz"))

    % segmentation spinal cord
    system( "sct_deepseg -task seg_sc_contrast_agnostic -i " + nii_file);
    
    % segmentation canal
    system( "sct_deepseg -task canal_t2w -i " + nii_file);

    % segmentation rootlets
    system( "sct_deepseg -task seg_spinal_rootlets_t2w -i " + nii_file) 
else
    disp("Segmentation already exists. Skipping automated segmentation.");
end   

python_script = full_path(fullfile(pwd, '..', '..', 'slicer3D-code','initialization-slicer3D.py'));

system ("slicer3D  --python-script """ + python_script + """ """ + subject + """ """ + anatomy_dicom + """ """ + dir_chiari + """");


function createDirIfNotExists(dirPath)
    if ~isfolder(dirPath)
        mkdir(dirPath);
    end
end

function absolutePath = full_path(folder_path)
    absolutePath = char(java.io.File(folder_path).getCanonicalPath());
end