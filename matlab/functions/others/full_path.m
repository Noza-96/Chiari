function absolutePath = full_path(folder_path)
    folder_path = fullfile(pwd,folder_path);
    absolutePath = char(java.io.File(folder_path).getCanonicalPath());
end