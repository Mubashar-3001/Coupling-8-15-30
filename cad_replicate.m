%CAD_REPLICATE  Independent MATLAB re-run of the monolithic and CAD searches.
%   The MATLAB port uses its own random streams, so individual runs differ
%   from the Python runs; the distributions should not.  NREP seeds per
%   method and system (default 50, as in the Python study), E = 5000
%   evaluations per run.
%   Output: results/cad_replicate_results.csv and .mat
if ~exist('NREP','var'), NREP = 50; end
if ~exist('SYSTEMS_TO_RUN','var'), SYSTEMS_TO_RUN = ["IEEE8","IEEE15","IEEE30"]; end
here = fileparts(mfilename('fullpath'));
if ~exist(fullfile(here,'results'),'dir'), mkdir(fullfile(here,'results')); end
S = cad_systems(); names = string({S.name});
Z = readtable(fullfile(here,'data','cad_partitions.csv'), 'TextType','string');
E = 5000;
fn = fullfile(here,'results','cad_replicate_results.csv');
if exist(fn,'file'), R = readtable(fn,'TextType','string'); else, R = table(); end
if exist('REDO','var') && REDO && ~isempty(R), R = R(~ismember(R.system, SYSTEMS_TO_RUN), :); end
for s = SYSTEMS_TO_RUN
    pb = cad_problem(S(names == s));
    zc = Z.cad_zone(Z.system == s);
    for method = ["mono","cad"]
        if ~isempty(R) && any(R.system == s & R.method == method), continue; end
        obj = nan(NREP,1); ev = nan(NREP,1); wl = nan(NREP,1); tr = ones(NREP,1);
        parfor k = 1:NREP
            if method == "mono"
                r = cad_solve_mono(pb, 5000 + k, E);
            else
                r = cad_solve_deco(pb, zc, 5000 + k, E);
                tr(k) = r.tries;
            end
            obj(k) = r.obj; ev(k) = r.evals; wl(k) = r.wall;
        end
        T = table(repmat(s,NREP,1), repmat(method,NREP,1), (5000+(1:NREP))', obj, ev, wl, tr, ...
            'VariableNames', {'system','method','seed','obj','evals','wall','tries'});
        R = [R; T]; %#ok<AGROW>
        writetable(R, fn);
        fprintf('%s %-5s median %.4f  IQR [%.4f %.4f]\n', s, method, median(obj), ...
            prctile(obj,25), prctile(obj,75));
    end
end
save(fullfile(here,'results','cad_replicate_results.mat'), 'R');
