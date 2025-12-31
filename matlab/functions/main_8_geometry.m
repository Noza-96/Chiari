function main_8_geometry(cas)

% Create top and bottom planes


ansys_path = fullfile(config_path('ansys', fullfile(cas.dir.chiari, 'config_file.txt')));
sc_path = fullfile(ansys_path, 'scdm', 'SpaceClaim.exe');

script_clip_geometry = full_path(fullfile(pwd, '..', 'ansys', 'clip_geometry.scscript'));

cmd = [sc_path ' /RunScript=' script_clip_geometry];

status = system(cmd);

end