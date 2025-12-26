function main_8_geometry(cas)

data_now = "data_4.mat";

[cas, dat_PC, didSkip] = check_data_updated(cas, data_now, "data_3.mat", dir(fullfile(cas.dir.trans, '*')));
if didSkip, return, end   

% Create top and bottom planes


ansys_path = fullfile(config_path('ansys', fullfile(cas.dir.chiari, 'config_file.txt')));
sc_path = fullfile(ansys_path, 'scdm', 'SpaceClaim.exe');

script_clip_geometry = full_path(fullfile(pwd, '..', 'ansys', 'clip_geometry.scscript'));

cmd = [sc_path ' /RunScript=' script_clip_geometry];

status = system(cmd);

end