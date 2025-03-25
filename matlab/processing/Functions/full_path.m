function absolutePath = full_path(folder_path)
    % Convert to absolute path
    folder_path = fullfile(folder_path);  % Normalize
    try
        f = java.io.File(folder_path);
        absolutePath = char(f.getCanonicalPath());
    catch
        % Fallback in case Java fails
        absolutePath = char(f.getAbsolutePath());
    end

    % Replace backslashes with slashes if needed (optional)
    if ispc
        % Use forward slashes only if needed by other tools
        % Otherwise keep native style (Windows: '\')
        absolutePath = strrep(absolutePath, '/', filesep);
    else
        % macOS/Linux: force slash separator
        absolutePath = strrep(absolutePath, '\', '/');
    end
end