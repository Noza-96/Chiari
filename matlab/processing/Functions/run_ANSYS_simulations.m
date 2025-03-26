function run_ANSYS_simulations(cas, dat_PC, DNS_cases, n_cores, visualize_output)
    % Flag to stop program if any case file is missing
    stopProgram = false;

    % Check if the necessary case files exist
    for k = 1:length(DNS_cases)
        if ~checkCaseFile(cas, DNS_cases{k})
            stopProgram = true;
        end
    end

    % Terminate if any case file is missing
    if stopProgram
        error('Program terminated due to missing case files. Run ansys journal in fluent meshing.');
    end

    % Run simulations for each DNS case
    for k = 1:length(DNS_cases)
        tic; % Start timing

        % Load the DNS data
        DNS = loadDNSData(cas, DNS_cases{k});

        % Create and run the ANSYS journal
        create_journal(dat_PC, cas, DNS);
        runFluentSimulation(DNS, DNS_cases{k}, n_cores, visualize_output);

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
function runFluentSimulation(DNS, case_name, n_cores, visualize_output)
    fluent_cmd = "fluent 3ddp -t" + n_cores + " -g -i """ + fullfile(DNS.ansys_path, DNS.subject, "inputs", case_name + ".jou") + """";
    if visualize_output == 0
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

% Function to create the ANSYS journal
function create_journal(dat_PC, cas, DNS)
    fileID = fopen(fullfile(cas.diransys_in, DNS.case + ".jou"), 'w');
    
    % Setup simulation
    setup_Fluent_case_TUI(DNS, fileID);
    
    % Create PCMRI surfaces and other necessary setups
    create_surfaces_journal_TUI(dat_PC, cas, DNS, fileID);
    
    % Add reports and run the simulation
    reports_journal_TUI(cas, DNS, fileID);
    run_simulation_TUI(dat_PC, cas, DNS, fileID);
end
