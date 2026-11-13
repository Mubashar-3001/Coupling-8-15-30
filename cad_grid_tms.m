function [obj, TMS, feasible, minmargin] = cad_grid_tms(pb, PS, step)
%CAD_GRID_TMS  Least grid-feasible TMS (steps of STEP) for fixed pickups.
%   Same relaxation as cad_exact_tms, but every requirement is rounded up to
%   the next tap, so the result is both on the relay grid and CTI-feasible.
if nargin < 3, step = 0.01; end
[c, cp, cb] = cad_coeff(pb, PS);
alpha = cp ./ cb; beta = pb.cti ./ cb;
nlo = round(pb.sys.tms_lo/step); nhi = round(pb.sys.tms_hi/step);
Tn = repmat(nlo, pb.Nr, 1);
feasible = true;
Pk = pb.P(pb.coord_idx); Bk = pb.B(pb.coord_idx);
ak = alpha(pb.coord_idx); bk = beta(pb.coord_idx);
for pass = 1:(nhi - nlo + 1)*pb.Nr %#ok<FORPF>
    need  = ak .* (Tn(Pk)*step) + bk;
    needn = ceil(need/step - 1e-9);
    viol  = needn > Tn(Bk);
    if ~any(viol), break; end
    if any(needn(viol) > nhi), feasible = false; break; end
    for q = find(viol)'
        if needn(q) > Tn(Bk(q)), Tn(Bk(q)) = needn(q); end
    end
end
TMS = Tn*step;
obj = sum(c .* TMS);
m = cb(pb.coord_idx) .* TMS(Bk) - cp(pb.coord_idx) .* TMS(Pk) - pb.cti;
minmargin = min(m);
feasible = feasible && minmargin >= -1e-9;
end
