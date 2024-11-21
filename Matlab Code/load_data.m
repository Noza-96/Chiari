function [cas, dat_PC] = load_data(subject, MRI_path)

    % fprintf("\n")
    % isCorrect = input("   Subject " + subject + "? [y/n]: ", 's');
    % 
    % % Loop until the user confirms or provides a new subject
    % while isCorrect ~= 'y'
    %     if isCorrect == 'n'
    %         % Prompt for the correct subject
    %         subject = input("Please enter the correct subject: ", 's');
    %     else
    %         disp("Invalid input. Please enter 'y' for yes or 'n' for no.");
    %     end
    %     % Ask for confirmation again
    %     isCorrect = input("Subject " + subject + "? [y/n]: ", 's');
    % end
    % 
    % % Continue with the rest of the code using the confirmed subject
    % disp("   Confirmed subject: " + subject);
    % fprintf("\n")
    % Add custom function path
    addpath('Functions/');
    addpath('Functions/Others/')
    addpath("data/" + subject);
    addpath("data/" + subject + "/ansys_outputs");


    % Load data from a previous script
    load("data/" + subject + "/03-apply_roi_compute_Q.mat");
    
    % For preprocessing
    if nargin == 2
        % List of directories to create
        folders = ["Figures", "Videos", "data/" + subject, ...
                   "data/" + subject + "/ansys_inputs", ...
                   "data/" + subject + "/ansys_inputs/FLTG", "data/" + subject + "/ansys_inputs/FLTG-2", ...
                   "data/" + subject + "/ansys_outputs", ...
                   "data/" + subject + "/ansys_outputs/FLTG", "data/" + subject + "/ansys_outputs/FLTG-2"];

        % Create directories if they do not exist
        for folder = folders
            if ~isfolder(folder)
                mkdir(folder);
            end
        end

        % Create subdirectories for 'pre' and 'post'
        for folder = ["Figures", "Videos"]
            if ~isfolder(folder + "/" + subject + "/pre")
                mkdir(folder + "/" + subject + "/pre");
            end
            if ~isfolder(folder + "/" + subject + "/post")
                mkdir(folder + "/" + subject + "/post");
            end
        end
        
        % Copy MRI-folder files to current folder
        copyfile(MRI_path, "data/" + subject + "/");
        disp('1. Directories created and PC-MRI data loaded...');
    else
        disp('1. Ansys output data transferred and loaded');
    end

end