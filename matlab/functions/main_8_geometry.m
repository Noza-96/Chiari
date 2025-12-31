function main_8_geometry(cas)

    fprintf("8) Geometry:\n");

    % --- ANSYS install path + version (e.g., v231) ---
    ansys_path    = fullfile(config_path('ansys', fullfile(cas.dir.chiari, 'config_file.txt')));
    ansys_version = regexp(ansys_path, 'v\d+', 'match', 'once');

    % --- SpaceClaim executable ---
    sc_path = fullfile(ansys_path, 'scdm', 'SpaceClaim.exe');

    % --- SpaceClaim script to run ---
    script_clip_geometry = full_path(fullfile('..', 'ansys', 'clip_geometry.scscript'));

    % --- Write args file for SpaceClaim/Python (3 lines) ---
    % Location: in chiari root folder
    args_file = fullfile(pwd,  'ansys_sc_args.txt');

    fid = fopen(args_file, 'w');
    fprintf(fid, '%s\n', cas.subj);
    fprintf(fid, '%s\n', full_path(cas.dir.chiari));
    fprintf(fid, '%s\n', ansys_version);
    fclose(fid);

    fprintf("\tOpening SpaceClaim...\n");

    % --- Launch SpaceClaim non-blocking, no console output ---
    cmd = sprintf('cmd /s /c start "" /B "%s" /RunScript="%s" > NUL 2>&1', ...
                  sc_path, script_clip_geometry);

    system(cmd);
    
    a = '';
    while ~strcmpi(a, 'ok')
        a = input('Type "ok" to continue: ', 's');
    end

end