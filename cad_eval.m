function f = cad_eval(pb, PSfull, rel, psz, pair_idx, mask)
%CAD_EVAL  Fitness of a pickup sub-vector: exact TMS objective, 1e6 if infeasible.
PS = PSfull; PS(rel) = psz;
if isempty(pair_idx)
    [f, ~, ok] = cad_exact_tms(pb, PS);
else
    [f, ~, ok] = cad_exact_tms(pb, PS, pair_idx, mask);
end
if ~ok, f = 1e6; end
end
