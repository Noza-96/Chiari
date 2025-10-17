% Define the number of colors in the colormap
function bluetored(data)
    n = 256; % You can adjust this number
    
    % Create a blue to white gradient
    blue = [0, 0, 1];  % RGB for blue
    white = [1, 1, 1]; % RGB for white
    
    % Create a white to red gradient
    red = [1, 0, 0];   % RGB for red
    
    % Number of steps for each transition
    n1 = round(n / 2); % Number of colors from blue to white
    n2 = n - n1;       % Number of colors from white to red
    
    % Interpolate the blue to white transition
    blue_to_white = [linspace(blue(1), white(1), n1)', ...
                     linspace(blue(2), white(2), n1)', ...
                     linspace(blue(3), white(3), n1)'];
    
    % Interpolate the white to red transition
    white_to_red = [linspace(white(1), red(1), n2)', ...
                    linspace(white(2), red(2), n2)', ...
                    linspace(white(3), red(3), n2)'];
    
    % Combine the two gradients
    blue_white_red_colormap = [blue_to_white; white_to_red];
    
    % Apply the colormap
    colormap(blue_white_red_colormap);

    clim([-max(abs(data(:))), max(abs(data(:)))]);
    % Display a colorbar for reference
    colorbar;
end