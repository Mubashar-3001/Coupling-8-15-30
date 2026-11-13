function H = cad_entropy(Z, lo, hi, bins)
%CAD_ENTROPY  Shannon entropy of a population over an equal-width grid.
if nargin < 4, bins = 6; end
span = max(hi(:)' - lo(:)', 1e-12);
idx = min(max(floor((Z - lo(:)')./span*bins), 0), bins-1);
[~, ~, g] = unique(idx, 'rows');
cnt = accumarray(g, 1);
p = cnt/sum(cnt);
H = -sum(p .* log(p + 1e-15));
end
