% run ansys simulation through terminal
function run_ANSYS_simulations (cas, dat_PC, DNS_cases, n_cores)
    stopProgram = false;

    for k = 1:length(DNS_cases)
        load(fullfile(cas.dirmat, "DNS_" + DNS_cases{k} + ".mat"), 'DNS');
        % Check if the case file exists
        if ~isfile(fullfile(cas.diransys_in, DNS.case + "_0.cas.gz"))
            fprintf(2, 'Error: Case file %s not found.\n', DNS_cases{k});
            stopProgram = true;
        end
    end

    % stop program if cases need to be created 
    if stopProgram
        error('Program terminated due to missing case files. Run ansys journal in fluent meshing.');
    end

    for k = 1:length(DNS_cases)
    
        tic; % Start timing
    
        load(fullfile(cas.dirmat, "DNS_" + DNS_cases{k} + ".mat"), 'DNS');
    

    
        % create ansys journal
        create_journal(dat_PC, cas, DNS)
    
        % run ansys journal through terminal
        fluent_cmd = "fluent 3ddp -t"+n_cores+" -g -i """+fullfile(DNS.ansys_path,DNS.subject,"inputs",DNS_cases{k}+".jou")+"""";
        system(fluent_cmd + " > nul"); % run with "> nul" to not print terminal
    
        elapsed_time = toc; % Stop timing
        delete('fluent*') % delete files created during the sumilation
        movefile(DNS_cases{k}+"_variables.out", fullfile(cas.diransys_out,DNS_cases{k},DNS_cases{k}+"_report.out"))
        fprintf("%s completed in %.2f seconds.\n", DNS_cases{k}, elapsed_time);
        DNS.time = elapsed_time;
        save(fullfile(cas.dirmat,"DNS_"+DNS.case+".mat"),'DNS')
        clear DNS
        
    end
end

function create_journal(dat_PC, cas, DNS)
    fileID = fopen(cas.diransys_in + "/" + DNS.case + ".jou", 'w');
    % setup simulation 
    setup_case_TUI(DNS, fileID);
            
    % Create pcmri surfaces in ansys and surface
    create_surfaces_journal_TUI(dat_PC, cas, DNS, fileID);
            
    % Reports
    reports_journal_TUI(cas, DNS, fileID);
            
    % run simulation
    run_simulation_TUI(dat_PC, cas, DNS, fileID);
end