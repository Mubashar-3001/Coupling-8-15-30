function [zb, bb, zones, bidx, ncross] = cad_allocate(pb, zof, E)
%CAD_ALLOCATE  Split a run's evaluation budget E across the zone searches and
%   the boundary search in proportion to the number of pickups each handles.
zof = zof(:);
G = max(zof);
intra = zof(pb.P) == zof(pb.B);
cp = find(~intra); ncross = numel(cp);
bnd = false(pb.Nr,1); bnd(pb.P(cp)) = true; bnd(pb.B(cp)) = true;
bidx = find(bnd);
zones = cell(G,2); dims = zeros(G,1);
for g = 1:G
    zones{g,1} = find(zof == g);
    zones{g,2} = find(intra & zof(pb.P) == g);
    if ~isempty(zones{g,2}), dims(g) = numel(zones{g,1}); end
end
Dtot = sum(dims) + numel(bidx);
zb = floor(E*dims/Dtot);
bb = E - sum(zb);
end
