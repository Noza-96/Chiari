function [type_geometry, type_simulation, boundary_inlet] = get_type_simulation(DNS_case)
    DNS_case = char(DNS_case);
    type_geometry = regexp(DNS_case, '^[a-zA-Z]+', 'match', 'once');
    type_simulation = str2double(regexp(DNS_case, '\d+', 'match', 'once'));
    if ismember(type_simulation, [0, 1])
        boundary_inlet = 'top'; % by default top 
        if length(DNS_case) == 3 && DNS_case(end)=='b'
            boundary_inlet = 'bottom';
        elseif length(DNS_case) == 3 && DNS_case(end)=='t'
            boundary_inlet = 'top';
        end
    else
        boundary_inlet = '';
    end
end