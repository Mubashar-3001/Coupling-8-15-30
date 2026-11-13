%CAD_CROSSCHECK  Cross-check of the exact TMS solve in MATLAB.
%   For every pickup vector in data/cad_check_cases.csv (final pickups of the
%   Python runs plus random draws) the TMS problem is solved three ways:
%   the Python relaxation (stored objective), cad_exact_tms (MATLAB port of
%   the same algorithm) and linprog (dual simplex, Optimization Toolbox).
%   Output: results/cad_crosscheck_results.csv and .mat
here = fileparts(mfilename('fullpath'));
if ~exist(fullfile(here,'results'),'dir'), mkdir(fullfile(here,'results')); end
C = readtable(fullfile(here,'data','cad_check_cases.csv'), 'TextType','string');
S = cad_systems(); names = string({S.name});
pscol = startsWith(C.Properties.VariableNames, 'PS_');
n = height(C);
obj_m = nan(n,1); obj_lp = nan(n,1); feas_m = false(n,1); feas_lp = false(n,1);
dT = nan(n,1); minmarg = nan(n,1); passes = nan(n,1); cert = false(n,1); t_ex = nan(n,1); t_lp = nan(n,1);
pbs = arrayfun(@cad_problem, S);
for i = 1:n
    pb = pbs(names == C.system(i));
    PS = C{i, pscol}'; PS = PS(1:pb.Nr);
    t0 = tic; [o1, T1, ok1, ~, info] = cad_exact_tms(pb, PS); t_ex(i) = toc(t0);
    t0 = tic; [o2, T2, ok2] = cad_linprog_tms(pb, PS); t_lp(i) = toc(t0);
    obj_m(i) = o1; feas_m(i) = ok1; obj_lp(i) = o2; feas_lp(i) = ok2;
    passes(i) = info.passes; cert(i) = info.certified;
    if ok1 && ok2
        [c, cp, cb] = cad_coeff(pb, PS);
        pos = c > 0;                      % relays with no primary pair carry no weight
        dT(i) = max(abs(T1(pos) - T2(pos)));
        minmarg(i) = min(cb.*T1(pb.B) - cp.*T1(pb.P) - pb.cti);
    end
end
R = C(:, {'system','source','case_id','py_obj','py_feasible'});
R.matlab_obj = obj_m; R.linprog_obj = obj_lp;
R.matlab_feasible = feas_m; R.linprog_feasible = feas_lp;
R.max_tms_diff = dT; R.min_margin = minmarg; R.passes = passes; R.certified = cert;
R.t_exact_ms = 1e3*t_ex; R.t_linprog_ms = 1e3*t_lp;
writetable(R, fullfile(here,'results','cad_crosscheck_results.csv'));
% summary per system
fprintf('\n%-8s %6s %6s %10s %12s %12s %10s %8s %8s\n', 'system','cases','feas', ...
        'flag-mism', 'max|py-mat|', 'max|mat-lp|', 'max dTMS', 'exact ms', 'lp ms');
summ = table();
for s = names(1:3)
    m = R.system == s; f = m & R.matlab_feasible & R.linprog_feasible;
    rel = @(a,b) max(abs(a(f)-b(f))./max(1,abs(b(f))));
    row = table(s, sum(m), sum(f), sum(m & (R.matlab_feasible ~= R.linprog_feasible | R.matlab_feasible ~= R.py_feasible)), ...
        rel(R.matlab_obj, R.py_obj), rel(R.matlab_obj, R.linprog_obj), max(R.max_tms_diff(f)), ...
        min(R.min_margin(f)), median(R.t_exact_ms(m)), median(R.t_linprog_ms(m)), ...
        'VariableNames', {'system','cases','feasible','flag_mismatch','max_rel_py_vs_matlab', ...
        'max_rel_matlab_vs_linprog','max_tms_diff','min_margin','median_exact_ms','median_linprog_ms'});
    summ = [summ; row]; %#ok<AGROW>
    fprintf('%-8s %6d %6d %10d %12.1e %12.1e %10.1e %8.3f %8.3f\n', s, row.cases, row.feasible, ...
        row.flag_mismatch, row.max_rel_py_vs_matlab, row.max_rel_matlab_vs_linprog, row.max_tms_diff, ...
        row.median_exact_ms, row.median_linprog_ms);
end
writetable(summ, fullfile(here,'results','cad_crosscheck_summary.csv'));
save(fullfile(here,'results','cad_crosscheck_results.mat'), 'R', 'summ');
