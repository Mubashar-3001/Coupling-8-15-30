function r = cad_solve_deco(pb, zof, seed, E, opt, max_tries, use_parfor)
%CAD_SOLVE_DECO  Decomposed coordination with E fitness evaluations per attempt:
%   interior stage per zone, boundary reconciliation of the relays on
%   cross-zone pairs against all pairs, exact global TMS solve, and a fresh
%   attempt (new seed) if the assembled pickups admit no feasible TMS.
if nargin < 5 || isempty(opt), opt = struct(); end
if nargin < 6 || isempty(max_tries), max_tries = 5; end
if nargin < 7, use_parfor = false; end
zof = zof(:);
G = max(zof);
[zb, bb, ~, bidx, ncross] = cad_allocate(pb, zof, E);
tot = 0; t_all = tic;
for tr = 1:max_tries
    PS = 0.5*(pb.ps_lo_vec + pb.ps_hi_vec);
    zps = cell(G,1); zev = zeros(G,1); zt = zeros(G,1);
    t_int = tic;
    if use_parfor
        parfor g = 1:G
            [zps{g}, zev(g), zt(g)] = cad_zone_search(pb, zof, g, seed*1000 + tr*50 + g, zb(g), opt);
        end
    else
        for g = 1:G
            [zps{g}, zev(g), zt(g)] = cad_zone_search(pb, zof, g, seed*1000 + tr*50 + g, zb(g), opt);
        end
    end
    t_interior = toc(t_int);
    for g = 1:G, PS(zof == g) = zps{g}; end
    t_b = tic; bev = 0;
    if ~isempty(bidx)
        rs = RandStream('mt19937ar', 'Seed', seed*1000 + tr*50);
        prev = RandStream.setGlobalStream(rs);
        fun = @(psb) cad_eval(pb, PS, bidx, psb, [], []);
        lo = pb.ps_lo_vec(bidx); hi = pb.ps_hi_vec(bidx);
        ob = opt; ob.budget = bb;
        [best, ~, bev] = cad_psogsa(fun, lo, hi, ob);
        RandStream.setGlobalStream(prev);
        PS(bidx) = best;
    end
    [obj, TMS, ok] = cad_exact_tms(pb, PS);
    t_bnd = toc(t_b);
    tot = tot + sum(zev) + bev + 1;
    if ok, break; end
end
r = struct('obj', obj, 'feasible', ok, 'TMS', TMS, 'PS', PS, 'tries', tr, ...
           'zone_evals', zev, 'zone_times', zt, 'bnd_evals', bev, ...
           't_interior', t_interior, 't_boundary', t_bnd, ...
           'evals', tot, 'wall', toc(t_all), ...
           'maxdim', max(accumarray(zof, 1)), 'cross', ncross, 'nbnd', numel(bidx));
end
