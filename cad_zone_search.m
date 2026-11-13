function [psz, used, wall] = cad_zone_search(pb, zof, g, seed, budget, opt)
%CAD_ZONE_SEARCH  Interior stage for zone g.  Only pairs with both relays in
%   the zone enter the fitness and only the zone's relays enter the objective,
%   so zones are independent and can run in any order or in parallel.
t0 = tic;
zof = zof(:);
rel = find(zof == g);
intra = zof(pb.P) == zof(pb.B);
pair_idx = find(intra & zof(pb.P) == g);
mid = 0.5*(pb.ps_lo_vec + pb.ps_hi_vec);
if isempty(pair_idx) || budget < 1
    psz = mid(rel); used = 0; wall = toc(t0); return
end
rs = RandStream('mt19937ar', 'Seed', seed);
prev = RandStream.setGlobalStream(rs);
mask = (zof == g);
fun = @(ps) cad_eval(pb, mid, rel, ps, pair_idx, mask);
lo = pb.ps_lo_vec(rel); hi = pb.ps_hi_vec(rel);
opt.budget = budget;
[psz, ~, used] = cad_psogsa(fun, lo, hi, opt);
RandStream.setGlobalStream(prev);
wall = toc(t0);
end
