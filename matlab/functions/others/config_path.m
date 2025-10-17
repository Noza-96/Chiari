function path_out = config_path(program, config_file)
%CONFIG_PATH Return the path to a given program from config.txt
%
%   path_out = config_path(program, config_file)
%
%   Example:
%       p = config_path('slicer', 'C:\path\to\config.txt');
%
%   The config file should look like:
%       # Auto-generated on 15-Oct-2025 13:57:30
%       # Config file for local tools
%       SLICER_PATH="C:\Program Files\Slicer 5.8.1\Slicer.exe"
%       ANSYS_PATH="C:\Program Files\ANSYS Inc\v241"

    % --- Read file ---
    if ~isfile(config_file)
        error('Config file not found: %s', config_file);
    end
    lines = strsplit(fileread(config_file), newline);

    % --- Normalize program name ---
    program = upper(strtrim(program));
    key = program + "_PATH=";

    % --- Search line ---
    path_out = '';
    for i = 1:numel(lines)
        line = strtrim(lines{i});
        if startsWith(line, key)
            % Extract text inside quotes
            tokens = regexp(line, '="([^"]+)"', 'tokens');
            if ~isempty(tokens)
                path_out = tokens{1}{1};
                return;
            end
        end
    end

    % --- If not found ---
    if isempty(path_out)
        warning('Program "%s" not found in %s', program, config_file);
    end
end