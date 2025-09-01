% Perform automated segmentation
clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s3";

dir_chiari = full_path(fullfile(pwd, '..', '..', '..'));
dicom_path = full_path(fullfile(dir_chiari,'patient-data',subject));


% --- List series and pick a T2 one (no renaming) ---
% Get table of series (one row per SE folder)
T = list_dicom_series(dicom_path);   % returns table with PAT, ST, SE, SeriesDescription, etc.

% Keep only series whose description contains 'T2' as a word (case-insensitive)
isT2 = ~cellfun(@isempty, regexpi(T.SeriesDescription, 'T2', 'once'));
T2T  = T(isT2, :);

if isempty(T2T)
    error('No series with "T2" found under: %s', dicom_path);
end

% Build display strings and candidate paths
choices = strings(height(T2T),1);
paths   = strings(height(T2T),1);
for i = 1:height(T2T)
    choices(i) = sprintf('%s / %s / %s : Ser%03d  %s', ...
        T2T.PAT{i}, T2T.ST{i}, T2T.SE{i}, T2T.SeriesNumber(i), T2T.SeriesDescription{i});
    paths(i)   = fullfile(dicom_path, T2T.PAT{i}, T2T.ST{i}, T2T.SE{i});
end

% If more than one candidate, ask the user
if height(T2T) > 1
    fprintf('\nT2 series found:\n');
    for i = 1:numel(choices)
        fprintf('%2d) %s\n', i, choices(i));
    end
    choice = input('Enter the number of the series to use for segmentation: ');
    while isempty(choice) || ~isfinite(choice) || choice < 1 || choice > numel(choices)
        choice = input('Invalid choice. Enter a valid number: ');
    end
    anatomy_dicom = char(paths(choice));
else
    anatomy_dicom = char(paths(1));
    fprintf('\nOnly one T2 series found. Using:\n   %s\n', choices(1));
end

% Confirm selection
disp(['Segmentation DICOMS (SE folder): ', anatomy_dicom]);

% (Optional) sanity check: ensure the folder exists and contains MR* files
if ~isfolder(anatomy_dicom)
    error('Selected SE folder not found: %s', anatomy_dicom);
end
mrCheck = dir(fullfile(anatomy_dicom, 'MR*'));
if isempty(mrCheck)
    % allow nested layout (rare); look one level deeper
    mrCheck = dir(fullfile(anatomy_dicom, '**', 'MR*'));
    if isempty(mrCheck)
        warning('No MR* files found under selected series: %s', anatomy_dicom);
    end
end

segmentation_path = full_path(fullfile(dir_chiari, 'computations','segmentation',subject));

createDirIfNotExists(segmentation_path);

%% Convert DICOMS to  NIfTI 
nii_file = fullfile(segmentation_path, "segmentation.nii.gz");

sct = '/Users/you/miniforge3/envs/sct/bin/sct_deepseg';

% Check if the file exists
if ~isfile(nii_file)
    % Run conversion if the file does not exist
    status = system("dcm2niix -o " + segmentation_path + " -f " + "segmentation" + " -z y " + anatomy_dicom);

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
if ~isfile(fullfile(segmentation_path, "segmentation_seg.nii.gz"))

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

function T = list_dicom_series(rootDir, csvOut)
% LIST_DICOM_SERIES  Print/return one line per SE0000xx series.
%   T = list_dicom_series(rootDir)
%   T = list_dicom_series(rootDir, 'series_list.csv')
%
% Output columns: PAT, ST, SE, StudyDate, StudyTime, SeriesNumber, SeriesDescription

if nargin < 1 || ~isfolder(rootDir)
    error('Folder not found: %s', string(rootDir));
end
if nargin < 2, csvOut = ''; end

% Find all SE folders under rootDir (e.g., s3/PAT00000/ST000001/SE000009)
seDirs = dir(fullfile(rootDir, '**', 'SE*'));
seDirs = seDirs([seDirs.isdir]);

rows = [];
data = struct('PAT', {}, 'ST', {}, 'SE', {}, 'StudyDate', {}, 'StudyTime', {}, ...
              'SeriesNumber', {}, 'SeriesDescription', {});

for k = 1:numel(seDirs)
    thisSE = fullfile(seDirs(k).folder, seDirs(k).name);
    % Look for one MR* file inside this SE folder
    mr = dir(fullfile(thisSE, 'MR*'));
    mr = mr(~[mr.isdir]);
    if isempty(mr)
        % sometimes files are nested one level deeper; handle it
        mr = dir(fullfile(thisSE, '**', 'MR*'));
        mr = mr(~[mr.isdir]);
    end
    if isempty(mr)
        % no dicoms here
        continue
    end

    sampleFile = fullfile(mr(1).folder, mr(1).name);
    try
        info = dicominfo(sampleFile);
    catch
        % skip unreadable series
        continue
    end

    % Pull fields with safe fallbacks
    StudyDate  = getfield_try(info, 'StudyDate', '00000000');
    StudyTime  = sanitize_time(getfield_try(info, 'StudyTime', '000000'));
    SeriesNum  = getfield_try(info, 'SeriesNumber', 0);
    SeriesDesc = getfield_try(info, 'SeriesDescription', '');
    if isempty(SeriesDesc)
        SeriesDesc = getfield_try(info, 'ProtocolName', '');
    end

    % Extract PAT/ST/SE names from the path for convenience
    parts = split(string(thisSE), filesep);
    % Expect .../PATxxxxx/STxxxxxx/SExxxxxx
    PAT = "";
    ST  = "";
    SE  = string(seDirs(k).name);
    if numel(parts) >= 3
        PAT = parts(end-2);
        ST  = parts(end-1);
    end

    data(end+1) = struct( ... %#ok<AGROW>
        'PAT', char(PAT), ...
        'ST',  char(ST), ...
        'SE',  char(SE), ...
        'StudyDate',  char(StudyDate), ...
        'StudyTime',  char(StudyTime), ...
        'SeriesNumber', double(SeriesNum), ...
        'SeriesDescription', char(SeriesDesc));
end

% Turn into table and sort by PAT, ST, SeriesNumber
if isempty(data)
    T = table();
    fprintf('No series found under %s\n', rootDir);
    return
end
T = struct2table(data);
T = sortrows(T, {'PAT','ST','SeriesNumber'});

% Pretty print like:
% SE000009 : Ser013 WATER_3D_Sag_T2_Cube_FS_CERVICAL
lastPAT = '';
lastST  = '';
for i = 1:height(T)
    if ~strcmp(lastPAT, T.PAT{i}) || ~strcmp(lastST, T.ST{i})
        fprintf('\n%s / %s\n', T.PAT{i}, T.ST{i});
        lastPAT = T.PAT{i}; lastST = T.ST{i};
    end
    fprintf('%s : Ser%03d %s\n', T.SE{i}, T.SeriesNumber(i), T.SeriesDescription{i});
end
fprintf('\nTotal series: %d\n', height(T));

% Optional CSV
if ~isempty(csvOut)
    writetable(T, csvOut);
    fprintf('Wrote %s\n', csvOut);
end
end

% ---- helpers ----
function v = getfield_try(s, fld, defaultVal)
    if isfield(s, fld) && ~isempty(s.(fld))
        v = s.(fld);
    else
        v = defaultVal;
    end
end

function t = sanitize_time(tin)
    t = char(string(tin));
    t = regexprep(t, '\D', '');
    if isempty(t), t = '000000'; end
    if numel(t) >= 6, t = t(1:6); else, t = pad(t, 6, 'right', '0'); end
end