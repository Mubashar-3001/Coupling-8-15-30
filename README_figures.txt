MATLAB figures of the paper (Figs. 2-7).

Edit a figure directly: openfig('figures/cad_fig5_boxplots.fig') - then double-click the legend, axis labels or title
to change them (or use legend(...), xlabel(...), title(...) in the Command Window), and save with
exportgraphics(gcf,'figures/cad_fig5_boxplots.pdf','ContentType','vector').

Redraw all figures from the data: run cad_make_figures.m (it reads data/*.csv and writes .fig .pdf .svg .png to figures/).
Legend texts, colours and axis labels are set near the top of each figure block in cad_make_figures.m.

Fig. 2 cad_fig2_validity_indices   Fig. 3 cad_fig3_partitions   Fig. 4 cad_fig4_ksweep
Fig. 5 cad_fig5_boxplots           Fig. 6 cad_fig6_power        Fig. 7 cad_fig7_margins
