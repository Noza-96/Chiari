function rename_dicoms(rootDir, dryRun)
% rename_dicom_s3(rootDir, dryRun)
% Renames MR* DICOM files under rootDir using dicom metadata.
% Output pattern:
%   YYYYMMDD_HHMMSS_SerNNN_<SeriesDescription>_Inst00001.dcm
%
% Example:
%   rename_dicom_s3('s3', true);   % preview
%   rename_dicom_s3('s3', false);  % rename

if nargin < 2, dryRun = true; end
rootDir = char(string(rootDir));  % normalize
if ~isfolder(rootDir)
    error('Folder not found: %s', rootDir);
end

mrFiles = dir(fullfile(rootDir, '**', 'MR*'));   % recursive
mrFiles = mrFiles(~[mrFiles.isdir]);             % files only

fprintf('Found %d MR* files under %s\n', numel(mrFiles), rootDir);
if dryRun
    fprintf('--- DRY RUN (no changes will be made) ---\n');
end

renamed = 0; skipped = 0; collided = 0;

for k = 1:numel(mrFiles)
    src = fullfile(mrFiles(k).folder, mrFiles(k).name);
    try
        info = dicominfo(src);
    catch ME
        warning('Skip (bad DICOM): %s (%s)', src, ME.message);
        skipped = skipped + 1;
        continue
    end

    % Pull fields with fallbacks
    StudyDate  = getfield_try(info, 'StudyDate',     '00000000'); % YYYYMMDD
    StudyTime  = getfield_try(info, 'StudyTime',     '000000');   % HHMMSS or HHMMSS.FFFFFF
    StudyTime  = sanitize_time(StudyTime);
    SeriesNum  = getfield_try(info, 'SeriesNumber',  0);
    SeriesDesc = getfield_try(info, 'SeriesDescription', '');
    if isempty(SeriesDesc)
        SeriesDesc = getfield_try(info, 'ProtocolName', '');
    end
    InstanceNo = getfield_try(info, 'InstanceNumber', []);
    if isempty(InstanceNo)
        % Fallback to last 5 digits of SOPInstanceUID if present
        sop = getfield_try(info, 'SOPInstanceUID', '0');
        d = regexp(sop, '(\d{5})$', 'tokens', 'once');
        if ~isempty(d)
            InstanceNo = str2double(d{1});
        else
            InstanceNo = 0;
        end
    end

    % Build new file name
    SeriesDescSafe = slug(SeriesDesc, 80);
    newName = sprintf('%s_%s_Ser%03d_%s_Inst%05d.dcm', ...
        StudyDate, StudyTime, fixnum(SeriesNum), SeriesDescSafe, fixnum(InstanceNo));
    dst = fullfile(mrFiles(k).folder, newName);

    % Ensure uniqueness: if exists, append counter
    counter = 1;
    dstTry = dst;
    while exist(dstTry, 'file')
        [p,f,e] = fileparts(dst);
        dstTry = fullfile(p, sprintf('%s_%02d%s', f, counter, e));
        counter = counter + 1;
    end
    if ~strcmp(dstTry, dst)
        collided = collided + 1;
        dst = dstTry;
    end

    % Report / apply
    rel = erase(dst, [rootDir filesep]);
    if dryRun
        fprintf('[DRY] %s -> %s\n', mrFiles(k).name, rel);
    else
        try
            movefile(src, dst);
            fprintf('[OK ] %s -> %s\n', mrFiles(k).name, rel);
            renamed = renamed + 1;
        catch ME
            warning('Failed to rename %s: %s', src, ME.message);
            skipped = skipped + 1;
        end
    end
end

fprintf('\nDone. Renamed: %d, Collisions handled: %d, Skipped: %d\n', ...
    renamed, collided, skipped);
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
    % Accept 'HHMMSS' or 'HHMMSS.FFFFFF' or shorter forms
    t = char(string(tin));
    t = regexprep(t, '\D', '');   % remove non-digits
    if isempty(t), t = '000000'; end
    if numel(t) >= 6
        t = t(1:6);
    else
        t = pad(t, 6, 'right', '0');
    end
end

function n = fixnum(x)
    % Convert to finite integer (avoid NaNs)
    if isempty(x) || ~isfinite(double(x))
        n = 0;
    else
        n = round(double(x));
    end
end

function s = slug(str, maxlen)
    if nargin < 2, maxlen = 80; end
    s = char(string(str));
    s = regexprep(s, '\s+', '_');           % spaces -> underscore
    s = regexprep(s, '[^\w\-]', '');        % keep [A-Za-z0-9_ -]
    s = regexprep(s, '_{2,}', '_');         % collapse ___
    if isempty(s), s = 'NA'; end
    if strlength(string(s)) > maxlen
        s = s(1:maxlen);
    end
end