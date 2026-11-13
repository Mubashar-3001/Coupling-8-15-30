function x = cad_policy_solve(Nr, Pk, Bk, ak, bk, TMS, lo, hi)
%CAD_POLICY_SOLVE  Linear solve of the binding CTI constraints, with a check.
%   For every relay b the binding term is the pair (with backup b) of largest
%   requirement, or the lower bound if that is larger.  The returned point is
%   accepted only if it is feasible, lies within the bounds and is not below
%   the current iterate; it is then the least feasible TMS vector, because a
%   cycle of binding pairs with gain product >= 1 would force values below the
%   positive lower bound.  Returns [] if the check fails.
need = ak .* TMS(Pk) + bk;
A = zeros(Nr); rhs = repmat(lo, Nr, 1);
for b = unique(Bk)'
    ks = find(Bk == b);
    [v, j] = max(need(ks));
    if v > lo + 1e-15
        A(b, Pk(ks(j))) = ak(ks(j));
        rhs(b) = bk(ks(j));
    end
end
M = eye(Nr) - A;
if rcond(M) < 1e-14, x = []; return; end
x = M \ rhs;
if any(~isfinite(x)) || min(x) < lo - 1e-12 || max(x) > hi + 1e-12 || ...
   any(ak .* x(Pk) + bk > x(Bk) + 1e-12) || any(x < TMS - 1e-12)
    x = []; return
end
x = min(max(x, lo), hi);
end
