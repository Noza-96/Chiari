function run_ANSYS_simulations(cas, dat_PC, DNS_cases, n_cores, visualize_console)

    % Run simulations for each DNS case
    for k = 1:length(DNS_cases)
        tic; % Start timing

        % Load the DNS data
        DNS = loadDNSData(cas, DNS_cases{k});

        % Create and run the ANSYS journal
        
        fileID = fopen(fullfile(cas.diransys_in, "journals", DNS.case + ".jou"), 'w');
        
        % Setup simulation
        TUI_setup_Fluent_case(DNS, cas, fileID);
        
        % Create PCMRI surfaces and other necessary setups
        TUI_create_surfaces_journal(dat_PC, cas, DNS, fileID);
        
        % Add reports 
        TUI_reports_journal(cas, DNS, fileID);
        
        % run the simulation
        TUI_run_simulation(dat_PC, cas, DNS, fileID);


        runFluentSimulation(DNS, DNS_cases{k}, n_cores, visualize_console);

        % Finalize after simulation
        elapsed_time = toc;
        finalizeSimulation(DNS, DNS_cases{k}, cas, elapsed_time);
    end
end

% Helper function to check if the case file exists
function exists = checkCaseFile(cas, case_name)
    file_path = fullfile(cas.diransys_in, case_name + "_0.cas.gz");
    exists = isfile(file_path);
    if ~exists
        fprintf(2, 'Error: Case file %s not found.\n', case_name);
    end
end

% Helper function to load DNS data
function DNS = loadDNSData(cas, case_name)
    load(fullfile(cas.dirmat, "DNS_" + case_name + ".mat"), 'DNS');
end

% Helper function to run the Fluent simulation through terminal
function runFluentSimulation(DNS, case_name, n_cores, visualize_console)
    fluent_cmd = "fluent 3ddp -t" + n_cores + " -g -i """ + fullfile(DNS.ansys_path, DNS.subject, "inputs", "journals", case_name + ".jou") + """";
    if visualize_console == 0
        fluent_cmd = fluent_cmd + " > nul";
    end
    system(fluent_cmd); % Run with "> nul" to suppress terminal output
end

% Helper function to finalize simulation and save results
function finalizeSimulation(DNS, case_name, cas, elapsed_time)
    delete('fluent*'); % Delete temporary files
    movefile(case_name + "_variables.out", fullfile(cas.diransys_out, case_name, case_name + "_report.out"));
    fprintf("%s completed in %.2f seconds.\n", case_name, elapsed_time);

    % Save the simulation time
    DNS.time = elapsed_time;
    save(fullfile(cas.dirmat, "DNS_" + DNS.case + ".mat"), 'DNS');
end