Fig. 1 (CAD-PSOGSA pipeline) is the only figure not drawn in MATLAB. Three editable versions:

1. draw.io:  CAD-PSOGSA_flowchart.drawio
   Open https://app.diagrams.net > File > Open from > Device. Edit, then File > Export as PDF/PNG/SVG.

2. Graphviz: CAD-PSOGSA_flowchart.dot
   Paste the file into https://dreampuf.github.io/GraphvizOnline (engine: dot), or run
   dot -Tpdf CAD-PSOGSA_flowchart.dot -o CAD-PSOGSA_flowchart.pdf
   Renders: CAD-PSOGSA_flowchart_graphviz.pdf/.png/.svg

3. TikZ (the version printed in the paper):
   fig_flowchart_in_paper.tex   the code used inside main.tex
   CAD-PSOGSA_flowchart_tikz.tex  stand-alone version (pdflatex), renders: CAD-PSOGSA_flowchart_tikz.pdf/.png/.svg
