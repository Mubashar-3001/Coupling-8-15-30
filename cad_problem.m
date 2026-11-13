function pb = cad_problem(sys)
%CAD_PROBLEM  Derived arrays for one benchmark system (see cad_systems).
pb.sys   = sys;
pb.name  = sys.name;
pb.Nr    = sys.Nr;
pb.P     = sys.pairs(:,1);
pb.B     = sys.pairs(:,2);
pb.Ip    = sys.pairs(:,3);
pb.Ib    = sys.pairs(:,4);
pb.Np    = numel(pb.P);
pb.ctr   = sys.ctr(:);
pb.cti   = sys.cti;
pb.den_p = pb.ctr(pb.P);
pb.den_b = pb.ctr(pb.B);
% the primary time of relay r is taken at its close-in fault, i.e. the
% largest primary current listed for r
pb.prim_scn = zeros(pb.Nr,1);
for r = 1:pb.Nr
    ks = find(pb.P == r);
    if ~isempty(ks)
        [~, j] = max(pb.Ip(ks));
        pb.prim_scn(r) = ks(j);
    end
end
pb.has_prim = pb.prim_scn > 0;
pb.Iclose = zeros(pb.Nr,1);
pb.Iclose(pb.has_prim) = pb.Ip(pb.prim_scn(pb.has_prim));
% backup sensitivity: the backup relay must see at least M_MIN times its
% pickup current.  This bounds the backup pickup from above; a pair that
% cannot meet the rule even at the smallest pickup stays in the coupling
% graph but carries no CTI constraint (its backup cannot detect the fault).
pb.M_MIN = 1.5;
bound = pb.Ib ./ (pb.M_MIN * pb.ctr(pb.B));
pb.coord = bound >= sys.ps_lo;
pb.coord_idx = find(pb.coord);
pb.ps_lo_vec = repmat(sys.ps_lo, pb.Nr, 1);
pb.ps_hi_vec = repmat(sys.ps_hi, pb.Nr, 1);
for k = find(pb.coord & bound < sys.ps_hi)'
    pb.ps_hi_vec(pb.B(k)) = min(pb.ps_hi_vec(pb.B(k)), bound(k));
end
end
