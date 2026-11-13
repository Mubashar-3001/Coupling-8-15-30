function [gbest, gf, used, restarts] = cad_psogsa(fun, lo, hi, opt)
%CAD_PSOGSA  PSO-GSA search over pickups with a hard evaluation budget.
%   fun(ps) returns the exact-TMS objective (1e6 if no feasible TMS exists).
%   opt.budget  number of fitness evaluations allowed
%   opt.N       population size (default 20)
%   opt.entropy re-randomise the worst 20% of the swarm when the population
%               entropy drops below rho*H0 (default true, rho = 0.15)
lo = lo(:)'; hi = hi(:)';
d = numel(lo); span = hi - lo; vmax = 0.2*span;
if ~isfield(opt,'N'), opt.N = 20; end
if ~isfield(opt,'entropy'), opt.entropy = true; end
if ~isfield(opt,'rho'), opt.rho = 0.15; end
if ~isfield(opt,'inject'), opt.inject = 0.2; end
B = opt.budget;
N = min(opt.N, max(2, B));
tmax = max(1, floor(B/N) - 1);
Z = lo + rand(N,d).*span;
V = zeros(N,d);
f = zeros(N,1);
for i = 1:N, f(i) = fun(Z(i,:)'); end
used = N; restarts = 0;
[gf, gi] = min(f); gbest = Z(gi,:);
H0 = cad_entropy(Z, lo, hi, 6);
t = 0;
while used + N <= B && t < tmax
    t = t + 1;
    G  = exp(-20*t/tmax);
    kb = max(1, round(N - (N-1)*t/tmax));
    worst = max(f); best = min(f);
    mm = (worst - f)./(worst - best + 1e-12) + 1e-12;
    Mass = mm/sum(mm);
    [~, ord] = sort(f);
    elite = ord(1:kb);
    a = zeros(N,d);
    for j = 1:kb
        e = elite(j);
        dz = Z(e,:) - Z;
        R = sqrt(sum(dz.^2, 2)) + 1e-12;
        a = a + (rand(N,1)*G*Mass(e)./R).*dz;
    end
    r1 = rand(N,d); r2 = rand(N,d); r3 = rand(N,d);
    V = min(max(r1.*V + 0.5*r2.*a + 1.5*r3.*(gbest - Z), -vmax), vmax);
    Z = min(max(Z + V, lo), hi);
    for i = 1:N, f(i) = fun(Z(i,:)'); end
    used = used + N;
    if opt.entropy && cad_entropy(Z, lo, hi, 6) < opt.rho*max(H0, 1e-9)
        nw = max(1, floor(opt.inject*N));
        if used + nw <= B
            [~, ord2] = sort(f);
            w = ord2(end-nw+1:end);
            Z(w,:) = lo + rand(nw,d).*span;
            V(w,:) = 0;
            for i = w', f(i) = fun(Z(i,:)'); end
            used = used + nw; restarts = restarts + 1;
        end
    end
    [fi, i] = min(f);
    if fi < gf - 1e-12
        gbest = Z(i,:); gf = fi;
    end
end
gbest = gbest(:);
end
