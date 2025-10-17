function check_compatibility(programs)

    % --- Define commands and installation URLs ---
    commands = {
        'sct_deepseg', 'https://spinalcordtoolbox.com/user_section/installation/windows.html';
        'bash',        'https://git-scm.com/downloads/win';
        'dcm2niix',    'https://pypi.org/project/dcm2niix/'
    };

    config_file = full_path(fullfile(pwd, '..', '..', 'config_file.txt'));

    if ~exist(config_file, "file")
        
        % check tools exist
        missing = check_tools_exist(commands);
        if ~isempty(missing)
            fprintf('\nCommands that need to be installed:\n');
            for i = 1:numel(missing)
                fprintf('  - %s\n', missing{i});
            end
            error('Some required commands are missing — see list above.');
        end

        % create config paths
        find_programs_paths(programs, config_file);
    end
end

function missing = check_tools_exist(commands)
        missing = {};
    
        % --- Loop through each command ---
        for i = 1:size(commands,1)
            cmd = commands{i,1};
            url = commands{i,2};
    
            % Choose appropriate check command depending on OS
            if isunix || ismac
                check_cmd = ['which ', cmd];
            else
                check_cmd = ['where ', cmd];
            end
    
            [status, ~] = system(check_cmd);
    
            if status ~= 0
                missing{end+1} = sprintf('%s (install: %s)', cmd, url); 
            end
        end
end

function find_programs_paths(programs, config_file)
%FIND_PROGRAMS_PATHS  Create config.txt with paths to Slicer and ANSYS root folder.
% - Refuses to overwrite an existing config.txt
% - Tries PATH and known installation directories (Windows/macOS/Linux)
% - Prompts user to select manually if not found.

    % ----------------------------
    % 1) Try to find programs

    for prog = lower(programs)

        if contains(prog, 'slicer')
            slicer_guess = findOnPathFirst('Slicer');        
            % If not found automatically, ask user
            if isempty(slicer_guess) || ~isfile(slicer_guess)
                slicer_guess = guessSlicer();
            end
            if isempty(slicer_guess) || ~isfile(slicer_guess)
                slicer_guess = askForPath('SLICER_PATH', ...
                    'Select  Slicer executable (e.g., Slicer.exe or Slicer)');
                slicer_guess = fullfile(slicer_guess, 'Slicer.exe');
            end
            % Validate path
            if isempty(slicer_guess) || ~isfile(slicer_guess)
                error("Invalid Slicer path: '%s'", string(slicer_guess));
            end
        end
    
        if contains(prog, 'ansys')
            ansys_guess  = guessANSYS();  % Find ANSYS root folder
            if isempty(ansys_guess) || ~isfolder(ansys_guess)
                ansys_guess = uigetdir('C:\', ...
                    'Select ANSYS root folder (e.g., C:\Program Files\ANSYS Inc\)');
            end
            if isempty(ansys_guess) || ~isfolder(ansys_guess)
                error("Invalid ANSYS folder: '%s'", string(ansys_guess));
            end
        end

        if ~ismember(prog, {'slicer', 'ansys'})
            error("Invalid program name: '%s'", prog);
        end
    end

    % ----------------------------
    % 3) Write config
    % ----------------------------
    fid = fopen(config_file, 'w');
    assert(fid > 0, 'Could not open file for writing: %s', config_file);
    c = onCleanup(@() fclose(fid));

    fprintf(fid, '# Auto-generated on %s\n', datestr(now));
    fprintf(fid, '# Config file for local tools\n');
    if any(contains(lower(programs), 'slicer'))
        fprintf(fid, 'SLICER_PATH="%s"\n', slicer_guess);
    end

    if any(contains(lower(programs), 'ansys'))
        fprintf(fid, 'ANSYS_PATH="%s"\n', ansys_guess);
    end

    fprintf('Config written to: %s\n', config_file);
end

% ------- helpers -------

function exe = findOnPathFirst(name)
% Try PATH using system 'which/where'
    if ispc
        [st, out] = system(['where ', name, ' 2>NUL']);
    else
        [st, out] = system(['which ', name, ' 2>/dev/null']);
    end
    if st == 0
        lines = strtrim(splitlines(string(out)));
        lines = lines(lines ~= "");
        if ~isempty(lines)
            exe = char(lines(1));
            return
        end
    end
    exe = '';
end

function p = guessSlicer()
% Try common installation paths for  Slicer
    if ispc
        p = lastMatchWindows("C:\Program Files", "Slicer*", "Slicer.exe");
    elseif ismac
        p = firstExisting("/Applications/Slicer.app/Contents/MacOS/Slicer");
    else
        p = firstExisting(["/usr/bin/Slicer", ...
                           "/usr/local/bin/Slicer", ...
                           "/opt/slicer/Slicer"]);
    end
end

function p = guessANSYS()
% Find the root ANSYS installation folder (not Fluent executable)
    if ispc
        rootDir = "C:\Program Files\ANSYS Inc";
        if isfolder(rootDir)
            % Pick the latest v* directory if multiple versions exist
            vers = dir(fullfile(rootDir, "v*"));
            if ~isempty(vers)
                [~, idx] = sort({vers.name});
                latest = vers(idx(end)).name;
                p = fullfile(rootDir, latest);
                return;
            end
            % fallback: just return the base folder
            p = rootDir;
        else
            p = '';
        end
    elseif ismac
        fprintf('ANSYS not available on macOS... \n');
        p = 'NAN';
    else
        % Linux typical installs
        candidates = ["/usr/ansys_inc", "/opt/ansys_inc"];
        p = '';
        for c = candidates
            if isfolder(c)
                p = c;
                break;
            end
        end
    end
end

function p = lastMatchWindows(rootDir, versionGlob, tailRelative)
    p = '';
    if ~isfolder(rootDir), return; end
    vers = dir(fullfile(rootDir, versionGlob));
    if isempty(vers), return; end
    [~, idx] = sort({vers.name});
    vers = vers(idx);
    for k = 1:numel(vers)
        candidate = fullfile(vers(k).folder, vers(k).name, tailRelative);
        if isfile(candidate)
            p = candidate;
        end
    end
end

function p = firstExisting(candidates)
    if isstring(candidates) || ischar(candidates)
        candidates = string(candidates);
    end
    p = '';
    for c = candidates(:)'
        if isfile(c)
            p = char(c);
            return
        end
    end
end

function selected = askForPath(envName, promptTitle)
%ASKFORPATH Ask user to type or paste a path (folder or executable).
%   selected = askForPath(envName, promptTitle)
%
%   - Accepts either a folder path or a full path to an executable.
%   - If an executable is given, the containing folder is returned.
%   - Shows the value of the environment variable envName as default.
%
%   Example:
%       selected = askForPath('ANSYS_PATH', 'Enter path to ANSYS folder');

    def = getenv(envName);

    if isempty(def)
        def = '';
        fprintf('%s\n', promptTitle);
        userInput = strtrim(input('Enter full path: ', 's'));
    else
        fprintf('%s\n(Default: %s)\n', promptTitle, def);
        userInput = strtrim(input('Enter full path (press Enter to keep default): ', 's'));
        if isempty(userInput)
            userInput = def;
        end
    end

    % --- Normalize and validate ---
    userInput = strtrim(userInput);

    if isfile(userInput)
        % If user gives an executable, take its containing folder
        selected = fileparts(userInput);
    elseif isfolder(userInput)
        % If it's already a folder, keep it
        selected = userInput;
    else
        % Neither a valid file nor folder
        warning('The provided path does not exist: %s', userInput);
        selected = userInput;
    end

    % --- Optional: clean trailing file separators ---
    if endsWith(selected, filesep)
        selected = extractBefore(selected, strlength(selected));
    end
end
