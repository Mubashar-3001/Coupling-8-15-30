%CAD_MAKE_FIGURES  Draw every data figure of the paper from the CSV files in
%   data/ (exported from the Python runs) and results/ (MATLAB runs).
%   Each figure is written to figures/ as .fig, .pdf (vector), .svg and .png.
here = fileparts(mfilename('fullpath'));
dd = fullfile(here,'data'); fd = fullfile(here,'figures');
if ~exist(fd,'dir'), mkdir(fd); end
set(groot,'defaultAxesFontName','Helvetica','defaultTextFontName','Helvetica', ...
    'defaultAxesFontSize',8,'defaultTextFontSize',8,'defaultAxesLineWidth',0.6, ...
    'defaultAxesTickDir','out','defaultAxesBox','off');
% fixed categorical order (validated palette): one colour per method, never re-used
COL.mono = [42 120 214]/255;  COL.cad = [235 104 52]/255;  COL.random = [27 175 122]/255;
COL.validity = [237 161 0]/255; COL.cad_fine = [232 123 164]/255; COL.random_fine = [0 131 0]/255;
GRAY = [0.55 0.55 0.55]; INK = [0.15 0.15 0.15];
SYS = ["IEEE8","IEEE15","IEEE30"]; SYSL = ["IEEE 8-bus","IEEE 15-bus","IEEE 30-bus"];
S = cad_systems(); snames = string({S.name});

%% Fig. 2 - validity indices of each technique's best candidate
V = readtable(fullfile(dd,'cad_validity_scores.csv'),'TextType','string');
f = figure('Units','inches','Position',[1 1 7.0 5.2],'Color','w');
tl = tiledlayout(3,3,'TileSpacing','compact','Padding','compact');
mets = ["sil","db","xb"]; ND = char(8211);   % en dash
mlab = ["Silhouette (higher is better)", "Davies"+ND+"Bouldin (lower is better)", "Xie"+ND+"Beni (lower is better)"];
for i = 1:3
    Vi = V(V.system == SYS(i), :);
    for j = 1:3
        ax = nexttile(tl); hold(ax,'on');
        y = Vi.(mets(j)); x = 1:height(Vi);
        b = bar(ax, x, y, 0.62, 'FaceColor','flat','EdgeColor','none');
        b.CData = repmat([0.70 0.74 0.80], height(Vi), 1);
        w = find(Vi.winner == 1);
        b.CData(w,:) = repmat(COL.cad, numel(w), 1);
        for k = 1:height(Vi)
            text(ax, x(k), y(k), sprintf(' K=%d', Vi.K(k)), 'Rotation', 90, 'FontSize', 6, ...
                 'Color', INK, 'VerticalAlignment','middle');
        end
        ax.XTick = x; ax.XTickLabel = Vi.technique; ax.XTickLabelRotation = 45;
        ax.YLim = [0, max(y)*1.45]; ax.YGrid = 'on'; ax.GridColor = [0.85 0.85 0.85];
        if i == 1, title(ax, mlab(j), 'FontWeight','normal'); end
        if j == 1, ylabel(ax, SYSL(i)); end
    end
end
save_fig(f, fd, 'cad_fig2_validity_indices');

%% Fig. 3 - relay coupling graphs coloured by zone: validity-index vs coupling-aware
Z = readtable(fullfile(dd,'cad_partitions.csv'),'TextType','string');
f = figure('Units','inches','Position',[1 1 7.0 5.4],'Color','w');
tl = tiledlayout(f, 2, 3, 'TileSpacing','compact','Padding','compact');
zcols = ["validity_zone","cad_zone","cad_fine_zone"];
ztit  = ["validity-index zones","coupling-aware, \itK\rm = 2","coupling-aware, fine split"];
PAL = [42 120 214; 235 104 52; 27 175 122; 237 161 0; 232 123 164; 0 131 0; 98 80 214; 227 73 72]/255;
for i = 2:3
    s = S(snames == SYS(i)); pr = s.pairs;
    G = simplify(graph(pr(:,1), pr(:,2), [], s.Nr));
    rng(3); L = layout_xy(G);
    for j = 1:3
        ax = nexttile(tl); hold(ax,'on'); axis(ax,'equal','off');
        z = Z.(zcols(j))(Z.system == SYS(i));
        E = G.Edges.EndNodes; cut = z(E(:,1)) ~= z(E(:,2));
        for e = find(~cut)', plot(ax, L(E(e,:),1), L(E(e,:),2), '-', 'Color', [0.78 0.78 0.78], 'LineWidth', 0.6); end
        for e = find(cut)',  plot(ax, L(E(e,:),1), L(E(e,:),2), '-', 'Color', [0.15 0.15 0.15], 'LineWidth', 1.1); end
        nz = max(z); cnt = accumarray(z, 1);
        [~, ordz] = sort(cnt, 'descend');
        for q = 1:nz
            g = ordz(q); m = z == g;
            c = PAL(1 + mod(q-1, size(PAL,1)), :);
            if cnt(g) == 1, c = [0.40 0.40 0.40]; end
            scatter(ax, L(m,1), L(m,2), 24, c, 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 0.5);
        end
        ncut = sum(z(pr(:,1)) ~= z(pr(:,2)));
        if ncut == 1, pw = 'pair'; else, pw = 'pairs'; end
        title(ax, sprintf('%s, %s\n%d zones, largest %d of %d relays, %d %s cut', SYSL(i), ztit(j), nz, ...
              max(cnt), s.Nr, ncut, pw), 'FontWeight', 'normal', 'FontSize', 7);
    end
end
save_fig(f, fd, 'cad_fig3_partitions');

%% Fig. 4 - K-sweep: objective gap to the monolithic median, and pairs cut
K = readtable(fullfile(dd,'cad_results_ksweep.csv'),'TextType','string');
f = figure('Units','inches','Position',[1 1 7.0 3.9],'Color','w');
tl = tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
for i = 1:3
    Ki = K(K.system == SYS(i) & ~isnan(K.obj), :);
    ref = median(Ki.obj(Ki.K == 0));
    ks = unique(Ki.K(Ki.K > 0))';
    md = arrayfun(@(k) median(Ki.obj(Ki.K == k)), ks);
    q1 = arrayfun(@(k) prctile(Ki.obj(Ki.K == k), 25), ks);
    q3 = arrayfun(@(k) prctile(Ki.obj(Ki.K == k), 75), ks);
    ax = nexttile(tl, i); hold(ax,'on');
    yline(ax, 0, '-', 'Color', GRAY, 'LineWidth', 0.8, 'HandleVisibility', 'off');
    g = 100*(md/ref - 1); gl = 100*(q1/ref - 1); gh = 100*(q3/ref - 1);
    errorbar(ax, ks, g, g - gl, gh - g, '-o', 'Color', COL.cad, 'MarkerFaceColor', COL.cad, ...
             'MarkerSize', 4, 'LineWidth', 1.2, 'CapSize', 3);
    ax.XTick = ks; ax.XLim = [min(ks)-0.5, max(ks)+0.5]; ax.YGrid = 'on'; ax.GridColor = [0.88 0.88 0.88];
    title(ax, SYSL(i), 'FontWeight', 'normal');
    if i == 1, ylabel(ax, {'Median gap to','monolithic (%)'}); end
    ax2 = nexttile(tl, i+3); hold(ax2,'on');
    cr = arrayfun(@(k) Ki.cross(find(Ki.K == k, 1)), ks);
    mz = arrayfun(@(k) Ki.maxdim(find(Ki.K == k, 1)), ks);
    s = S(snames == SYS(i));
    bar(ax2, ks, 100*cr/size(s.pairs,1), 0.6, 'FaceColor', [0.62 0.66 0.74], 'EdgeColor', 'none');
    for q = 1:numel(ks)
        text(ax2, ks(q), 100*cr(q)/size(s.pairs,1), sprintf('%d', mz(q)), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', 'FontSize', 6, 'Color', INK);
    end
    ax2.XTick = ks; ax2.XLim = ax.XLim; ax2.YGrid = 'on'; ax2.GridColor = [0.88 0.88 0.88];
    ax2.YLim = [0, 1.15*max(100*cr/size(s.pairs,1))];          % head-room for the bar labels
    xlabel(ax2, 'Number of zones \itK');
    if i == 1, ylabel(ax2, {'Pairs cut (%)','[label: largest zone]'}); end
end
save_fig(f, fd, 'cad_fig4_ksweep');

%% Fig. 5 - distributions over 50 runs
M = readtable(fullfile(dd,'cad_results_main.csv'),'TextType','string');
M = M(M.E == 5000 & M.ablation == "none" & M.seed < 50, :);
f = figure('Units','inches','Position',[1 1 7.0 2.9],'Color','w');
tl = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
order = ["mono","cad","random","cad_fine","random_fine","validity"];
olab = ["Mono","CAD K=2","Rand K=2","CAD fine","Rand fine","Validity"];
for i = 1:3
    ax = nexttile(tl); hold(ax,'on');
    for q = 1:numel(order)
        y = M.obj(M.system == SYS(i) & M.method == order(q) & M.feasible == 1);
        if isempty(y), continue; end
        boxchart(ax, q*ones(size(y)), y, 'BoxFaceColor', COL.(order(q)), 'MarkerColor', COL.(order(q)), ...
                 'MarkerStyle', '.', 'BoxWidth', 0.55, 'LineWidth', 0.8);
    end
    ax.XTick = 1:numel(order); ax.XTickLabel = olab; ax.XTickLabelRotation = 40;
    ax.YGrid = 'on'; ax.GridColor = [0.88 0.88 0.88];
    title(ax, SYSL(i), 'FontWeight', 'normal');
    if i == 1, ylabel(ax, 'Total primary operating time (s)'); end
    yl = prctile(M.obj(M.system == SYS(i)), [0 97]); r = yl(2) - yl(1);
    ax.YLim = [yl(1) - 0.05*r, yl(2) + 0.15*r];
end
save_fig(f, fd, 'cad_fig5_boxplots');

%% Fig. 6 - statistical power versus number of runs
P = readtable(fullfile(dd,'cad_power.csv'),'TextType','string');
f = figure('Units','inches','Position',[1 1 7.0 2.5],'Color','w');
tl = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
comps = unique(P.comparison, 'stable'); cc = [COL.mono; COL.random; COL.validity; COL.cad_fine];
mk = {'o','s','^','d'};
for i = 1:3
    ax = nexttile(tl); hold(ax,'on');
    for q = 1:numel(comps)
        Pi = P(P.system == SYS(i) & P.comparison == comps(q), :);
        plot(ax, Pi.n, Pi.power, ['-' mk{q}], 'Color', cc(q,:), 'MarkerFaceColor', cc(q,:), ...
             'MarkerSize', 4, 'LineWidth', 1.2, 'DisplayName', comps(q));
    end
    yline(ax, 0.8, '--', 'Color', GRAY, 'HandleVisibility', 'off');
    ax.YLim = [0 1.02]; ax.XLim = [3 52]; ax.YGrid = 'on'; ax.GridColor = [0.88 0.88 0.88];
    xlabel(ax, 'Runs per method, n'); title(ax, SYSL(i), 'FontWeight', 'normal');
    if i == 1, ylabel(ax, 'Power at \alpha = 0.05'); end
    if i == 3, legend(ax, 'Location', 'southeast', 'Box', 'off', 'FontSize', 6.5); end
end
save_fig(f, fd, 'cad_fig6_power');

%% Fig. 7 - CTI margins of continuous and discrete settings (median CAD run)
G7 = readtable(fullfile(dd,'cad_margins.csv'),'TextType','string');
f = figure('Units','inches','Position',[1 1 7.0 2.5],'Color','w');
tl = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
for i = 1:3
    ax = nexttile(tl); hold(ax,'on');
    Gi = G7(G7.system == SYS(i), :);
    [x1, y1] = ecdf_xy(Gi.margin_cont); [x2, y2] = ecdf_xy(Gi.margin_discrete);
    stairs(ax, x1, y1, '-', 'Color', COL.mono, 'LineWidth', 1.3, 'DisplayName', 'Continuous');
    stairs(ax, x2, y2, '-', 'Color', COL.cad, 'LineWidth', 1.3, 'DisplayName', 'Discrete (taps)');
    xline(ax, 0, '-', 'Color', GRAY, 'HandleVisibility', 'off');
    ax.YGrid = 'on'; ax.XGrid = 'on'; ax.GridColor = [0.88 0.88 0.88];
    xlabel(ax, 'CTI margin T_b - T_p - CTI (s)'); title(ax, SYSL(i), 'FontWeight', 'normal');
    if i == 1, ylabel(ax, 'Fraction of pairs'); end
    if i == 3, legend(ax, 'Location', 'southeast', 'Box', 'off'); end
end
save_fig(f, fd, 'cad_fig7_margins');
disp('figures written to figures/');

function L = layout_xy(G)
    fh = figure('Visible','off'); h = plot(G, 'Layout', 'force', 'Iterations', 600, 'UseGravity', true);
    L = [h.XData(:) h.YData(:)]; close(fh);
end

function [x, y] = ecdf_xy(v)
    v = sort(v(:)); n = numel(v);
    x = [v(1); v]; y = [0; (1:n)'/n];
end

function save_fig(f, fd, name)
    savefig(f, fullfile(fd, [name '.fig']));
    exportgraphics(f, fullfile(fd, [name '.pdf']), 'ContentType', 'vector');
    exportgraphics(f, fullfile(fd, [name '.png']), 'Resolution', 300);
    print(f, fullfile(fd, [name '.svg']), '-dsvg', '-painters');
end
