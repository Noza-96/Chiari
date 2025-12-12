function [cas,dat_PC] = main_7_geometry(cas)

sc_path = '"C:\Program Files\ANSYS Inc\v242\scdm\SpaceClaim.exe"';

script_clip_geometry = full_path(fullfile(pwd,'..', 'ansys', 'clip_geometry.scscript'));

cmd = [sc_path ' /RunScript=' scScript];

status = system(cmd);

end