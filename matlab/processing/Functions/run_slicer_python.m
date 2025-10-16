function run_slicer_python(cas, python_script)
    slicer_path = fullfile(config_path('slicer', fullfile(cas.dir.chiari, 'config_file.txt')));

    args = "--no-splash --python-script """ + python_script + ...
           """ """ + cas.subj + """ """ + cas.dir.chiari + """";
    
    if ispc
        % ----- Windows -----
        % Non-blocking, no window, no console output
        cmd = "cmd /s /c start """" /B """ + slicer_path + """ " + args + " > NUL 2>&1";
    elseif ismac
        % ----- macOS -----
        % Runs detached in background, discards all output
        cmd = """" + slicer_path + """ " + args + " > /dev/null 2>&1 &";
    else
        % ----- Linux or others -----
        cmd = """" + slicer_path + """ " + args + " > /dev/null 2>&1 &";
    end
    
    system(cmd); 

    a = '';
    while ~strcmpi(a, 'ok')
        a = input('Type "ok" to continue: ', 's');
    end
end