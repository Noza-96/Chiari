function fluent_command = get_fluent_command()

    if ispc
        hostname = getenv('COMPUTERNAME');
    else
        [~, hostname] = system('hostname');
        hostname = strtrim(hostname);  % remove newline
    end
    
    if hostname == "DESKTOP-30N19DV"
        fluent_command = """C:\Program Files\ANSYS Inc\v231\fluent\ntbin\win64\fluent.exe""";
    elseif hostname == "Guillermos-MacBook-Pro.local"
        disp('Ansys path not available ...');
        return;
    else    
        fluent_command = 'fluent'; % fluent has been added to the path
    end
end