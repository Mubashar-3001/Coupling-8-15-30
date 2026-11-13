%CAD_PARALLEL_TIMING  Measured (not estimated) parallel execution on this PC.
%   Fine-grained: the zones of one CAD run are solved with parfor. Each of
%   NREP seeds is run once sequentially and once in parallel (paired runs);
%   the table reports median times and the median and IQR of the per-seed
%   speed-up.
%   Coarse-grained: NRUN independent runs (seeds) executed one after the other
%   and then distributed with parfor; the speed-up is the ratio of the totals.
%   Output: results/cad_parallel_timing.csv and .mat
here = fileparts(mfilename('fullpath'));
if ~exist(fullfile(here,'results'),'dir'), mkdir(fullfile(here,'results')); end
S = cad_systems(); names = string({S.name});
Z = readtable(fullfile(here,'data','cad_partitions.csv'), 'TextType','string');
p = gcp('nocreate');
if isempty(p), p = parpool('Processes'); end
nw = p.NumWorkers;
E = 5000;
if ~exist('NREP','var'), NREP = 30; end          % paired runs per fine-grained case
if ~exist('NRUN','var'), NRUN = 50; end          % runs per coarse-grained batch
if ~exist('SYSTEMS_TO_RUN','var'), SYSTEMS_TO_RUN = ["IEEE8","IEEE15","IEEE30"]; end
fn = fullfile(here,'results','cad_parallel_timing.csv');
logf = fullfile(here,'results','timing_progress.txt');
vn = {'system','partition','mode','workers','zones','nrep','interior_seq_s','interior_par_s', ...
      'run_seq_s','run_par_s','speedup','speedup_q1','speedup_q3'};
T = table();
for s = SYSTEMS_TO_RUN
    pb = cad_problem(S(names == s));
    for zcol = ["cad_zone","cad_fine_zone"]
        zc = Z.(zcol)(Z.system == s);
        % warm-up (JIT, worker start-up) -- not timed
        cad_solve_deco(pb, zc, 1, 500, [], 1, false);
        cad_solve_deco(pb, zc, 1, 500, [], 1, true);
        tseq = nan(NREP,1); tpar = nan(NREP,1); iseq = nan(NREP,1); ipar = nan(NREP,1);
        for k = 1:NREP
            r1 = cad_solve_deco(pb, zc, 100+k, E, [], 1, false);
            r2 = cad_solve_deco(pb, zc, 100+k, E, [], 1, true);
            tseq(k) = r1.wall; tpar(k) = r2.wall; iseq(k) = r1.t_interior; ipar(k) = r2.t_interior;
            assert(abs(r1.obj - r2.obj) < 1e-9, 'parallel and sequential runs differ');
        end
        sp = tseq ./ tpar;
        T = [T; table(s, zcol, "fine (zones)", nw, max(zc), NREP, median(iseq), median(ipar), ...
            median(tseq), median(tpar), median(sp), prctile(sp,25), prctile(sp,75), ...
            'VariableNames', vn)]; %#ok<AGROW>
        fid = fopen(logf,'a'); fprintf(fid,'%s %s fine done %s\n', s, zcol, datestr(now)); fclose(fid);
    end
    % coarse-grained: NRUN independent runs, proposed partition and monolithic search
    zc = Z.cad_zone(Z.system == s);
    t0 = tic; for k = 1:NRUN, cad_solve_deco(pb, zc, 200+k, E); end; ts = toc(t0);
    t0 = tic; parfor k = 1:NRUN, cad_solve_deco(pb, zc, 200+k, E); end; tp = toc(t0);
    T = [T; table(s, "cad_zone", "coarse (runs)", nw, max(zc), NRUN, NaN, NaN, ts, tp, ts/tp, NaN, NaN, ...
        'VariableNames', vn)]; %#ok<AGROW>
    t0 = tic; for k = 1:NRUN, cad_solve_mono(pb, 200+k, E); end; ts = toc(t0);
    t0 = tic; parfor k = 1:NRUN, cad_solve_mono(pb, 200+k, E); end; tp = toc(t0);
    T = [T; table(s, "monolithic", "coarse (runs)", nw, 1, NRUN, NaN, NaN, ts, tp, ts/tp, NaN, NaN, ...
        'VariableNames', vn)]; %#ok<AGROW>
    fid = fopen(logf,'a'); fprintf(fid,'%s coarse done %s\n', s, datestr(now)); fclose(fid);
    disp(T(T.system == s, :));
end
T.efficiency = T.speedup ./ T.workers;
if exist(fn,'file')
    T0 = readtable(fn,'TextType','string');
    T0 = T0(~ismember(T0.system, SYSTEMS_TO_RUN), :);
    if ~isempty(T0) && width(T0) == width(T), T = [T0; T]; end
end
writetable(T, fn);
save(fullfile(here,'results','cad_parallel_timing.mat'), 'T');
