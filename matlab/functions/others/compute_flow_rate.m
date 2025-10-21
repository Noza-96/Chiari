function Q = compute_flow_rate(U, pixel_area)
%FLOW_RATE  Compute total flow rate over location for each time frame
%
%   Q = flow_rate(U, pixel_area)
%
%   Input:
%       U           : 3D array (nx × ny × Nt) of velocities
%       pixel_area  : scalar, area represented by one pixel [m²]
%
%   Output:
%       Q           : Nt×1 vector of total flow rate [m³/s]
%
    Q = transpose(reshape(sum(U, [1 2], 'omitnan'), [], 1)) * pixel_area;
end
