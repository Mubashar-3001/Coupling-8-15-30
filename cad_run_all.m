%CAD_RUN_ALL  Run the complete MATLAB side of the CAD-PSOGSA study.
%   1) cross-check of the exact TMS solve against linprog
%   2) independent re-run of the monolithic and CAD (K = 2) searches
%   3) measured parallel execution (Parallel Computing Toolbox)
%   4) all data figures of the paper (.fig, .pdf, .svg, .png in figures/)
here = fileparts(mfilename('fullpath')); cd(here);
fprintf('--- 1/4 cross-check\n');            cad_crosscheck;
fprintf('--- 2/4 independent re-run\n');     NREP = 50; REDO = true; cad_replicate; clear NREP REDO;
fprintf('--- 3/4 parallel timing\n');        NREP = 30; NRUN = 50; cad_parallel_timing; clear NREP NRUN;
fprintf('--- 4/4 figures\n');                cad_make_figures;
