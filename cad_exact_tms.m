function [obj, TMS, feasible, block, info] = cad_exact_tms(pb, PS, pair_idx, relay_mask)
%CAD_EXACT_TMS  Exact time-multiplier solve for fixed pickups.
%   Each CTI constraint is TMS(b) >= alpha*TMS(p) + beta with alpha > 0.
%   Starting from the lower bounds, backups are raised until no constraint
%   is violated; the iterates increase monotonically towards the least
%   feasible TMS vector, which minimises the positive-weighted objective.
%   On networks whose primary/backup graph has cycles the approach is
%   geometric, so once the increments are small the binding constraints are
%   solved as a linear system and the result is certified (cad_policy_solve).
%   A requirement above the upper bound proves that no feasible TMS exists;
%   BLOCK is the backup relay at which this was detected (0 if feasible).
if nargin < 3 || isempty(pair_idx), pair_idx = pb.coord_idx; else, pair_idx = pair_idx(pb.coord(pair_idx)); end
if nargin < 4, relay_mask = []; end
[c, cp, cb] = cad_coeff(pb, PS);
alpha = cp ./ cb;
beta  = pb.cti ./ cb;
lo = pb.sys.tms_lo; hi = pb.sys.tms_hi;
TMS = repmat(lo, pb.Nr, 1);
Pk = pb.P(pair_idx); Bk = pb.B(pair_idx);
ak = alpha(pair_idx); bk = beta(pair_idx);
active = true(numel(pair_idx),1);
if ~isempty(relay_mask), active = active & relay_mask(Bk); end
feasible = true; block = 0;
info = struct('passes', 0, 'certified', false, 'capped', false);
last_try = -10;
for it = 1:25*pb.Nr
    need = ak .* TMS(Pk) + bk;
    gap  = need - TMS(Bk);
    viol = active & (gap > 1e-13);
    if ~any(viol), break; end
    over = viol & (need > hi + 1e-9);
    if any(over)
        % every iterate is a lower bound on the least solution, so a
        % requirement above the upper bound proves infeasibility
        feasible = false;
        block = Bk(find(over, 1));
        break
    end
    capped = min(need, hi);
    for q = find(viol)'
        if capped(q) > TMS(Bk(q)), TMS(Bk(q)) = capped(q); end
    end
    info.passes = it;
    if max(gap(active)) < 1e-6 && it - last_try >= 4
        last_try = it;
        x = cad_policy_solve(pb.Nr, Pk(active), Bk(active), ak(active), bk(active), TMS, lo, hi);
        if ~isempty(x)
            TMS = x; info.certified = true;
            break
        end
    end
    if it == 25*pb.Nr, info.capped = true; end
end
if isempty(relay_mask)
    obj = sum(c .* TMS);
else
    obj = sum(c(relay_mask) .* TMS(relay_mask));
end
end
