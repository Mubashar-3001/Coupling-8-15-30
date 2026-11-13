function [obj, TMS, feasible] = cad_linprog_tms(pb, PS)
%CAD_LINPROG_TMS  Reference solve of the TMS linear program with linprog
%   (Optimization Toolbox), used only to cross-check cad_exact_tms.
[c, cp, cb] = cad_coeff(pb, PS);
ks = pb.coord_idx;
A = zeros(numel(ks), pb.Nr);
for q = 1:numel(ks)
    k = ks(q);
    A(q, pb.P(k)) = A(q, pb.P(k)) + cp(k);
    A(q, pb.B(k)) = A(q, pb.B(k)) - cb(k);
end
b = -pb.cti*ones(numel(ks),1);
lb = repmat(pb.sys.tms_lo, pb.Nr, 1); ub = repmat(pb.sys.tms_hi, pb.Nr, 1);
o = optimoptions('linprog', 'Display', 'off', 'Algorithm', 'dual-simplex', ...
                 'OptimalityTolerance', 1e-10, 'ConstraintTolerance', 1e-10);
[x, fv, flag] = linprog(c, A, b, [], [], lb, ub, o);
feasible = flag == 1;
if feasible, obj = fv; TMS = x; else, obj = NaN; TMS = nan(pb.Nr,1); end
end
