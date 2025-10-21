function Vs = compute_stroke_volume(Q, T)
%COMPUTE_STROKE_VOLUME  Compute stroke volume from flow waveform.
%
%   Vs = compute_stroke_volume(Q, T)
%
%   Input:
%       Q : flow rate waveform [m³/s]
%       T : period of the waveform [s]
%
%   Output:
%       Vs : stroke volume [m³]
%
%   The function integrates the absolute value of the flow rate
%   over one period using Simpson's rule.

    t = linspace(0, 1, length(Q))*T;
    Vs = 0.5 * simps(t, abs(Q), 2);
end
