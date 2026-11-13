function r = cad_solve_mono(pb, seed, E, opt)
%CAD_SOLVE_MONO  Monolithic search over all pickups with E fitness evaluations.
if nargin < 4, opt = struct(); end
opt.budget = E;
rs = RandStream('mt19937ar', 'Seed', seed);
prev = RandStream.setGlobalStream(rs);
lo = pb.ps_lo_vec; hi = pb.ps_hi_vec;
mid = 0.5*(lo + hi);
fun = @(ps) cad_eval(pb, mid, (1:pb.Nr)', ps, [], []);
t0 = tic;
[PS, ~, used] = cad_psogsa(fun, lo, hi, opt);
[obj, TMS, ok] = cad_exact_tms(pb, PS);
RandStream.setGlobalStream(prev);
r = struct('obj', obj, 'feasible', ok, 'TMS', TMS, 'PS', PS, ...
           'evals', used + 1, 'wall', toc(t0));
end
