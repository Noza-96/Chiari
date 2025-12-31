function main_8_geometry(cas)

    fprintf("8) Geometry:\n")  
    
    ansys_path = fullfile(config_path('ansys', fullfile(cas.dir.chiari, 'config_file.txt')));

    ansys_version = regexp(ansys_path, 'v\d+', 'match', 'once');

    sc_path = fullfile(ansys_path, 'scdm', 'SpaceClaim.exe');
    
    script_clip_geometry = full_path(fullfile('..', 'ansys', 'clip_geometry_ansys.py'));
    
    fprintf("\tOpening SpaceClaim...\n") 
    
    cmd = ['cmd /s /c start "" /B "' sc_path ...
           '" /RunScript="' script_clip_geometry ...
           '" "' cas.subj '" "' full_path(cas.dir.chiari) '" "' ansys_version '" > NUL 2>&1'];

    system(cmd);
    
    a = '';
    while ~strcmpi(a, 'ok')
        a = input('Type "ok" to continue: ', 's');
    end

end