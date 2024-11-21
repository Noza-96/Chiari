%Calculate longitudinal impedance
function (ZL,LI) = Longitudinal_Impedance(Dp,Q) 
    ZL = norm(Dp(1:8)./Q(1:8));
    LI = sum(ans)*(length(ZL)-1)/(length(ZL));
end