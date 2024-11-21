function Transfer_ansys(subject)

    Ansys_path_variable = "../3. Ansys/"+subject+"_files/dp0/FLTG/Fluent/";
    Ansys_path_uniform = "../3. Ansys/"+subject+"_files/dp0/FLTG-2/Fluent/";
    copyfile("data/"+subject+"/ansys_inputs/FLTG/*",Ansys_path_variable,'f');
    % delete(Ansys_path_variable+"Q0.txt")
    copyfile("data/"+subject+"/ansys_inputs/FLTG-2/*",Ansys_path_uniform);

    disp('6. Copied data into ansys folders.')
    disp('Preprocessing completed!')
end