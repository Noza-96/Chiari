% Create flow rate with colors
function flow_rate(Q, n)
    if Q(1) ~= Q(end)
        Q = [Q(:);Q(1)]';
    end
    if nargin == 1
        n=0;
    end
    % Define color schemes
    blue = [116, 124, 187] / 255;  
    red = [241, 126, 126] / 255;
    fs = 12;
    % Create a time vector
    t = linspace(0, 1, length(Q));
    % Plot the flow rate
    plot(t, Q, '-', 'LineWidth', 1.5, 'Color', 'k');
    hold on;

    % Separate positive and negative flow rates for shading
    Q_neg = Q .* (Q < 0);
    area(t, Q, 'FaceColor', red);
    area(t, Q_neg, 'FaceColor', blue);

    % Set axis properties
    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', 10);

    % Highlight the specific point if n is greater than 0
    if n > 0
        xline(t(n+1), 'LineWidth', 1);
    end

    % Plot a horizontal line at y=0
    plot(t, n * 0, '-', 'LineWidth', 1, 'Color', 'k');
    
    % Add labels if needed (optional)
    xlabel('$t/T$', 'Interpreter', 'latex', 'FontSize', fs);
    % ylabel('$Q\left[{\rm ml/s}\right]$', 'Interpreter', 'latex', 'FontSize', fs);
    ylim([-ceil(max(abs(Q))),ceil(max(abs(Q)))])
    hold off
end
