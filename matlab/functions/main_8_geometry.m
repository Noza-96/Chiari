function main_8_geometry(cas)

    fprintf("8) Geometry:\n");

    geom_path = fullfile(cas.dir.ansys_in, "geometry", "c_geometry.scdoc");

    % --- ANSYS install path + version (e.g., v231) ---
    ansys_path    = fullfile(config_path('ansys', fullfile(cas.dir.chiari, 'config_file.txt')));
    sc_path = fullfile(ansys_path, "scdm");
    d = dir(fullfile(sc_path, "SpaceClaim.Api.V*"));
    versions = arrayfun(@(x) sscanf(x.name,'SpaceClaim.Api.V%d'), d);
    ansys_version = max(versions);

    % --- SpaceClaim executable ---
    sc_exe = fullfile(sc_path, 'SpaceClaim.exe');

    % Check if geometry already exists
    if exist(geom_path, 'file') == 2
    
        fprintf("- Existing geometry found...\n");
    
        a = strtrim(input('- Do you want to use the existing geometry? [yes]/no: ', 's'));
        if isempty(a); a = 'yes'; end
        if strcmpi(a, 'yes')
            fprintf("- Using existing geometry.\n\n");
            return
        end
    
        a = strtrim(input('- Do you want to recreate the geometry from scratch and replace it? [yes]/no: ', 's'));
        if isempty(a); a = 'yes'; end
        if ~strcmpi(a, 'yes')
            fprintf("- Geometry step skipped.\n");
            return
        end
    
        fprintf("- Recreating geometry from scratch...\n");
    end

    % Geometry creation from scratch
    script_clip_geometry = full_path(fullfile('..', 'ansys', 'clip_geometry.scscript'));

    % --- Write temporary file for SpaceClaim inputs---
    args_file = fullfile(pwd,  'ansys_sc_args.txt');

    fid = fopen(args_file, 'w');
    fprintf(fid, '%s\n', cas.subj);
    fprintf(fid, '%s\n', full_path(cas.dir.chiari));
    fprintf(fid, '%d\n', ansys_version);
    fclose(fid);

    fprintf("\tOpening SpaceClaim...\n");

    % --- Launch SpaceClaim non-blocking, no console output ---
    cmd = sprintf('cmd /s /c start "" /B "%s" /RunScript="%s" > NUL 2>&1', ...
                  sc_exe, script_clip_geometry);

    system(cmd);

    fprintf([ ...
        '=== Manual steps to follow in SpaceClaim ===\n\n' ...
        '1. Change the name of the auto-skinned surface to "fluid".\n\n' ...
        '2. Cut the geometry by the selected planes:\n' ...
        '   Design -> Intersect -> Split Body.\n\n' ...
        '3. Delete everything except "fluid".\n\n' ...
        '4. Create named selections:\n' ...
        '   bottom, top, cord, dura, tonsils, (nerve_roots, ligaments).\n\n' ...
        '5. Save and exit.\n\n' ...
        '--- Troubleshooting ---\n' ...
        'If there is an error when generating the geometry:\n' ...
        '  • Redo the segmentation in Slicer 3D.\n' ...
        '  • Problematic locations can often be identified using:\n' ...
        '    Tools -> Auto Skin.\n\n' ...
    ]);
    
    a = '';
    while ~strcmpi(a, 'ok')
        a = input('Type "ok" to continue: ', 's');
    end



end