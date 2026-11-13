function [c, cp, cb] = cad_coeff(pb, PS)
%CAD_COEFF  IEC standard-inverse time coefficients for fixed pickups PS.
%   T = coefficient * TMS.  c(r): close-in primary coefficient of relay r;
%   cp(k), cb(k): primary and backup coefficients of pair k.
GAMMA = 0.14; BETA = 0.02;
PS = PS(:);
Mp = max(pb.Ip ./ (PS(pb.P) .* pb.den_p), 1 + 1e-9);
Mb = max(pb.Ib ./ (PS(pb.B) .* pb.den_b), 1 + 1e-9);
cp = GAMMA ./ (Mp.^BETA - 1);
cb = GAMMA ./ (Mb.^BETA - 1);
c = zeros(pb.Nr,1);
m = pb.has_prim;
Mc = max(pb.Iclose(m) ./ (PS(m) .* pb.ctr(m)), 1 + 1e-9);
c(m) = GAMMA ./ (Mc.^BETA - 1);
end
