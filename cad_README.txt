CAD-PSOGSA_DOCR  --  MATLAB companion of the paper
"Coupling-aware decomposition of directional overcurrent relay coordination"
(M. Javed, L. Khan, M. Wagner, Y. Muhammad)

Run everything:   >> cad_run_all        (R2026a; Optimization and Parallel Computing toolboxes)

Functions
  cad_systems.m        protection data: IEEE 8-, 15-, 30-bus and IEEE30v (pair-23 sensitivity case)
  cad_problem.m        derived arrays for one system
  cad_coeff.m          IEC standard-inverse coefficients for fixed pickups
  cad_exact_tms.m      exact TMS solve (monotone relaxation + certified linear solve)
  cad_policy_solve.m   certificate step used by cad_exact_tms
  cad_grid_tms.m       least TMS on the relay tap grid (step 0.01) for fixed pickups
  cad_linprog_tms.m    reference LP solve with linprog (used only for the cross-check)
  cad_entropy.m        population entropy used by the restart rule
  cad_psogsa.m         PSO-GSA pickup search with entropy-triggered restarts, hard evaluation budget
  cad_eval.m           fitness: exact TMS objective, 1e6 if no feasible TMS exists
  cad_solve_mono.m     monolithic search
  cad_allocate.m       budget split across zone searches and the boundary search
  cad_zone_search.m    interior stage of one zone
  cad_solve_deco.m     decomposed search (interior, boundary reconciliation, retries; optional parfor)

Scripts (outputs go to results\ and figures\)
  cad_crosscheck.m       -> results\cad_crosscheck_results.csv/.mat, cad_crosscheck_summary.csv
  cad_replicate.m        -> results\cad_replicate_results.csv/.mat   (50 seeds per method and system)
  cad_parallel_timing.m  -> results\cad_parallel_timing.csv/.mat     (30 paired runs per zone-level case,
                            50-run batches for run-level parallelism)
  cad_make_figures.m     -> figures\cad_fig2_validity_indices, cad_fig3_partitions, cad_fig4_ksweep,
                            cad_fig5_boxplots, cad_fig6_power, cad_fig7_margins  (.fig .pdf .svg .png)
  cad_run_all.m          runs the four scripts in order

Data (exported from the Python runs that produced every number in the paper)
  data\cad_results_main.csv      every run with seeds 0-49 (all methods, budgets, ablation)
  data\cad_results_ksweep.csv    K-sweep, seeds 100-149, with monolithic reference rows (K = 0)
  data\cad_validity_scores.csv   best validity-index candidate of each clustering technique
  data\cad_partitions.csv        zone of every relay: validity-index, CAD K = 2, CAD fine K
  data\cad_power.csv             bootstrap power of the Mann-Whitney test versus runs per method
  data\cad_margins.csv           CTI margins of the median CAD run, continuous and discrete
  data\cad_check_cases.csv       pickup vectors used in the exactness cross-check
