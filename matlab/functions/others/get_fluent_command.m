function fluent_command = get_fluent_command(cas)

    ansys_path    = fullfile(config_path('ansys', fullfile(cas.dir.chiari, 'config_file.txt')));
    fluent_command = fullfile(ansys_path, "fluent", "ntbin", "win64", "fluent.exe");

end