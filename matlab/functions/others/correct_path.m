function filepath = correct_path(filepath)
    filepath = strrep(filepath, '\', '/');
end