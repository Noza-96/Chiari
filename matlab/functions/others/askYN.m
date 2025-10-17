function ok = askYN(prompt)
    resp = input(prompt,'s');
    resp = strtrim(lower(resp));
    if isempty(resp), ok = true; return; end
    while ~ismember(resp, {'y','n'})
        resp = input('Please answer y or n (Enter = y): ','s');
        resp = strtrim(lower(resp));
        if isempty(resp), ok = true; return; end
    end
    ok = strcmp(resp,'y');
end